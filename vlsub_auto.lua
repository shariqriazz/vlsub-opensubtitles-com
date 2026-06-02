-- Background auto-fetch interface for VLSub OpenSubtitles.com.
-- Install to lua/intf and start with: --extraintf luaintf --lua-intf vlsub_auto

local extension_path = vlc.config.userdatadir()
  .. "/lua/extensions/vlsubcom.lua"
local log_path = vlc.config.userdatadir()
  .. "/lua/extensions/userdata/vlsub.com/auto_fetch.log"

local function log(message)
  local text = "[VLSub AutoFetch Intf] " .. tostring(message)
  vlc.msg.dbg(text)

  local f = io.open(log_path, "a")
  if f then
    f:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. text .. "\n")
    f:close()
  end
end

local function sleep(seconds)
  if vlc.misc and vlc.misc.mwait and vlc.misc.mdate then
    vlc.misc.mwait(vlc.misc.mdate() + seconds * 1000000)
  else
    os.execute("sleep " .. tonumber(seconds))
  end
end

local ok, err = pcall(dofile, extension_path)
if not ok then
  log("failed to load extension: " .. tostring(err))
  return
end

if type(vlsub_background_init) ~= "function" or
   type(vlsub_background_tick) ~= "function" then
  log("extension does not expose background functions")
  return
end

local initialized = false
while true do
  if not initialized then
    local init_ok, init_result = pcall(vlsub_background_init)
    initialized = init_ok and init_result == true
    if not initialized then
      log("background init pending: " .. tostring(init_result))
      sleep(5)
    end
  else
    local tick_ok, tick_err = pcall(vlsub_background_tick)
    if not tick_ok then
      log("background tick failed: " .. tostring(tick_err))
      initialized = false
      sleep(5)
    else
      sleep(2)
    end
  end
end
