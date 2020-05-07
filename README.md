# Cucumber.js for WinJS JavaScript-based Windows 8 Apps

This is a version of [Cucumber.js](https://github.com/cucumber/cucumber-js)
adapted for use inside a Windows 8 store WinJS application.

In addition to the modified Cucumber.js [License](https://github.com/cucumber/cucumber-js/blob/master/LICENSE), this repository also includes some step
definitions for some basic functionality like navigation, file open pickers
(mocked, because invoking the real deal would stop the app in its tracks) and
message dialogues.

Pull requests with more step definitions are welcome.

## Windows 8 App Cucumber Example Feature

```gherkin
Feature: Welcome page
  To become acquainted with the application
  As a user
  I want to be guided through the first start

  Background:
    Given I start the application for the first time
    And I am on the welcome page

 # Commented out as an example for a possible registration scenario
 #
 # Scenario: First start with registration
 #   When I click on 'Register Now'
 #   Then I should see a registration form
 #   When I enter my registration details
 #   And I click on 'Register'
 #   Then I should be on the welcome page
 #   And I should see 'Thank you for registering'
 #   And I should see a button 'Add Documents'

  Scenario: Using demo documents on first start
    When I click on 'Register Later'
    And choose 'Add Demo Documents'
    Then I should be on the landing page
    And should see a list with 9 documents

  Scenario: Using my own documents on first start
    When I click on 'Register Later'
    And I choose 'Use My Documents' and pick the file demoData/Account Information.pdf
    Then I should be on the landing page
    And I should see a document list with the following elements:
      | Name                 |
      | Account Information  |
```

## How it looks in action

<small>Note: The videos sadly don't show the feature described above</small>

Windows 8 Metro App

<video width="800" height="450" controls muted>
  <source src="doc/cucumber-winjs-Windows-8-Desktop.mp4" type="video/mp4">
</video>

Windows 8 Phone

<video width="392" height="716" controls muted>
  <source src="doc/cucumber-winjs-Windows-8-Phone.mp4" type="video/mp4">
</video>

## License

[MIT](LICENSE) License
