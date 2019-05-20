util = class("util")
----------------------------------------------
--工具方法
----------------------------------------------
local sharedScheduler = cc.Director:getInstance():getScheduler()

function util.exit()
	cc.Director:getInstance():endToLua()
end

function util.getKey(key,def)
	local value =  cc.UserDefault:getInstance():getStringForKey(key,def)
	if value == util.STR_TRUE then
		value = true
	elseif value == util.STR_FALSE then
		value = false
	end
	return value
end

function util.setKey( key,str )
	if type(str) == "boolean" then
		str = str and util.STR_TRUE or util.STR_FALSE
	end
	cc.UserDefault:getInstance():setStringForKey(key,str)
	cc.UserDefault:getInstance():flush()
end

function util.merge(dest,src)
	for k,v in pairs(src) do
		dest[k]=v
	end
end

function util.clone(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for key, value in pairs(object) do
			new_table[_copy(key)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	 end
	return _copy(object)
end

--移除所有定时,doNow 表示立即执行所有延迟函数(循环的除外)
function util.removeAllSchedulerFuns(node,doNow)
	if node  then
		if node._schedulehandle then
			if doNow then
				--todo
			end
			sharedScheduler:unscheduleScriptEntry(node._schedulehandle)
			node._scheduleFuns = nil
			node._schedulehandle = nil
		end
		if node._delayCallhandles then
			for _delayCallhandle,info in pairs(node._delayCallhandles) do
				if doNow and not info.bRepeat then
					local func = info.func
					if func then
						func()
					end
				end
				sharedScheduler:unscheduleScriptEntry(_delayCallhandle)
				node._delayCallhandles[_delayCallhandle] = nil
			end
		end
   end
end


function util.delayCall(node,func,delay,bRepeat)
	if tolua.isnull(node) then
		return
	end
	node._delayCallhandles = node._delayCallhandles or {}
	local _delayCallhandle
	_delayCallhandle = sharedScheduler:scheduleScriptFunc(function(dt)
		if node._delayCallhandles and node._delayCallhandles[_delayCallhandle] and not bRepeat then
			sharedScheduler:unscheduleScriptEntry(_delayCallhandle)
			node._delayCallhandles[_delayCallhandle] = nil
		end
		if not tolua.isnull(node) then
			func(dt)
		elseif node._delayCallhandles then
			util.removeAllSchedulerFuns(node)
		else
			sharedScheduler:unscheduleScriptEntry(_delayCallhandle)
		end
	end, delay or 0, false)

	node._delayCallhandles[_delayCallhandle] = {func=func,bRepeat=bRepeat}

	return _delayCallhandle
end

function util.removeDelayCall(handler)
	if handler then
		sharedScheduler:unscheduleScriptEntry(handler)
	end
end

function util.removeSchedulerFun(node,func)
	if node._scheduleFuns then
		for i,j in pairs(node._scheduleFuns) do
			if j == func then
				table.remove(node._scheduleFuns,i)
			end
		end
	end
end

--延迟处理函数,同一个node中,根据添加的顺序,执行func
function util.addSchedulerFuns(node,func,bRepeat,timeStart,timeEnd,dt)
	if tolua.isnull(node) then
		trace("error on addSchedulerFuns node is nil")
		return
	end
	if type(func) == "table" then
		for index,currFun in pairs(func) do
			util.addSchedulerFuns(node,currFun,bRepeat,timeStart,timeEnd,dt)
		end
		return
	elseif type(func) ~= "function" then
		error("addSchedulerFuns arg2 is not a function")
		return
	end
	node._scheduleFuns = node._scheduleFuns or {}
	table.insert(node._scheduleFuns,{dt = 0,bRepeat = bRepeat,func = func,timeStart = timeStart,endTime = timeEnd,lastTick = util.time()})
	local sharedScheduler = cc.Director:getInstance():getScheduler()
	node._schedulehandle = node._schedulehandle or sharedScheduler:scheduleScriptFunc(function()
		local info = (not tolua.isnull(node)) and node._scheduleFuns and table.remove(node._scheduleFuns,1)
		if info then     
			local func = info.func
			local endTime = info.endTime   
			local bRepeat = info.bRepeat
			local timeStart = info.timeStart
			local cd = info.dt
			local lastTick = info.lastTick
			local now = util.time()
			local tick = now - lastTick
			if (cd and cd>0) or (timeStart and timeStart>0) then
				info.dt = info.dt and (info.dt - tick)
				info.timeStart = info.timeStart and (info.timeStart - tick)
				table.insert(node._scheduleFuns,info)
				return
			end
			info.dt = dt
			if endTime then
				endTime = endTime - tick
				if endTime<0 then
					func(tick,true)
					return
				end
				info.endTime = endTime
			end
			func(tick)
			if bRepeat and node._scheduleFuns then
				info.lastTick = now
				table.insert(node._scheduleFuns,info)
			end
		elseif node._schedulehandle then
			sharedScheduler:unscheduleScriptEntry(node._schedulehandle)
			node._schedulehandle = nil
		end
	end,0,false)
	if node.registerScriptHandler then
		node:registerScriptHandler(function(state)
			if state == "exit" then
				if node._schedulehandle then
					sharedScheduler:unscheduleScriptEntry(node._schedulehandle)
					node._schedulehandle = nil
				end
			end
		end)
	end
end

function util.schedulerPairs(tab,fun,node)
	if node == nil then
		node = cc.Node:create()
		node:retain()
		node.autoRel = true
	end
	local num = table.nums(tab)
	for i,j in pairs(tab) do
		util.addSchedulerFuns(node,function()
			fun(i,j)
			num = num -1
			if num == 0 and node.autoRel then
				node:release()
			end
		end)
	end
end

local function isVisible(node)
	local parent = node
	while(true) do
		if not parent:isVisible() then
			return false
		end
		parent = parent:getParent()
		if tolua.isnull(parent) then
			break
		end
	end
	return true
end
--获取世界坐标的区域
function util.getWorldBoundingBox(node)
	local rect = node:getBoundingBox()
	while node:getParent() ~= self do
		rect.x = rect.x + node:getParent():getPositionX()
		rect.y = rect.y + node:getParent():getPositionY()
		node = node:getParent()
	end
	return rect
end

function util.init()
    math.randomseed(os.time())
    util.reg()
end

function util.setBackEnabled(state)
	if state then -- 添加返回
		if not util.keyBackListener then
			trace("添加返回监听")
			util.addKeyBack()
		end
	else -- 移除返回
		if util.keyBackListener then
			trace("移除返回监听")
			local eventDispatcher = scenes.winLayer:getEventDispatcher()
			eventDispatcher:removeEventListener(util.keyBackListener)
			util.keyBackListener = nil
		end 
	end
end

-- 返回键监听
function util.addKeyBack()
	util._eventBackFunx = util._eventBackFunx or {}
	util._eventKeyFunx = util._eventKeyFunx or {}
	local function onKeyReleased(keyCode, event)
		if keyCode == cc.KeyCode.KEY_BACK then
			for i,j in pairs(util._eventBackFunx) do
				if not tolua.isnull(j.node) then
					if not j.func() then
						return
					end
				end
			end
		else
			for i,j in pairs(util._eventKeyFunx) do
				if not tolua.isnull(j.node) then
					if not j.func(keyCode) then
						return
					end
				end
			end
		end
	end
	local listener = cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED )
	local eventDispatcher = scenes.winLayer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, scenes.winLayer)
	util.keyBackListener = listener
