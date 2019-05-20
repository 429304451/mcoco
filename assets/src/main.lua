-- 图片加载失败时 是否弹出消息框
cc.FileUtils:getInstance():setPopupNotify(false)
-- 平台 0-window,1-linux,2-mac,3-android, 4-iphone,5-ipad
__Platform__ = cc.Application:getInstance():getTargetPlatform()
trace = print
print("__Platform__", __Platform__)
--是否使用断点调试 （高性能消耗，版本发布必须关闭。）
local USE_BREAKPOINT_DEBUG = false -- __Platform__ == 0

local director = cc.Director:getInstance()
local view = director:getOpenGLView()
local framesize = view:getFrameSize()
--是否显示FPS调试信息
if CC_SHOW_FPS then
    director:setDisplayStats(true)
end

require "config"
require "cocos.init"
-- require "utils.util"
require "utils.init"

local breakInfoFun , xpCallFun
if USE_BREAKPOINT_DEBUG then
	--本地调试
	breakInfoFun , xpCallFun = require("LuaDebugjit")("localhost",7003)
	--手机端调试															--电脑IP
	-- breakInfoFun , xpCallFun = require("LuaDebugjit")("192.168.1.119",7004)
	cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakInfoFun, 0.3, false)
end
-- local breakInfoFunc, debugXpCall = require("LuaDebugjit")("localhost", 8008)
-- cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakInfoFunc, 0.5, false)

local function main()
	util.init()
	-- require("utils.util")
    require("app.MyApp"):create():run()

end

local postedLog = {}
function __G__TRACKBACK__(msg)
	local debuglog = debug.traceback()
	cclog("----------------------------------------")
	cclog("LUA ERROR: " .. tostring(msg) .. "\n")
	cclog(debuglog)
	cclog("----------------------------------------")

	if USE_BREAKPOINT_DEBUG then
		xpCallFun()
	end

	if not postedLog[msg] then
		postedLog[msg] = true
		debuglog = tostring(msg)..debuglog
		util.postLogToServer(debuglog)
	end
	if CC_ALERT_ERROR then
		Alert:debugWin(msg.."\r\n"..debuglog)
	end
	-- trace = function() end
	-- traceObj = function() end
	return msg
end


local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
