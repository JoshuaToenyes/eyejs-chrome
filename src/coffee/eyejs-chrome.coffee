
# Pull-in the Mousetrap lib.
require './../../lib/mousetrap/mousetrap'

EyeJS = require '/Users/josh/work/eyejs'

eyejs = new EyeJS()

enabled = localStorage['enabled'] or eyejs.enabled
size    = localStorage['size']    or eyejs.indicator.size
opacity = localStorage['opacity'] or eyejs.indicator.opacity()

if enabled then eyejs.enable()
eyejs.indicator.resize size
eyejs.indicator.opacity opacity


getStatus = ->
  return {
    enabled:  eyejs.enabled
    size:     eyejs.indicator.size
    opacity:  eyejs.indicator.opacity()
  }


Mousetrap.bind 'ctrl', ->
  console.log 'clicking!'
  eyejs.triggerEvents 'click'


if chrome?

  chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->

    switch request.msg
      when 'eyejs:enable'
        eyejs.enable()
        localStorage['enabled'] = true

      when 'eyejs:disable'
        eyejs.disable()
        localStorage['enabled'] = false

      when 'eyejs:getstatus' then null

      when 'eyejs:resize'
        eyejs.indicator.resize +request.val
        localStorage['size'] = +request.val

      when 'eyejs:setopacity'
        eyejs.indicator.opacity +request.val
        localStorage['opacity'] = +request.val

      when 'eyejs:calibrate'
        eyejs.calibrate()

    sendResponse getStatus()