end

--添加返回事件
--超后面添加的越优先响应
function util.addEventBack(node,func)
	if not tolua.isnull(node) then
		if util._eventBackFunx then
			for i = table.nums(util._eventBackFunx),1 -1 do
				if util._eventBackFunx[i] and tolua.isnull(util._eventBackFunx[i].node) then
					table.remove(util._eventBackFunx,i)
				end
			end
			table.insert(util._eventBackFunx,1,{node = node,func = func})
		end
	end
end

function util.addKeyEvent(node,func)
	if not tolua.isnull(node) then
		if util._eventKeyFunx then
			for i = table.nums(util._eventKeyFunx),1 -1 do
				if util._eventKeyFunx[i] and tolua.isnull(util._eventKeyFunx[i].node) then
					table.remove(util._eventKeyFunx,i)
				end
			end
			table.insert(util._eventKeyFunx,1,{node = node,func = func})
		end
	end
end
--改变锚点,不移动位置
function util.changeAnchor(node,newAnchor)
	local oldAnchor = node:getAnchorPoint()
	if newAnchor == nil or (oldAnchor.y == newAnchor.y and oldAnchor.x == newAnchor.x) then
		return oldAnchor
	end

	local pos = cc.p(node:getPosition())
	local size = node:getContentSize()

	pos.x = pos.x + (newAnchor.x-oldAnchor.x)*size.width*node:getScaleX()
	pos.y = pos.y + (newAnchor.y-oldAnchor.y)*size.height*node:getScaleY()

	node:setPosition(pos.x,pos.y)
	if iskindof(node,"ccui.RichText") then
		node:setAnchorPoint(newAnchor)
	else
		node:setAnchorPoint(newAnchor.x,newAnchor.y)
	end

	return oldAnchor
