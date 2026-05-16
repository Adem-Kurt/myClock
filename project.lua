--! luart-extensions
-- project.lua: Improved build & run script for LuaRT projects
-- Uses luart-extensions for string interpolation and cleaner syntax

import yaml

local CONFIG_FILE = "project.yaml"

if not sys.File(CONFIG_FILE).exists then
    error("Configuration file '${CONFIG_FILE}' not found.")
end

local config = yaml.load(CONFIG_FILE)
local name   = config.name or "App"
local entry  = config.entry or "main.lua"
local output = config.output or "${name}.exe"
local icon   = config.icon
local desktopApp = config.desktopApp or false
local staticBuild = config.staticBuild or false
local libs   = config.modules or {}
local action = arg[1] or "help"

local function build()
    print("--- Build Process Started [${name} v${config.version or '1.0'}] ---")

    local versionFile = sys.File("src/version.lua")
    local commitHash = "unknown"

    local gitCheck = sys.cmd('git -v', true)

    if gitCheck == true then
        local handle = io.popen("git rev-parse --short HEAD 2>nul")
        commitHash = handle:read("*l") or "unknown"
        handle:close()
    else
        commitHash = "none"
    end

    versionFile:open("write", "binary")
    versionFile:write('return {\n    version = "' .. (config.version or "1.0") .. '",\n    commit = "' .. commitHash .. '"\n}\n')
    versionFile:close()
    print("Injected version: " .. (config.version or "1.0") .. " (" .. commitHash .. ")")

    local bin = sys.Directory("bin")
    if not bin.exists then bin:make() end

    local typeFlag = desktopApp and "-w" or "-c"
    local flags = staticBuild and "${typeFlag} -s" or typeFlag
    for _, lib in ipairs(libs) do
        flags = "${flags} -l${lib}"
        print("Adding module: ${lib}")
    end

    if icon then
        flags = '${flags} -i "${sys.currentdir}/src/${icon}"'
    end

    local outputPath = "${sys.currentdir}/bin/${output}"
    local oldCwd = sys.currentdir

    sys.currentdir = "${oldCwd}/src"

    local rtcCmd = 'rtc ${flags} -o "${outputPath}" "${entry}" .'
    print("Executing: ${rtcCmd}")

    local status = sys.cmd(rtcCmd)
    sys.currentdir = oldCwd

    versionFile:open("write", "binary")
    versionFile:write('return {\n    version = "dev",\n    commit = "none"\n}\n')
    versionFile:close()
    print("Reset version.lua to 'dev'")

    if sys.File(outputPath).exists then
        print("--- Build Completed Successfully! ---")
        print("Executable: ${outputPath}")
    else
        print("--- Build Failed (Status: ${status}) ---")
    end
end

local function run()
    print("--- Running Application [${name}] ---")
    local oldCwd = sys.currentdir
    sys.currentdir = "${oldCwd}/src"

    sys.cmd('wluart "${entry}"')

    sys.currentdir = oldCwd
end

local function clean()
    local bin = sys.Directory("bin")
    if bin.exists then
        bin:removeall()
        print("Cleaned: bin/")
    else
        print("Nothing to clean.")
    end
end

function help()
    print([[
Project Manager
Usage: luart project.lua [command]

Available commands:
  build    Compiles the project in 'src/' to 'bin/]] .. output .. [['
  run      Runs the project using wluart
  clean    Removes the 'bin/' directory
  help     Displays this help message
]])
end

if action == "build" then
    build()
elseif action == "run" then
    run()
elseif action == "clean" then
    clean()
elseif action == "help" then
    help()
else
    print("Error: Unknown command '${action}'")
    help()
end
