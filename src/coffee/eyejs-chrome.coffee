# Pull-in the Mousetrap lib.
require './../../lib/mousetrap/mousetrap'

EyeJS = require '/Users/josh/work/eyejs'

eyejs = new EyeJS()

vscroll = require 'vscroll'

_ = require 'lodash'

# Scroller
window.addEventListener 'load', ->

  eyejs.on 'gaze', _.throttle (e) ->
    MAX_VELOCITY = 900
    THRESHOLD = 150
    EDGE_FUZZ = 30
    if e.y >= -EDGE_FUZZ and e.y < THRESHOLD
      q = (THRESHOLD - e.y) / THRESHOLD
      v = q * MAX_VELOCITY
      vscroll.velocity 0, -v
    else if e.y > window.innerHeight - THRESHOLD and e.y < window.innerHeight + EDGE_FUZZ
      q = (e.y - window.innerHeight + THRESHOLD) / THRESHOLD
      v = q * MAX_VELOCITY
      vscroll.velocity 0, v
    else
      vscroll.velocity 0, 0
  , 200


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



forwardBackShowTimer = null

showForwardBackButtons = (e) ->
  if e.x >= 10 and e.x <= window.innerWidth - 10 then return
  back = document.getElementById('eyejs-back')
  forward = document.getElementById('eyejs-forward')
  if !back or !forward then return
  if e.x < 10
    back.classList.add('eyejs-show')
  else if e.x > window.innerWidth - 10
    forward.classList.add('eyejs-show')
  resetForwardBackButtonTimer()

hideForwardBackButtons = ->
  back = document.getElementById('eyejs-back')
  forward = document.getElementById('eyejs-forward')
  if !back or !forward then return
  back.classList.remove('eyejs-show')
  forward.classList.remove('eyejs-show')

resetForwardBackButtonTimer = ->
  clearTimeout forwardBackShowTimer
  forwardBackShowTimer = setTimeout hideForwardBackButtons, 2000

addForwardBackButtons = ->
  fwd  = document.createElement 'div'
  back = document.createElement 'div'
  fwd.id = 'eyejs-forward'
  back.id = 'eyejs-back'
  fwd.setAttribute 'data-eyejs-snap', ''
  back.setAttribute 'data-eyejs-snap', ''
  document.body.appendChild fwd
  document.body.appendChild back
  fwd.addEventListener 'gaze', resetForwardBackButtonTimer
  back.addEventListener 'gaze', resetForwardBackButtonTimer
  fwd.addEventListener 'click', -> window.history.forward()
  back.addEventListener 'click', -> window.history.back()
  eyejs.on 'gaze', showForwardBackButtons

window.addEventListener 'load', addForwardBackButtons

Mousetrap.bind 'ctrl', ->
  eyejs.triggerEvents 'click'

# Don't prevent triggering a click if inside a form element.
# @see http://craig.is/killing/mice
Mousetrap.stopCallback = -> false

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
