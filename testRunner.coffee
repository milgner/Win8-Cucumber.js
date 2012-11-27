# Cucumber = require './cucumber'

StorageFile = Windows.Storage.StorageFile
StorageFolder = Windows.Storage.StorageFolder
FileIO = Windows.Storage.FileIO
Package = Windows.ApplicationModel.Package

# collect all files in the step_definitions folder and concatenate them into one support code variable
SUPPORT_CODE = '''
  this.World = function(callback) {
    callback(this);
  };
  var World = this.World;
  var originalDefineStep = this.defineStep;
  // a custom defineStep implementation
  // because we don't want to burden the test implementor with waiting for async operations
  // we assume that a test may fail up to 10 times, before the actual failure gets promoted
  var customDefineStep = function(regex, stepImplementation) {
    customCallback = function() {
      var origArgs = arguments;
      var stepCompleteCallback = arguments[arguments.length-1];
      var oldStepFailedCallback = stepCompleteCallback.fail;
      var timesFailed = 0;
      stepCompleteCallback.fail = function () {
        if (timesFailed < 10) {
          timesFailed += 1;
          setTimeout( function() {
            stepImplementation.apply(World, origArgs);
          }, 500);
        } else {
          oldStepFailedCallback(arguments);
        }
      }
      try {
        WinJS.Promise.as(stepImplementation.apply(World, origArgs)).then(function() {}, function(e) {
          stepCompleteCallback.fail(e);
        });
      } catch (exception) {
        oldStepFailedCallback(exception);
      }
    }
    originalDefineStep(regex, customCallback);
  }
  var Given = When = Then = customDefineStep;\n\n
  '''

concatenateFilesAsync = (folder, pattern = /.*/) ->
  result = ""
  folder.getFilesAsync().then (files) ->
    files.sequentialEachAsync (file) ->
      return unless pattern.test file.name
      FileIO.readTextAsync(file).then (content) ->
        result += content + "\n"
        return
  .then ->
    result

applicationPath = Package.current.installedLocation.path

testConfig = {}
outputFolder = null

Windows.Storage.StorageFile.getFileFromApplicationUriAsync('testConfig.json'.toAppPackageUri())
.then (file) ->
  Windows.Storage.FileIO.readTextAsync(file)
.then (buffer) ->
  try
    testConfig = JSON.parse buffer
  catch e
    window.console?.error?("Could not load testConfig.json file", e)
.then ->
  StorageFolder.getFolderFromPathAsync(applicationPath + '\\features\\step_definitions')
.then (folder) ->
  concatenateFilesAsync(folder, /\.js$/)
.then (stepDefinitions) ->
  SUPPORT_CODE += stepDefinitions

  folderName = testConfig.folderName || 'testResults'
  localFolder = Windows.Storage.ApplicationData.current.localFolder
  localFolder.createFolderAsync(folderName, Windows.Storage.CreationCollisionOption.openIfExists)
.then (folder) ->
  outputFolder = folder
  StorageFolder.getFolderFromPathAsync(applicationPath + "\\features")
.then (featuresFolder) ->
  concatenateFilesAsync(featuresFolder, /\.feature$/)
.then (featureCode) ->
  cucumber = Cucumber featureCode, new Function(SUPPORT_CODE)

  outputElement = document.getElementById 'testOutput'
  if outputElement
    cucumber.attachListener doo.cucumber.CucumberHTMLListener(outputElement)
    errors = document.getElementById 'testErrors'
    errorsContainer = document.getElementById 'testErrorsContainer'
    errors.innerText = ''
    errorsContainer.style.display = 'none'
  cucumber.attachListener(new doo.cucumber.JUnitXmlListener(outputFolder))


  new WinJS.Promise (complete) ->
    try
      cucumber.start complete
    catch err
      if errorsContainer
        errorsContainer.style.display = 'block'
        errorMessage = err.message || err
        errors.innerText += "\n" + errorMessage
      complete(err)
.then (err) ->
  window.close() if testConfig.quitAfterTests

