local ui = require "ui"
local Settings = require "modules.settings"
local Stopwatch = require "modules.stopwatch"
local Timer = require "modules.timer"
local Pomodoro = require "modules.pomodoro"
local AboutWindow = require "modules.aboutWindow"
local settings = Settings()

if settings:get("theme") ~= "default" then
    ui.theme = settings:get(settings:get("theme"))
end

local window = ui.Window("", "raw",settings:get("window.width"), settings:get("window.height"))
window.x = settings:get("window.x")
window.y = settings:get("window.y")
window.maximized = settings:get("window.maximized")
window.topmost = settings:get("window.alwaysOnTop")
if window.maximized then window:maximize() end
function window:toggleMaximize()
    if window.maximized then
        window:restore()
    elseif not window.maximized then
        window:maximize()
    end
end
function window:toggleFullscreen()
    window.fullscreen = not window.fullscreen
    window:updateLayout()
end
function window:onMaximize()
    self.maximized = true
    self.updateLayout()
end
function window:onRestore()
    if not window.fullscreen then
        window.maximized = false
    end
    self.updateLayout()
end
window:status()

local windowBarHeight = 30
local statusBarHeight = 23


local windowBar = ui.Panel(window, 0, 0, 0, windowBarHeight)
function windowBar:onClick() window:startmoving() end
function windowBar:onDoubleClick() window:toggleMaximize() end
local WindowBarIcon = ui.Picture(windowBar, sys.File("assets/icons/icon.png"), 10, 5, windowBarHeight - 10, windowBarHeight - 10)

local windowBarOpenStopwatchButton = ui.Button(windowBar, "", WindowBarIcon.x + windowBarHeight - 5, 5, windowBarHeight - 10, windowBarHeight - 10)
windowBarOpenStopwatchButton.hastext = false
windowBarOpenStopwatchButton.tooltip = "Open Stopwatch"
windowBarOpenStopwatchButton:loadicon(sys.File("assets/icons/stopwatch.ico"))

local windowBarOpenTimerButton = ui.Button(windowBar, "", windowBarOpenStopwatchButton.x + windowBarHeight - 5, 5, windowBarHeight - 10, windowBarHeight - 10)
windowBarOpenTimerButton.hastext = false
windowBarOpenTimerButton.tooltip = "Open Timer"
windowBarOpenTimerButton:loadicon(sys.File("assets/icons/timer.ico"))

local windowBarOpenPomodoroButton = ui.Button(windowBar, "", windowBarOpenTimerButton.x + windowBarHeight - 5, 5, windowBarHeight - 10, windowBarHeight - 10)
windowBarOpenPomodoroButton.hastext = false
windowBarOpenPomodoroButton.tooltip = "Open Pomodoro"
windowBarOpenPomodoroButton:loadicon(sys.File("assets/icons/pomodoro.ico"))

local windowBarTitle = ui.Label(windowBar, "", 0, 0, 0, windowBarHeight)
windowBarTitle.fontsize = 10
windowBarTitle.textalign = "center"
function windowBarTitle:onClick() window:startmoving() end
function windowBarTitle:onDoubleClick() window:toggleMaximize() end

local closeLabel = ui.Label(windowBar, "\xc3\x97", 0, 0, 45, windowBarHeight)
closeLabel.fontsize = 15
closeLabel.textalign = "center"
function closeLabel:onHover() closeLabel.bgcolor = 0xFF0000 end
function closeLabel:onLeave() closeLabel.bgcolor = nil end
function closeLabel:onClick()
    window:onClose()
    window:hide()
end

local maximizeLabel = ui.Label(windowBar, "□", 0, 0, 45, windowBarHeight)
function maximizeLabel:onClick() window:toggleMaximize() end
function maximizeLabel:onHover() maximizeLabel.bgcolor = 0x373737 end
function maximizeLabel:onLeave() maximizeLabel.bgcolor = nil end
maximizeLabel.fontsize = 15
maximizeLabel.textalign = "center"

local minimizeLabel = ui.Label(windowBar, "-", 0, 0, 45, windowBarHeight)
function minimizeLabel:onHover() minimizeLabel.bgcolor = 0x373737 end
function minimizeLabel:onLeave() minimizeLabel.bgcolor = nil end
function minimizeLabel:onClick() window:minimize() end
minimizeLabel.fontsize = 15
minimizeLabel.textalign = "center"

local windowBarMenu = ui.Menu()
local windowBarMenuAlwaysOnTopItem = windowBarMenu:add("Always On Top")
windowBarMenuAlwaysOnTopItem.onClick = function(self)
    window.topmost = not window.topmost
    self.checked = window.topmost
end
windowBarMenuAlwaysOnTopItem.checked = window.topmost

windowBarMenu:add("")

local windowBarMenuAboutItem = windowBarMenu:add("About")
windowBarMenuAboutItem.onClick = function()
    local about = AboutWindow()
    window:showmodal(about)
