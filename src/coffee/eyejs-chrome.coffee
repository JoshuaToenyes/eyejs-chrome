
# Pull-in the Mousetrap lib.
require './../../lib/mousetrap/mousetrap'

EyeJS = require '/Users/josh/work/eyejs'

eyejs = new EyeJS()

getStatus = ->
  return {
    enabled: eyejs.enabled
    size: eyejs.indicator.size
    opacity: eyejs.indicator.opacity()
  }


Mousetrap.bind 'ctrl', ->
  console.log 'clicking!'
  eyejs.triggerEvents 'click'


if chrome?

  chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->

    switch request.msg
      when 'eyejs:enable'
        eyejs.enable()

      when 'eyejs:disable'
        eyejs.disable()

      when 'eyejs:getstatus' then null

      when 'eyejs:resize'
        eyejs.indicator.resize +request.val

      when 'eyejs:setopacity'
        eyejs.indicator.opacity +request.val

      when 'eyejs:calibrate'
        eyejs.calibrate()

    sendResponse getStatus()
