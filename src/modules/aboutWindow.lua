local ui = require("ui")
local version = require("version")

local aboutWindow = Object(ui.Window)

function aboutWindow:constructor()
    local winWidth, winHeight = 450, 320
    ui.Window.constructor(self, "About myClock", "raw", 450, 320)
    self.bgcolor = 0x181818

    self.icon = ui.Picture(self, sys.File("assets/icons/icon.png"), iconX, 40, 48, 48)
    self.icon.x = math.floor((winWidth - (48 / ui.dpi)) // 2)

    self.titleLabel = ui.Label(self, "myClock " .. version.version, 0, 110)
    self.titleLabel.fontsize = 16
    self.titleLabel.fgcolor = 0xFFFFFF
    self.titleLabel.x = (winWidth - self.titleLabel.width) // 2

    self.commitHeader = ui.Label(self, "Commit", 0, 155)
    self.commitHeader.fontsize = 9
    self.commitHeader.fgcolor = 0x888888
    self.commitHeader.x = (winWidth - self.commitHeader.width) // 2

    self.commitLabel = ui.Label(self, version.commit, 0, 175)
    self.commitLabel.fontsize = 10
    self.commitLabel.fgcolor = 0xCCCCCC
    self.commitLabel.x = (winWidth - self.commitLabel.width) // 2

    self.versionHeader = ui.Label(self, "Full Version", 0, 205)
    self.versionHeader.fontsize = 9
    self.versionHeader.fgcolor = 0x888888
    self.versionHeader.x = (winWidth - self.versionHeader.width) // 2

    self.fullVersionLabel = ui.Label(self, version.version .. "+" .. version.commit, 0, 225)
    self.fullVersionLabel.fontsize = 10
    self.fullVersionLabel.fgcolor = 0xCCCCCC
    self.fullVersionLabel.x = (winWidth - self.fullVersionLabel.width) // 2

    self.okButton = ui.Button(self, "Ok", 35, 270, 180, 30)
    function self.okButton:onClick()
        self.parent:hide()
    end

    self.copyButton = ui.Button(self, "Copy", 235, 270, 180, 30)
    self.copyButton.bgcolor = 0x2A3D5E
    self.copyButton.fgcolor = 0xFFFFFF
    self.copyButton.defaultText = self.copyButton.text
    self.copyButton.timerId = 0

    function self.copyButton:onClick()
        sys.clipboard = "myClock " .. version.version .. " (commit: " .. version.commit .. ")"

        self.text = "Copied!"
        self.timerTick = self.timerTick + 1
        local snapTick = self.timerTick

        sys.Task(function()
            sleep(3000)
            if self.timerTick == snapTick then
                self.text = self.lastText
            end
        end)()
    end

    self:center()
end

return aboutWindow
