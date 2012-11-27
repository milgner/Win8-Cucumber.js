CucumberHTMLListener = (output) ->
  # CucumberHTML = require 'cucumber-html'
  formatter = new CucumberHTML.DOMFormatter output
  formatter.uri 'test.feature'

  currentStep = undefined

  self =
    hear: (event, callback) ->
      eventName = event.getName()
      switch eventName
        when "BeforeFeature"
          feature = event.getPayloadItem 'feature'
          formatter.feature
            keyword     : feature.getKeyword()
            name        : feature.getName()
            line        : feature.getLine()
            description : feature.getDescription?()
        when 'BeforeScenario'
          scenario = event.getPayloadItem 'scenario'
          formatter.scenario
            keyword     : scenario.getKeyword()
            name        : scenario.getName()
            line        : scenario.getLine()
            description : scenario.getDescription?()
        when 'BeforeStep'
          step = event.getPayloadItem 'step'
          self.handleAnyStep step
        when 'StepResult'
          stepResult = event.getPayloadItem 'stepResult'
          result = undefined
          if stepResult.isSuccessful()
            result = {status: 'passed'}
          else if stepResult.isPending()
            result = {status: 'pending'}
          else if stepResult.isUndefined() || stepResult.isSkipped()
            result = {status: 'skipped'}
          else
            error = stepResult.getFailureException()
            errorMessage = error.stack || error
            result = 
              status: 'failed'
              error_message: errorMessage
          formatter.match
            uri : 'test.feature'
            step:
              line: currentStep.getLine()
          formatter.result result
      callback()

    handleAnyStep: (step) ->
      toFormat =
        keyword : step.getKeyword()
        name    : step.getName()
        line    : step.getLine()
      if step.hasDataTable()
        toFormat.rows = step.getDataTable().raw()
      formatter.step(toFormat)
      currentStep = step
  self

WinJS.Namespace.define 'doo.cucumber',
  CucumberHTMLListener: CucumberHTMLListener
