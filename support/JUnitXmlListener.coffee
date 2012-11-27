CreationCollisionOption = Windows.Storage.CreationCollisionOption
XmlDocument = Windows.Data.Xml.Dom.XmlDocument

#
# Cucumber listener that writes output into a Ant/JUnit compatible XML
# http://windyroad.org/dl/Open%20Source/JUnit.xsd
#

filenameBaseForFeatureName = (featureName, initial = true) ->
  if featureName.length is 0
    return featureName
  else
    char = featureName[0]
    if char in [' ', '-']
      filenameBaseForFeatureName(featureName.substr(1), true)
    else
      (if initial then char.toUpperCase() else char) + 
        filenameBaseForFeatureName(featureName.substr(1), false)


class JUnitXmlListener

  constructor: (@outputDirectory) ->
    return

  hear: (event, callback) ->
    eventName = event.getName()
    WinJS.Promise.as(@[eventName]?(event)).then ->
      callback()

  BeforeFeature: (event) ->
    feature = event.getPayloadItem 'feature'

    filename = filenameBaseForFeatureName(feature.getName()) + ".xml"
    @outputDirectory.createFileAsync(filename, CreationCollisionOption.replaceExisting)
    .then (@currentOutputFile) =>
      @xmlDocument = new XmlDocument()
      pi = @xmlDocument.createProcessingInstruction('xml', 'version="1.0" encoding="UTF-8"')
      @xmlDocument.appendChild(pi)
      @testsuites = @xmlDocument.createElement('testsuites')
      @xmlDocument.appendChild(@testsuites)
      return

  AfterFeature: (event) ->
    if @xmlDocument
      @xmlDocument.saveToFileAsync(@currentOutputFile) 
    else 
      WinJS.Promise.wrap()
    
  BeforeScenario: (event) ->
    @testsuite = @xmlDocument.createElement('testsuite')
    @scenario = event.getPayloadItem 'scenario'
    @testsuite.setAttribute('name', @scenario.getName())
    @_stepCounter = 0
    @_testSuiteStarted = Date.now()
    @testsuite.setAttribute('timestamp', new Date().toISOString())
    @testsuites.appendChild(@testsuite)
    return

  BeforeStep: (event) ->
    @currentStep = event.getPayloadItem 'step'
    @_stepStarted = Date.now()
    @_stepCounter += 1
    return

  StepResult: (event) ->
    element = @xmlDocument.createElement('testcase')
    element.setAttribute('classname', @scenario.getName())
    element.setAttribute('name', "#{@_stepCounter.toPaddedString(2)} - #{@currentStep.getName()}")
    element.setAttribute('time', (Date.now() - @_stepStarted)/1000)
    stepResult = event.getPayloadItem('stepResult')
    if not stepResult.isSuccessful()
    # else if stepResult.isPending()
      if stepResult.isUndefined() or stepResult.isSkipped()
        skipped = @xmlDocument.createElement('skipped')
        element.appendChild(skipped)
      else
        error = stepResult.getFailureException()
        errorMessage = error.stack || error
        failure = @xmlDocument.createElement('failure')
        failure.setAttribute 'message', errorMessage
        element.appendChild(failure)
    @testsuite.appendChild(element)
    return


WinJS.Namespace.define 'doo.cucumber',
  JUnitXmlListener: JUnitXmlListener