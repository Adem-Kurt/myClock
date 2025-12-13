local ui = require("ui")
local sys = require("sys")
local alarm = require("modules.alarm")

Timer = Object(ui.Panel)

function Timer:constructor(...)
    local timer = ui.Panel.constructor(self, ...)

    self.alarm = alarm()

    self.timerTimeLabel = ui.Label(timer, "00:00:00", 0, 20, 0, 60)
    self.timerTimeLabel.fontsize = 50
    self.timerTimeLabel.textalign = "center"

    self.timerHoursInput = ui.Entry(timer, "00", 0, 100, 70, 30)
    self.timerHoursInput.textalign = "center"
    self.timerHoursInput.fontsize = 15

    self.timerMinutesInput = ui.Entry(timer, "00", 0, 100, 70, 30)
    self.timerMinutesInput.textalign = "center"
    self.timerMinutesInput.fontsize = 15

    self.timerSecondsInput = ui.Entry(timer, "00", 0, 100, 70, 30)
    self.timerSecondsInput.textalign = "center"
    self.timerSecondsInput.fontsize = 15

    local function removeString(s)
        if #s.text > 0 and tonumber(s.text) == nil then
            s.text = s.text:gsub("%D", "")
        end
    end

    self.timerHoursInput.onChange, self.timerMinutesInput.onChange, self.timerSecondsInput.onChange = removeString, removeString, removeString

    self.timerStartStopButton = ui.Button(timer, "Start", 0, 150, 100, 30)
    self.timerResetButton = ui.Button(timer, "Reset", 0, 150, 100, 30)

    self.running = false
    self.pausedTime = 0
    self.startTime = sys.Datetime()
    self.totalSeconds = 0
    self.remainingSeconds = 0
    self.alarmRinging = false

    function self:reset()
        self.running = false
        self.totalSeconds = 0
        self.remainingSeconds = 0
        self.pausedTime = 0
        self.timerTimeLabel.text = "00:00:00"
        self.timerStartStopButton.text = "Start"
        self.alarm:stop()
        self.alarmRinging = false

        self.timerHoursInput.enabled = true
        self.timerMinutesInput.enabled = true
        self.timerSecondsInput.enabled = true
        self.timerHoursInput.text = "00"
        self.timerMinutesInput.text = "00"
        self.timerSecondsInput.text = "00"

        self:updateButtonsLayout()
    end

    function self:toggle()
        if self.alarmRinging then
            self:reset()
        elseif not self.running then
            self.running = true
            if self.remainingSeconds == 0 then
                local hours = tonumber(self.timerHoursInput.text) or 0
                local minutes = tonumber(self.timerMinutesInput.text) or 0
                local seconds = tonumber(self.timerSecondsInput.text) or 0

                self.totalSeconds = (hours * 3600) + (minutes * 60) + seconds
                self.remainingSeconds = self.totalSeconds
                self.pausedTime = 0

                if self.totalSeconds == 0 then
                    self.running = false
                    return
                end

                self.timerHoursInput.enabled = false
                self.timerMinutesInput.enabled = false
                self.timerSecondsInput.enabled = false
            else
                self.pausedTime = self.totalSeconds - self.remainingSeconds
            end

            self.startTime = sys.Datetime()
            self.timerStartStopButton.text = "Stop"
        else
            self.running = false
            self.timerStartStopButton.text = "Start"
        end
    end

    function self.timerStartStopButton:onClick()
        self.parent:toggle()
    end

    function self.timerResetButton:onClick()
        self.parent:reset()
    end

    local task = sys.Task(function()
        while not ui.task.terminated do
            if self.running then
                if self.remainingSeconds <= 0 then
                    self.remainingSeconds = 0
                    self.running = false
                    self.alarmRinging = true
                    self.timerStartStopButton.text = "Stop"

                    self:updateButtonsLayout()
                    self.alarm:play()
                    ui.mainWindow:notify("🎉", "Time is up", "none")
                else
                    local now = sys.Datetime()
                    local elapsedTime = now:interval(self.startTime, "seconds")

                    self.remainingSeconds = self.totalSeconds - elapsedTime - self.pausedTime

                    local h = math.floor(self.remainingSeconds / 3600)
                    local m = math.floor((self.remainingSeconds % 3600) / 60)
                    local s = math.floor(self.remainingSeconds % 60)
                    self.timerTimeLabel.text = string.format("%02d:%02d:%02d", h, m, s)
                end
            end
            sleep()
        end
    end)
    task()
end

function Timer:updateButtonsLayout()
    local yPos = self.timerHoursInput.y + self.timerHoursInput.height + 20

    if self.alarmRinging then
        self.timerResetButton.visible = false
        self.timerStartStopButton.width = 210
        self.timerStartStopButton.x = (self.width - self.timerStartStopButton.width) / 2
        self.timerStartStopButton.y = yPos
    else
        self.timerResetButton.visible = true
        local buttonWidth = 100
        local buttonSpacing = 10
        local totalButtonsWidth = (buttonWidth * 2) + buttonSpacing
        local startXButtons = (self.width - totalButtonsWidth) / 2

        self.timerStartStopButton.width = buttonWidth
        self.timerStartStopButton.x = startXButtons
        self.timerStartStopButton.y = yPos

        self.timerResetButton.x = startXButtons + buttonWidth + buttonSpacing
        self.timerResetButton.y = yPos
    end
end

function Timer:onResize()
    self.timerTimeLabel.width = self.width
    local timerElementsHeight = self.timerTimeLabel.height + self.timerHoursInput.height + self.timerStartStopButton.height + 40
    local timerStartY = (self.height - timerElementsHeight) / 2
    self.timerTimeLabel.y = timerStartY

    local inputWidth = 70
    local inputSpacing = 10
    local totalInputsWidth = (inputWidth * 3) + (inputSpacing * 2)
    local startXInputs = (self.width - totalInputsWidth) / 2

    self.timerHoursInput.x = startXInputs
    self.timerHoursInput.y = self.timerTimeLabel.y + self.timerTimeLabel.height + 20

    self.timerMinutesInput.x = startXInputs + inputWidth + inputSpacing
    self.timerMinutesInput.y = self.timerTimeLabel.y + self.timerTimeLabel.height + 20

    self.timerSecondsInput.x = startXInputs + (inputWidth + inputSpacing) * 2
    self.timerSecondsInput.y = self.timerTimeLabel.y + self.timerTimeLabel.height + 20

    self:updateButtonsLayout()
end

return Timer
