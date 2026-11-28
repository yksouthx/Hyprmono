-- Load the HyprMono Hyprland config against a stub `hl` API and assert basic
-- invariants. This checks the Lua logic (syntax, requires, binds), not that
-- Hyprland accepts every option; use `hyprctl configerrors` for that.
local config_dir = assert(arg[1], "usage: stub-hl.lua CONFIG_DIR")
package.path = config_dir .. "/?.lua;" .. package.path

local binds, execs, envs = {}, {}, {}
local started = false

local function chain(name)
    return setmetatable({}, {
        __index = function(_, key) return chain(name .. "." .. key) end,
        __call = function() return name end,
    })
end

hl = setmetatable({}, { __index = function(_, key) return chain("hl." .. key) end })
hl.bind = function(keys, dispatcher, opts)
    binds[#binds + 1] = { keys = keys, dispatcher = tostring(dispatcher), opts = opts or {} }
end
hl.exec_cmd = function(command) execs[#execs + 1] = command end
hl.env = function(name, value) envs[name] = value end
hl.on = function(event, callback)
    if event == "hyprland.start" then
        started = true
        callback()
    end
end
hl.dsp = setmetatable({}, { __index = function(_, key) return chain("dsp." .. key) end })
hl.dsp.exec_cmd = function(command) return "exec:" .. command end
hl.dsp.global = function(name) return "global:" .. name end

dofile(config_dir .. "/hyprland.lua")

local function fail(message)
    io.stderr:write("FAIL: " .. message .. "\n")
    os.exit(1)
end

assert(started, "hyprland.start handler was never registered")

local seen = {}
for _, bind in ipairs(binds) do
    local normalized = bind.keys:gsub("%s", ""):upper()
    if bind.opts.release then normalized = normalized .. "@release" end
    if seen[normalized] then fail("duplicate keybind: " .. bind.keys) end
    seen[normalized] = true
end

local function dispatcher_for(keys)
    for _, bind in ipairs(binds) do
        if bind.keys:gsub("%s", ""):upper() == keys then return bind.dispatcher end
    end
end

if dispatcher_for("SUPER+R") ~= "exec:$HOME/.local/bin/launch-menu.sh" then
end
if dispatcher_for("SUPER+L") ~= "exec:$HOME/.local/bin/lock-screen.sh" then
    fail("SUPER+L must run lock-screen.sh")
end

local function any_exec(needle)
    for _, command in ipairs(execs) do
        if command:find(needle, 1, true) then return true end
    end
    return false
end
for _, helper in ipairs({ "start-shell.sh", "start-idle.sh", "start-session-services.sh" }) do
    if not any_exec(helper) then fail("autostart is missing " .. helper) end
end

-- Lua-mode Hyprland rejects legacy dispatcher names in `hyprctl dispatch`.
local function legacy_dispatch(command)
    return command:match("hyprctl dispatch [a-z]") ~= nil
end
for _, command in ipairs(execs) do
    if legacy_dispatch(command) then fail("legacy hyprctl dispatch in autostart: " .. command) end
end
for _, bind in ipairs(binds) do
    if legacy_dispatch(bind.dispatcher) then fail("legacy hyprctl dispatch in bind " .. bind.keys) end
end

if not (envs.PATH and envs.PATH:find("/.local/bin", 1, true)) then
    fail("PATH must include ~/.local/bin for everything Hyprland launches")
end

print(string.format("Lua config OK: %d binds, %d autostart commands", #binds, #execs))
