-- 图片加载失败时 是否弹出消息框
cc.FileUtils:getInstance():setPopupNotify(false)
-- 平台 0-window,1-linux,2-mac,3-android, 4-iphone,5-ipad
__Platform__ = cc.Application:getInstance():getTargetPlatform()
trace = print
cclog = print
print("__Platform__", __Platform__)

--把打印的log写入文件  
LOG_FILE_NAME = "D:\\xampp\\htdocs\\mGit\\mcoco\\assets\\srcGAME_LOG.txt"  
LOG_FILE_PATH = io.open(LOG_FILE_NAME,'w+')  
--重写print 让打印的东西能同时写入到文件里  
-- old_print = print  
-- print = function (...) 
--     if not ... then return end  
--     local time = os.date("[%H:%M:%S]", os.time())
--     old_print(...)  
--     --写入  
--     local args = {...}  
--     local s = time
--     for i , v in ipairs(args) do 
--         s = s .. "\t" .. tostring(v)  
--     end  
--     LOG_FILE_PATH:write(tostring(s).."\n")  
--     LOG_FILE_PATH:flush()  
-- end 

_game_require = require
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
require "utils.init"

local breakInfoFun , xpCallFun
if USE_BREAKPOINT_DEBUG then
	--本地调试
	breakInfoFun , xpCallFun = require("LuaDebugjit")("localhost",7003)
	--手机端调试															--电脑IP
	-- breakInfoFun , xpCallFun = require("LuaDebugjit")("192.168.1.119",7004)
	cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakInfoFun, 0.3, false)
end

--重启游戏
function reloadGame(isreload)
	local runingscene = cc.Director:getInstance():getRunningScene()
	if runingscene then
		runingscene:removeAllChildren()
	end   
	local scene = cc.Scene:create()
	if runingscene then
		cc.Director:getInstance():replaceScene(scene)
	else
		cc.Director:getInstance():runWithScene(scene)
	end

	-- BASE_NODE = cc.Node:create()
	-- scene:addChild(BASE_NODE)

	util.delayCall(scene, function ()
		-- require("modules.forestdance.yl")
		-- local layer = require("modules.forestdance.forestdance").new(scene)
		-- GameViewLayer
		local layer = require("modules.forestdance.GameLayer").new(scene)
		-- local layer = require("modules.forestdance.GameLayer").new(nil, scene)
	end, 0.1)
	-- BASE_NODE = cc.Node:create()
	-- scene:addChild(BASE_NODE)

	-- BASE_NODE:delayCall(function ()
	-- 	print("wocao")
	-- end, 1)
	-- require("app.MyApp"):create():run()
	-- local me = display.newSprite("img2/2.png")
 --    me:move(display.center)
 --    me:addTo(scene, -1)
 --    local size = me:getContentSize()
 --    me:setScaleX(1334/size.width)
 --    me:setScaleY(display.height/size.height)
end

local function main()
	-- util.init()
	collectgarbage("collect")
	collectgarbage("setpause", 100)
	collectgarbage("setstepmul", 5000)

    -- require("app.MyApp"):create():run()
    reloadGame()
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
