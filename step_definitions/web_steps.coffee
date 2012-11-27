#
# Simulate clicking on links and buttons
#
When /^(?:I |)click on '([^']+)'/, (whatToClick, callback) ->
  element = undefined
  for candidate in document.querySelectorAll 'a,button'
    if candidate.innerText == whatToClick
      element = candidate
      break

  if element
    element.click()
    callback()
  else
    callback.fail(new Error("There's no element titled \"#{whatToClick}\""))

#
# Look for text on the current page
#
Then /^(?:I |)should see '([^'])'$/, (text, callback) ->
  found = document.innerText.indexOf(text) > -1
  unless found
    callback.fail(new Error("Couldn't find \"#{text}\" on the page"))
  else
    callback()
