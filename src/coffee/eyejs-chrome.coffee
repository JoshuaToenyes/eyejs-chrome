# Pull-in the Mousetrap lib.
require './../../lib/mousetrap/mousetrap'

EyeJS = require '/Users/josh/work/eyejs'

disableEyeJS = /disable\-eyejs/.test(window.location.search) or document.body.hasAttribute 'data-eyejs-disable'

eyejs = new EyeJS()

vscroll = require 'vscroll'

_ = require 'lodash'

recorder = require '/Users/josh/Dropbox/eyejs-trial/recorder/dist/recorder-client'

recordEyeEvent = (type, e) ->
  msg =
    event:   type
    element: recorder.serializeNode e
  recorder.send msg

eyejs.on 'blink', (e) ->
  recordEyeEvent 'blink', e

eyejs.on 'fixation', (e) ->
  recordEyeEvent 'fixation', e

eyejs.on 'fixationend', (e) ->
  recordEyeEvent 'fixationend', e

eyejs.on 'gaze', (e) ->
  e.event = 'gaze'
  e.el    = recorder.serializeNode e.el
  recorder.send e

# Retrieve and update the local storage settings...
chrome.storage.local.get 'config', (storage = {}) ->
  config  = storage.config
  enabled = if config.enabled? then config.enabled else eyejs.enabled
  size    = if config.size?    then config.size    else eyejs.indicator.size
  opacity = if config.opacity? then config.opacity else eyejs.indicator.opacity()

  if enabled then eyejs.enable()
  eyejs.indicator.resize size
  eyejs.indicator.opacity opacity

  # Disable for special cases...
  if disableEyeJS then eyejs.disable()


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
  if disableEyeJS then return
  fwd  = document.createElement 'div'
  back = document.createElement 'div'
  fwd.id = 'eyejs-forward'
  back.id = 'eyejs-back'
  fwd.setAttribute 'data-eyejs-snap', ''
  back.setAttribute 'data-eyejs-snap', ''
  fwd.style.zIndex = 10000000
  back.style.zIndex = 10000000
  document.body.appendChild fwd
  document.body.appendChild back
  fwd.addEventListener 'gaze', resetForwardBackButtonTimer
  back.addEventListener 'gaze', resetForwardBackButtonTimer
  fwd.addEventListener 'click', -> window.history.forward()
  back.addEventListener 'click', -> window.history.back()
  eyejs.on 'gaze', showForwardBackButtons

addForwardBackButtons()




scrollBarShowTimer = null

showScrollBars = (e) ->
  if e.y > 10 and e.y <= window.innerHeight - 10 then return
  up = document.getElementById('eyejs-scroll-up')
  down = document.getElementById('eyejs-scroll-down')
  if !up or !down then return
  if e.y < 10
    up.classList.add('eyejs-show')
  else if e.y > window.innerHeight - 10
    down.classList.add('eyejs-show')
  resetScrollBarTimer()

hideScrollBars = ->
  up = document.getElementById('eyejs-scroll-up')
  down = document.getElementById('eyejs-scroll-down')
  if !up or !down then return
  up.classList.remove('eyejs-show')
  down.classList.remove('eyejs-show')
  vscroll.velocity 0, 0
  eyejs.removeListener 'gaze', scrollUp
  eyejs.removeListener 'gaze', scrollDown

resetScrollBarTimer = ->
  clearTimeout scrollBarShowTimer
  scrollBarShowTimer = setTimeout hideScrollBars, 2000

MAX_SCROLL_VELOCITY = 900
SCROLL_THRESHOLD = 150

startedScrolling = null
scrollTimer = null

# scrollUp = _.throttle (e) ->
#   q = (e.y - window.innerHeight + SCROLL_THRESHOLD) / SCROLL_THRESHOLD
#   v = q * MAX_SCROLL_VELOCITY
#   vscroll.velocity 0, v
# , 200
#
# scrollDown = _.throttle (e) ->
#   q = (SCROLL_THRESHOLD - e.y) / SCROLL_THRESHOLD
#   v = q * MAX_SCROLL_VELOCITY
#   vscroll.velocity 0, -v
# , 200

_scrollUp = ->
  v = (_.now() - startedScrolling) / 3
  vscroll.velocity 0, -Math.pow(v, 1.2)

_scrollDown = ->
  v = (_.now() - startedScrolling) / 3
  vscroll.velocity 0, Math.pow(v, 1.2)

scrollUp = ->
  startedScrolling = _.now()
  scrollTimer = setInterval _scrollUp, 50

scrollDown = (e) ->
  startedScrolling = _.now()
  scrollTimer = setInterval _scrollDown, 50

stopScrolling = ->
  clearInterval scrollTimer
  vscroll.velocity 0, 0

addScrollBars = ->
  if disableEyeJS then return
  up  = document.createElement 'div'
  down = document.createElement 'div'
  up.id = 'eyejs-scroll-up'
  down.id = 'eyejs-scroll-down'
  up.setAttribute 'data-eyejs-snap', ''
  down.setAttribute 'data-eyejs-snap', ''
  up.style.zIndex = 10000000
  down.style.zIndex = 10000000
  document.body.appendChild up
  document.body.appendChild down
  up.addEventListener 'gaze', resetScrollBarTimer
  down.addEventListener 'gaze', resetScrollBarTimer
  up.addEventListener 'fixation', scrollUp
  up.addEventListener 'fixationend', stopScrolling
  down.addEventListener 'fixation', scrollDown
  down.addEventListener 'fixationend', stopScrolling
  eyejs.on 'gaze', showScrollBars

addScrollBars()


Mousetrap.bind 'ctrl', ->
  eyejs.triggerGazeEvents 'click'

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