end

function util.isPlistPath(path)
	local tem = path
	for str in pairs(plisPath) do
		tem = string.gsub(tem,str,"")
	end

	return not string.find(tem, "/")
end

local function addImgType(path)
	if not string.find(path, util.getImgType()) and not string.find(path,".jpg") then
		path = path..util.getImgType()
	end
	return path
end

function util.loadSprite(node, path)
	if not path or tolua.isnull(node) then
		return
	end
	path = addImgType(path)

	if not util.isPlistPath(path) then
		node:setTexture(path)
	else
		node:setSpriteFrame( path )
	end
end

function util.loadImage( node,path,resType )
	if not path or tolua.isnull(node) then
		return
	end
	path = addImgType(path)
	if not  tolua.isnull(node) and path then 
		if not util.isPlistPath(path) then
			node:loadTexture(path,0)
		else
			node:loadTexture(path,resType or 1)
		end
	end
end
-- 重设按钮图片
function util.loadButton( node,path ,resType, path1, path2)
	if not  tolua.isnull(node) and path then
		resType = resType or 1
		path = addImgType(path)
		if not path1 then
			path1 = path
		end
		if not path2 then
			path2 = path
		end
		if not util.isPlistPath(path) then
			node:loadTextureNormal(path, 0)
			node:loadTexturePressed(path1, 0)
			node:loadTextureDisabled(path2, 0)
		else
			node:loadTextureNormal(path, resType)
			node:loadTexturePressed(path1, resType)
			node:loadTextureDisabled(path2, resType)            
		end
	end
end

function util.listAddItem(node,item)
	if not  tolua.isnull(node) then 
		node:pushBackCustomItem(item)
	end
end

--每行多个Item
function util.listAddLineItem(node,item,numPerLine)
	if not  tolua.isnull(node) then 
		local lineItem = node._lastLineItem
		if  not lineItem or (lineItem._itemNum >= numPerLine) then
			lineItem = ccui.Layout:create()
			lineItem:setLayoutType(ccui.LayoutType.HORIZONTAL)
			lineItem:setContentSize(cc.size(node:getContentSize().width,item:getContentSize().height))
			node:pushBackCustomItem(lineItem)
			lineItem._itemNum = 0
			node._lastLineItem = lineItem
		end

		lineItem._itemNum = lineItem._itemNum + 1
		lineItem:addChild(item)
	end
end

--获取文字长度
function util.getStringWidth(text,fontName,fontSize)
	local laber = ccui.Text:create()
	if type(fontSize) == "number" then
		laber:setFontSize(fontSize) 
	end
	laber:setFontName(fontName) 
	laber:setString(text)
	return laber:getContentSize().width
end
--字符串过长截取
function util.getFixedString(text,fontName,fontSize,width)
	local laber = ccui.Text:create()
	laber:setFontName(fontName) 
	laber:setString(text)
	util.setStringWidth(laber,width)

	return laber:getString()
end

