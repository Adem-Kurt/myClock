local json = require "json"


local appSettingsFolder = sys.Directory(os.getenv("APPDATA") .. "\\myClock")
local defaultSettings = {
    window = {
        width = 800,
        height = 600,
        x = 100,
        y = 100,
        alwaysOnTop = false,
    },
    theme = "default",
    shortcuts = {
            toggleFullscreen = "f",
            startStop = "s",
            reset = "r",
            showStopwatch = "1",
            showTimer = "2",
            showPomodoro = "3",
        },
}


local Settings = Object{}

function Settings:constructor()
    if not appSettingsFolder.exists then
        appSettingsFolder:make()
    end
    self.settingsFile = sys.File(appSettingsFolder.path .. "\\settings.json")
end

function Settings:save()
    self.settingsFile:open("write")
    self.settingsFile:write(json.encode(self.settings))
    self.settingsFile:close()
end

function Settings:load()
    if not self.settingsFile.exists then
        self.settings = defaultSettings
        self:save()
    else
        self.settingsFile:open("read")
        local data = self.settingsFile:read()
        self.settingsFile:close()
        self.settings = json.decode(data)
    end
end

function Settings:get(key)
    self:load()

    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end

    local value = self.settings
    for _, k in ipairs(keys) do
        if type(value) == "table" and value[k] ~= nil then
            value = value[k]
        else
            value = nil
            break
        end
    end

    if value ~= nil then
        return value
    end

    local defaultValue = defaultSettings
    for _, k in ipairs(keys) do
        if type(defaultValue) == "table" then
            defaultValue = defaultValue[k]
        else
            defaultValue = nil
            break
        end
    end

    if defaultValue == nil then
        return nil
    end

    self:set(key, defaultValue)

    return defaultValue
end

function Settings:set(key, value)
    self:load()

    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end

    if #keys == 1 then
        self.settings[keys[1]] = value
        self:save()
        return
    end

    local current = self.settings
    for i = 1, #keys - 1 do
        local k = keys[i]
        if current[k] == nil or type(current[k]) ~= "table" then
            current[k] = {}
        end
        current = current[k]
    end

    current[keys[#keys]] = value
    self:save()
end

return Settings
