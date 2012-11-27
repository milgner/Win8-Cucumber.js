Navigation = WinJS.Navigation

#
# Some steps that control the application or are WinJS-specific
#
urlForPagename = (pagename) -> if pagename in ['welcome'] then "/html/#{pagename}.html" else "/html/#{pagename}Page.html"

Given /^(?:I |)am on the ([\w\s]+) page$/, (pagename, callback) ->
  pagename = pagename.replace /\s(\w)/g, (str, p1) -> p1.toUpperCase()
  pageLocation = urlForPagename pagename
  Navigation.navigate(pageLocation).then -> callback()

Then /^(?:I |)should be on the ([\w\s]+) page$/, (pagename, callback) ->
  if Navigation.location == urlForPagename pagename
    callback()
  else
    callback.fail new Error "I wanted to be on the #{pagename} page, instead I'm at #{Navigation.location}"
  
When /^(?:I |)wait (\d+) seconds$/, (seconds, callback) ->
  setTimeout ->
    callback()
  , seconds*1000

#
# mock the message dialog because the native dialog doesn't work with the DOM
# and blocks the execution flow
#
doo.ui.showLocalizedMessageDialogAsync = (namePrefix, commands) =>
  World.dialogButtonsAndCallback = {}
  new WinJS.Promise (complete) =>
    for own command, callback of commands
      text = doo.ui.translate "#{namePrefix}.#{command}"
      modifiedCallback = (origCallback) -> 
        WinJS.Promise.as(origCallback.apply(arguments.callee.caller)).then (result) ->
          complete result
      World.dialogButtonsAndCallback[text] = modifiedCallback.bind this, callback

When /^(?:I |)choose '([^']+)' from the dialog$/, (option, callback) ->
  unless World.dialogButtonsAndCallback
    callback.fail(new Error("There is no open dialog")) 
    return
  unless World.dialogButtonsAndCallback[option]
    callback.fail(new Error("The dialog has no such option"))
    return
  resultCallback = World.dialogButtonsAndCallback[option]
  WinJS.Promise.as(resultCallback()).then(
    -> callback()
    (e) -> callback.fail e
  )

#
# Replace the Windows FileOpenPicker with a mock
#
class MockFileOpenPicker

  constructor: ->
    instance = @
    @fileTypeFilter = new Object
    @fileTypeFilter.replaceAll = (newExts) =>
      @extensions = newExts

    for p in ['commitButtonText', 'suggestedStartLocation', 'viewMode']
      Object.defineProperty @, p,
        configurable: true
        enumerable: true
    @_pickedFiles = []

    return

  pickMultipleFilesAsync: ->
    new WinJS.Promise (complete) =>
      @_completionHandler = complete

  _addPickedFile: (file) ->
    @_pickedFiles.push file

  _pickFiles: (files) ->
    @_pickedFiles = files

  _done: () ->
    files = @_pickedFiles
    @_pickedFiles = []
    files.size = files.length
    @_completionHandler(files)

World.mockedFileOpenPicker = new MockFileOpenPicker()
doo.ui.showImportSelector = doo.ui.showImportSelector.bind(World, World.mockedFileOpenPicker)

When /^(?:I |)pick the file (.+)$/, (pickedFile, callback) ->
  Windows.Storage.StorageFile.getFileFromApplicationUriAsync(pickedFile.toAppPackageUri())
  .then (file) ->
    World.mockedFileOpenPicker._addPickedFile(file)
    callback()

When /^(?:I |)confirm the file picker selection$/, (callback) ->
  WinJS.Promise.as(World.mockedFileOpenPicker._done()).then ->
    callback()

#
# Replace the Windows PopupMenu with a mock
#
class MockPopupMenu

  constructor: ->
    @commands = {}
    @commands.append = (cmd) ->
      this[cmd.label] = cmd

  _select: (label) ->
    command = @commands[label]
    WinJS.Promise.as(command.invoked(command))
    .then =>
      @_completionHandler()

  showAsync: (pos) ->
    new WinJS.Promise (complete) =>
      @_completionHandler = complete

World.mockedPopupMenu = new MockPopupMenu()
doo.ui.showImportPopupAsync = _.wrap doo.ui.showImportPopupAsync, (func, pos) ->
  func(pos, World.mockedPopupMenu)

When /^(?:I |)select '(.+)' in the popup menu$/, (selectedCommand, callback) ->
  World.mockedPopupMenu._select(selectedCommand)
  callback()

Then /^(?:I |)should see a list with (\d+) documents$/, (elementCount, callback) ->
  elementCount = parseInt(elementCount)
  listViews = document.querySelectorAll('[data-win-control="WinJS.UI.ListView"]')
  if listViews.length == 0
    callback.fail new Error "There is no ListView on the current page"
    return
  found = false
  promises = []
  for listView in listViews
   dataSource = listView.winControl.itemDataSource
   promises.push dataSource.getCount().then (actualElementCount) ->
     found = true if actualElementCount is elementCount
     return
  WinJS.Promise.join(promises).then ->
    if found
      callback()
    else
      callback.fail() 

findElementTextInListView = (listView, elementText, vertical=false, restart = true) ->
  [scrollProperty, sizeProperty] = if vertical 
      ['scrollTop', 'height']
    else 
      ['scrollLeft', 'width']
  listView[scrollProperty] = 0 if restart
  for item in listView.querySelectorAll('.win-item')
    return true if item.innerText.indexOf(elementText) > -1
  oldValue = listView[scrollProperty]
  listView[scrollProperty] = oldValue + listView[sizeProperty]
  if listView[scrollProperty] != oldValue # scrolling successful
    findElementTextInListView(listView, elementText, vertical, false)
  else
    false

Then /^(?:I |)should see a document list with the following elements:?$/, (elements, callback) ->
  WinJS.Promise.timeout(1000).then ->
    docsToFind = elements.hashes()
    listViews = document.querySelectorAll('[data-win-control="WinJS.UI.ListView"]')
    for listView in listViews
      notFound = []
      for doc in docsToFind
        unless findElementTextInListView(listView, doc.Name)
          notFound.push doc.Name
      break if notFound.length is 0
    if notFound.length > 0
      callback.fail(new Error("Could not find the following elements: #{notFound.join(', ')}"))
    else
      callback()
