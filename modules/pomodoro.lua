local ui = require("ui")
local sys = require("sys")
local alarm = require("modules.alarm")

Pomodoro = Object(ui.Panel)

function Pomodoro:constructor(...)
    local Pomodoro = ui.Panel.constructor(self, ...)

    self.alarm = alarm()

    self.pomodoroTimeLabel = ui.Label(Pomodoro, "25:00", 0, 20, 0, 60)
    self.pomodoroTimeLabel.fontsize = 50
    self.pomodoroTimeLabel.textalign = "center"

    self.pomodoroStartStopButton = ui.Button(Pomodoro, "Start", 0, 150, 100, 30)
    self.pomodoroResetButton = ui.Button(Pomodoro, "Reset", 0, 150, 100, 30)

    self.pomodoroSessionLabel = ui.Label(Pomodoro, "Pomodoro", 0, 200, 0, 30)
    self.pomodoroSessionLabel.textalign = "center"
    self.pomodoroSessionLabel.fontsize = 20

    self.pomodoroCounterLabel = ui.Label(Pomodoro, "Session 1/8", 0, 230, 0, 25)
    self.pomodoroCounterLabel.textalign = "center"
    self.pomodoroCounterLabel.fontsize = 14

    self.running = false
    self.alarmRinging = false
    self.sessions = {
        { name = "Pomodoro", duration = 25 * 60 },
        { name = "Short Break", duration = 5 * 60 },
        { name = "Pomodoro", duration = 25 * 60 },
        { name = "Short Break", duration = 5 * 60 },
        { name = "Pomodoro", duration = 25 * 60 },
        { name = "Short Break", duration = 5 * 60 },
        { name = "Pomodoro", duration = 25 * 60 },
        { name = "Long Break", duration = 15 * 60 },
    }
    self.currentSessionIndex = 1
    self.remainingTime = self.sessions[self.currentSessionIndex].duration
    self.startTime = nil
    self.pausedTime = 0

    function self.pomodoroStartStopButton:onClick()
        local parent = self.parent
        parent:startStop()
    end

    function self.pomodoroResetButton:onClick()
        local parent = self.parent
        parent:reset()
    end

    local task = sys.Task(function()
        while not ui.task.terminated do
            if self.running then
                local now = sys.Datetime()
                local elapsedTime = now:interval(self.startTime, "seconds")
                self.remainingTime = self.sessions[self.currentSessionIndex].duration - elapsedTime - self.pausedTime

                if self.remainingTime <= 0 then
                    self:nextSession()
                else
                    local minutes = math.floor(self.remainingTime / 60)
                    local seconds = math.floor(self.remainingTime % 60)
                    self.pomodoroTimeLabel.text = string.format("%02d:%02d", minutes, seconds)
                end
            end
            sleep()
        end
    end)
    task()
end

function Pomodoro:startStop()
    if self.alarmRinging then
        self.alarm:stop()
        self.alarmRinging = false

        if self.currentSessionIndex < #self.sessions then
            self.currentSessionIndex = self.currentSessionIndex + 1
        else
            self.currentSessionIndex = 1
            ui.mainWindow:notify("🎉", "Pomodoro cycle completed!", "none")
        end

        self:updateSessionUI()
        self.pomodoroStartStopButton.text = "Start"
        self:updateButtonsLayout()
    elseif not self.running then
        self.running = true
        self.startTime = sys.Datetime()
        self.pausedTime = 0
        self.pomodoroStartStopButton.text = "Stop"
    else
        self.running = false
        self.pomodoroStartStopButton.text = "Start"
    end
end

function Pomodoro:reset()
    self.running = false
    self.alarm:stop()
    self.alarmRinging = false
    self.currentSessionIndex = 1
    self:updateSessionUI()
    self.pomodoroStartStopButton.text = "Start"
    self:updateButtonsLayout()
end

function Pomodoro:nextSession()
    self.running = false
    self.alarmRinging = true
    self.pomodoroStartStopButton.text = "Stop"

    local currentSession = self.sessions[self.currentSessionIndex]
    ui.mainWindow:notify("🎉", currentSession.name .. " finished!", "none")
    self.alarm:play()
    self:updateButtonsLayout()
end

function Pomodoro:updateSessionUI()
    self.remainingTime = self.sessions[self.currentSessionIndex].duration
    self.pausedTime = 0
    self.startTime = nil

    local session = self.sessions[self.currentSessionIndex]
    self.pomodoroSessionLabel.text = session.name
    self.pomodoroCounterLabel.text = "Session " .. self.currentSessionIndex .. "/" .. #self.sessions

    local minutes = math.floor(self.remainingTime / 60)
    local seconds = math.floor(self.remainingTime % 60)
    self.pomodoroTimeLabel.text = string.format("%02d:%02d", minutes, seconds)
end

function Pomodoro:updateButtonsLayout()
    local yPos = self.pomodoroTimeLabel.y + self.pomodoroTimeLabel.height + 20
    if self.alarmRinging then
        self.pomodoroResetButton.visible = false
        self.pomodoroStartStopButton.width = 210
        self.pomodoroStartStopButton.x = (self.width - self.pomodoroStartStopButton.width) / 2
        self.pomodoroStartStopButton.y = yPos
    else
        self.pomodoroResetButton.visible = true
        local buttonWidth = 100
        local buttonSpacing = 10
        local totalButtonsWidth = (buttonWidth * 2) + buttonSpacing
        local startXButtons = (self.width - totalButtonsWidth) / 2

        self.pomodoroStartStopButton.width = buttonWidth
        self.pomodoroStartStopButton.x = startXButtons
        self.pomodoroStartStopButton.y = yPos

        self.pomodoroResetButton.x = startXButtons + buttonWidth + buttonSpacing
        self.pomodoroResetButton.y = yPos
    end
end

function Pomodoro:onResize()
    self.pomodoroTimeLabel.width = self.width
    local pomodoroElementsHeight = self.pomodoroTimeLabel.height + self.pomodoroStartStopButton.height + self.pomodoroSessionLabel.height + self.pomodoroCounterLabel.height + 60
    local pomodoroStartY = (self.height - pomodoroElementsHeight) / 2
    self.pomodoroTimeLabel.y = pomodoroStartY

    self:updateButtonsLayout()

    self.pomodoroSessionLabel.width = self.width
    self.pomodoroSessionLabel.y = self.pomodoroStartStopButton.y + self.pomodoroStartStopButton.height + 20

    self.pomodoroCounterLabel.width = self.width
    self.pomodoroCounterLabel.y = self.pomodoroSessionLabel.y + self.pomodoroSessionLabel.height + 10
end

return Pomodoro