end

local windowBarMenuLabel = ui.Label(windowBar, "⋯", 0, 0, 45, windowBarHeight)
windowBarMenuLabel.fontsize = 15
windowBarMenuLabel.textalign = "center"
function windowBarMenuLabel:onHover() windowBarMenuLabel.bgcolor = 0x373737 end
function windowBarMenuLabel:onLeave() windowBarMenuLabel.bgcolor = nil end
function windowBarMenuLabel:onClick() window:popup(windowBarMenu) end

local function setWindowTitle(title)
    windowBarTitle.text = title
    window.title = title
end
setWindowTitle("myClock")

local contentPanel = ui.Panel(window, 0, windowBarHeight, 0, 0)
contentPanel.bgcolor = 0x202020

local stopwatchPanel = Stopwatch(contentPanel, 0, 0, 0, 0)
stopwatchPanel.bgcolor = 0x202020

local timerPanel = Timer(contentPanel, 0, 0, 0, 0)
timerPanel.bgcolor = 0x202020

local pomodoroPanel = Pomodoro(contentPanel, 0, 0, 0, 0)
pomodoroPanel.bgcolor = 0x202020


local activePanel = nil

local function showPanel(mode)
if mode == "stopwatch" then
        stopwatchPanel:tofront()
        activePanel = stopwatchPanel
    elseif mode == "timer" then
        timerPanel:tofront()
        activePanel = timerPanel
    elseif mode == "pomodoro" then
        pomodoroPanel:tofront()
        activePanel = pomodoroPanel
    else
        stopwatchPanel:tofront()
        activePanel = stopwatchPanel
    end
end

function windowBarOpenStopwatchButton:onClick() showPanel("stopwatch") end
function windowBarOpenTimerButton:onClick()     showPanel("timer") end
function windowBarOpenPomodoroButton:onClick()  showPanel("pomodoro") end

function window:updateLayout()
    local windowHeight = window.height
    local windowWidth = window.width

    if window.maximized and not window.fullscreen then
        windowHeight = windowHeight - 14
        windowWidth = windowWidth - 14

        windowBar.visible = true
        windowBar.x = 8
        windowBar.y = 7
        contentPanel.x = windowBar.x
        contentPanel.y = windowBar.y + windowBar.height
        contentPanel.height = windowHeight - windowBarHeight - statusBarHeight + 8
    elseif window.fullscreen then
        windowBar.visible = false
        contentPanel.y = 0
        contentPanel.x = 0
        contentPanel.height = windowHeight - statusBarHeight
    else
        windowBar.visible = true
        windowBar.x = 0
        windowBar.y = 0
        contentPanel.x = 0
        contentPanel.y = windowBar.y + windowBar.height
        contentPanel.height = windowHeight - windowBarHeight - statusBarHeight
    end

    windowBar.width = windowWidth

    closeLabel.x = windowWidth - 45
    maximizeLabel.x = windowWidth - 90
    minimizeLabel.x = windowWidth - 135
    windowBarMenuLabel.x = windowWidth - 180

    windowBarTitle.x = windowBarOpenPomodoroButton.x + windowBarOpenPomodoroButton.width
    windowBarTitle.width = windowBarMenuLabel.x - (windowBarOpenPomodoroButton.x + windowBarOpenPomodoroButton.width)

    contentPanel.width = windowWidth

    stopwatchPanel.width = contentPanel.width
    stopwatchPanel.height = contentPanel.height

    timerPanel.width = contentPanel.width
    timerPanel.height = contentPanel.height

    pomodoroPanel.width = contentPanel.width
    pomodoroPanel.height = contentPanel.height
end
function window:onResize() window:updateLayout() end
function window:onMove()   window:updateLayout() end


function window:onClose()
    settings:set("window.alwaysOnTop", window.topmost)
    settings:set("window.maximized", window.maximized)
    if self.fullscreen then window.fullscreen = false end
    if self.maximized then window:restore() end
    settings:set("window.x", window.x)
    settings:set("window.y", window.y)
    settings:set("window.width", window.width)
    settings:set("window.height", window.height)
end

window:shortcut(settings:get("shortcuts.toggleFullscreen"), window.toggleFullscreen)
window:shortcut(settings:get("shortcuts.startStop"), function()
    if activePanel and activePanel.toggle then
        activePanel:toggle()
    end
end)
window:shortcut(settings:get("shortcuts.reset"), function()
    if activePanel and activePanel.reset then
        activePanel:reset()
    end
end)
window:shortcut(settings:get("shortcuts.showStopwatch"), function() showPanel("stopwatch") end)
window:shortcut(settings:get("shortcuts.showTimer"), function() showPanel("timer") end)
window:shortcut(settings:get("shortcuts.showPomodoro"), function() showPanel("pomodoro") end)

showPanel("timer")
window:updateLayout()

await(window:showasync())