--长于width的字符串省略成...(stringToFormatEx 这个函数实现的laber 不可为换行的)
function util.setStringWidth(laber,width)
	local laberTem = ccui.Text:create()
	laberTem:setFontSize(laber:getFontSize()) 
	laberTem:setFontName(laber:getFontName()) 
	laberTem:setString(laber:getString())
	stringToFormatEx(laberTem,width)
	return laber:setString(laberTem:getString())
end

--自适应文字长度
function util.fixLaberWidth(laber,readOnly)
	local fontSize = laber:getFontSize()
	local fontName = laber:getFontName()
	local text =  laber:getString()
	local textWidth = util.getStringWidth(text,fontName,fontSize)
	if not readOnly and (textWidth ~= laber:getContentSize().width) then
		laber:setContentSize(cc.size(textWidth,laber:getContentSize().height))
	end
	return textWidth
end



function util.setGray(node)
	local vertDefaultSource = "\n"..
	"attribute vec4 a_position; \n" ..
	"attribute vec2 a_texCoord; \n" ..
	"attribute vec4 a_color; \n"..                                                    
	"#ifdef GL_ES  \n"..
	"varying lowp vec4 v_fragmentColor;\n"..
	"varying mediump vec2 v_texCoord;\n"..
	"#else                      \n" ..
	"varying vec4 v_fragmentColor; \n" ..
	"varying vec2 v_texCoord;  \n"..
	"#endif    \n"..
	"void main() \n"..
	"{\n" ..
	"gl_Position = CC_PMatrix * a_position; \n"..
	"v_fragmentColor = a_color;\n"..
	"v_texCoord = a_texCoord;\n"..
	"}"
	 
	local pszFragSource = "#ifdef GL_ES \n" ..
	"precision mediump float; \n" ..
	"#endif \n" ..
	"varying vec4 v_fragmentColor; \n" ..
	"varying vec2 v_texCoord; \n" ..
	"void main(void) \n" ..
	"{ \n" ..
	"vec4 c = texture2D(CC_Texture0, v_texCoord); \n" ..
	"gl_FragColor.xyz = vec3(0.4*c.r + 0.4*c.g +0.4*c.b); \n"..
	"gl_FragColor.w = c.w; \n"..
	"}"

	if tolua.type(node) == "ccui.ImageView" then
		local image = node:getVirtualRenderer()
		node = image:getSprite()
	end

	local pProgram = cc.GLProgram:createWithByteArrays(vertDefaultSource,pszFragSource)
	 
	pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
	pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR,cc.VERTEX_ATTRIB_COLOR)
	pProgram:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_FLAG_TEX_COORDS)
	pProgram:link()
	pProgram:updateUniforms()
	node:setGLProgram(pProgram)
end

function util.setnoGray(node)
	if tolua.type(node) == "ccui.ImageView" then
		local image = node:getVirtualRenderer()
		node = image:getSprite()
	end    
	node:setGLProgramState(cc.GLProgramState:getOrCreateWithGLProgram(cc.GLProgramCache:getInstance():getGLProgram("ShaderPositionTextureColor_noMVP")))
end

function util.encodeURL(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02x", string.byte(c))
	end))
end

--加载网络图片,Url图片地址,bForceRefer删除缓存强制刷新,callback回调,参数:成功与否,本地图片存放地址

local loadingImg = {}

