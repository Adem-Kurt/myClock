local ui = require("ui")
local sys = require("sys")

Stopwatch = Object(ui.Panel)

function Stopwatch:constructor(...)
    local Stopwatch = ui.Panel.constructor(self, ...)

    self.stopwatchTimeLabel = ui.Label(Stopwatch, "00:00:00.000", 0, 20, 0, 60)
    self.stopwatchTimeLabel.fontsize = 50
    self.stopwatchTimeLabel.textalign = "center"

    self.stopwatchStartStopButton = ui.Button(Stopwatch, "Start", 0, 100, 100, 30)
    self.stopwatchResetButton = ui.Button(Stopwatch, "Reset", 0, 100, 100, 30)

    self.running = false
    self.startTime = nil
    self.elapsed = 0

    function self.stopwatchStartStopButton:onClick()
        local parent = self.parent
        if not parent.running then
            parent.running = true
            parent.startTime = sys.Datetime()
            self.text = "Stop"
        else
            local now = sys.Datetime()
            local diff = now:interval(parent.startTime, "seconds") / 1000
            parent.elapsed = parent.elapsed + diff
            parent.running = false
            self.text = "Start"
        end
    end

    function self.stopwatchResetButton:onClick()
        local parent = self.parent
        parent.running = false
        parent.elapsed = 0
        parent.stopwatchTimeLabel.text = "00:00:00.000"
        parent.stopwatchStartStopButton.text = "Start"
    end

    local i = 0
    local task = sys.Task(function()
        while not ui.task.terminated do
            if self.running then
                i = i + 1
                local now = sys.Datetime()
                local diff = now:interval(self.startTime, "seconds") / 1000
                local total = self.elapsed + diff
                local h = math.floor(total / 3600)
                local m = math.floor((total % 3600) / 60)
                local s = math.floor(total % 60)
                local ms = math.floor((total % 1) * 1000)
                self.stopwatchTimeLabel.text = string.format("%02d:%02d:%02d.%03d", h, m, s, ms)
            end
            sleep()
        end
    end)
    task()
end

function Stopwatch:onResize()
    self.stopwatchTimeLabel.width = self.width
    local stopwatchElementsHeight = self.stopwatchTimeLabel.height + self.stopwatchStartStopButton.height + 20
    local stopwatchStartY = (self.height - stopwatchElementsHeight) / 2
    self.stopwatchTimeLabel.y = stopwatchStartY

    local buttonWidth = 100
    local buttonSpacing = 10
    local totalButtonsWidth = (buttonWidth * 2) + buttonSpacing
    local startX = (self.width - totalButtonsWidth) / 2

    self.stopwatchStartStopButton.x = startX
    self.stopwatchStartStopButton.y = self.stopwatchTimeLabel.y + self.stopwatchTimeLabel.height + 20
    self.stopwatchResetButton.x = startX + buttonWidth + buttonSpacing
    self.stopwatchResetButton.y = self.stopwatchTimeLabel.y + self.stopwatchTimeLabel.height + 20
end

return Stopwatch
