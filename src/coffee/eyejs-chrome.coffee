# Pull-in the Mousetrap lib.
require './../../lib/mousetrap/mousetrap'

EyeJS = require '/Users/josh/work/eyejs'

eyejs = new EyeJS()


chrome.storage.local.get 'config', (storage = {}) ->
  config  = storage.config
  enabled = if config.enabled? then config.enabled else eyejs.enabled
  size    = if config.size?    then config.size    else eyejs.indicator.size
  opacity = if config.opacity? then config.opacity else eyejs.indicator.opacity()

  if enabled then eyejs.enable()
  eyejs.indicator.resize size
  eyejs.indicator.opacity opacity


getStatus = ->
  return {
    enabled:  eyejs.enabled
    size:     eyejs.indicator.size
    opacity:  eyejs.indicator.opacity()
  }


updateSettings = ->
  chrome.storage.local.set 'config': getStatus()


Mousetrap.bind 'ctrl', ->
  eyejs.triggerEvents 'click'

# Don't prevent triggering a click if inside a form element.
# @see http://craig.is/killing/mice
Mousetrap.stopCallback = -> false


if chrome?

  chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->

    switch request.msg
      when 'eyejs:enable'
        eyejs.enable()
        updateSettings()

      when 'eyejs:disable'
        eyejs.disable()
        updateSettings()

      when 'eyejs:getstatus' then null

      when 'eyejs:resize'
        eyejs.indicator.resize +request.val
        updateSettings()

      when 'eyejs:setopacity'
        eyejs.indicator.opacity +request.val
        updateSettings()

    sendResponse getStatus()