function util.loadWebImg(Url,bForceRerfer,callback)
	if loadingImg[Url] then
		table.insert(loadingImg[Url],callback)
		return
	end
	loadingImg[Url] = {callback}
	local function doCallbacks(...)
		if loadingImg[Url] then
			for i,j in pairs(loadingImg[Url]) do
				j(...)
			end
		end
		loadingImg[Url] = nil
	end

	local File = require("util.File")
	local path = File.wirtePath
	path = path.."webImg/"
	File.mkdir(path)
	path = path..util.encodeURL(Url)--..".png"
	local imgType = string.sub(path,-4)
	if imgType~=".png" and imgType~=".jpg" then
		if string.find(path,".jpg") then
			path = path..".jpg"
		else
			path = path..".png"
		end
	end
	if not File.exists(path) or bForceRerfer then
		--GET手机端无法下载Facebook头像,原因未知
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
		xhr:open("GET", Url)
		local function onReadyStateChange()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				File.save(path,xhr.response,"wb")
				doCallbacks(true,path)
			else
				trace("util.loadWebImg xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
				doCallbacks(false)
			end
		end
		xhr:registerScriptHandler(onReadyStateChange)
		xhr:send()

		--[[改为用Loader
		local function downCallback(result)
			if result.state == 3 then -- 下载完成
				
			end
		end
		Loader:shared():setRemotePath(Url)
		Loader:shared():load("", handler(self, downCallback))]]
	else
		doCallbacks(true,path)
	end
end


function util.setImg(node,img)
	if tolua.isnull(node) or not img then
		trace("R:setImg no find image or node")
	end
	if iskindof(node,"cc.Sprite") then
		util.loadSprite(node,img)
	elseif iskindof(node,"ccui.ImageView") then
		util.loadImage(node,img)
	elseif iskindof(node,"ccui.Button") then
		util.loadButton( node,img)
	else
		trace("R:img unknown node")
	end
end

function util.setWebImg(node,url)
	if tolua.isnull(node) or not url or url == "" then
		return
	end
	util.loadWebImg(url,false,function(suc,path) if suc then util.setImg(node,path) end end)
end

function util.reg()
	if util.isReg then -- 已注册过 就不用再重复注册
		return
	end
	util.isReg = true
	trace("reg LocalMsg")
	util.listener1 = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND",util.onEnerBackground )
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(util.listener1,1);  
	util.listener2 = cc.EventListenerCustom:create("APP_EXIT_BACKGROUND",util.onEnterForground)
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(util.listener2,1);     
end

function util.removeReg()
	trace("移除后台监听")
	cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners("APP_ENTER_BACKGROUND")
	cc.Director:getInstance():getEventDispatcher():removeCustomEventListeners("APP_EXIT_BACKGROUND")
end

-- 进入游戏
function util.onEnerBackground()
	if util._isInBackGround then
		trace("回到游戏")
		util._isInBackGround = false
		-- local isout,timeDiff = util.isTimeOut()
		-- if isout then
		-- 	trace("切入后台时间过久,重载游戏")
		-- 	util.setTimeout(function() util.backToLogin(sdkManager:is_IOS() or __Platform__ == 3) end,0.2)
		-- 	return
		-- end
		-- --if __Platform__==3 or __Platform__==4 or __Platform__==5 then
		-- 	--util.setTimeout(function() 
		-- 	-- util.setTimeout(function() GameEvent:notifyView(GameEvent.gameBackFromGround,timeDiff)  end,0)
		-- 	GameEvent:notifyView(GameEvent.gameBackFromGround,timeDiff) 
		-- 	--end,0.01)
			
		-- 	--util.setTimeout(function() cc.SimpleAudioEngine:getInstance():resumeMusic() end,1)
		-- --end
	end
end

-- 退出游戏
function util.onEnterForground()
	trace("切入后台")
	util.enterForgroundTime = os.time()
	--if __Platform__==3 or __Platform__==4 or __Platform__==5 then
		--collectgarbage("collect")
		-- GameEvent:notifyView(GameEvent.gametoBack)
	--end
	util._isInBackGround = true
end
function util.isInBackGround()
	return util._isInBackGround
end

-- 找到两个不同节点的相对相差位置 
function util:moveToOtherWordPoint(mNode, toNode)
    -- 我方-相对父节点世界坐标位置
    -- 目标-相对父节点世界坐标位置
    local oPos = cc.p(toNode:getPositionX(), toNode:getPositionY())
    oPos = toNode:getParent():convertToWorldSpace(oPos)
    -- ### 两者相差
    local sPos = mNode:getParent():convertToNodeSpace(oPos)
    return sPos
end


function util:fixFullScreen(mNode)
    -- 我方-相对父节点世界坐标位置
    -- 目标-相对父节点世界坐标位置
    -- local oPos = cc.p(toNode:getPositionX(), toNode:getPositionY())
    -- oPos = toNode:getParent():convertToWorldSpace(oPos)
    -- -- ### 两者相差
    -- local sPos = mNode:getParent():convertToNodeSpace(oPos)
    -- return sPos
end











