-- create by Changwei on 2019/05/23
util = class("util")
----------------------------------------------
--工具方法
----------------------------------------------
local sharedScheduler = cc.Director:getInstance():getScheduler()
util.PrintPosDiff = 15;
-- 在屏幕上向上飘一下的打印
function util.mlog( ... )
	-- 如果遇到bool值好像会出现问题
	local args = {...}
	for k,v in pairs(args) do
		if type(v) == "boolean" then
			args[k] = tostring(v)
		end
	end
	-- 打印出现在屏幕上的初始位置
	util.PrintPosDiff = ifnil(util.PrintPosDiff, 15)
	if util.PrintPosDiff > 1 then
		util.PrintPosDiff = util.PrintPosDiff - 1
	else
		util.PrintPosDiff = util.PrintPosDiff + 15
	end
	-- 打印内容
	local content = table.concat(args, " ; ");
	print(content)
	local director = cc.Director:getInstance();
	local scene = director:getRunningScene();
	local viewsize = director:getWinSize();
	-- 生成打印内容ttf放在初始位置
	local ttfConfig = {}
    ttfConfig.fontFilePath = "img2/font/MSYH.TTF"
    ttfConfig.fontSize = 30

	-- local mNode = cc.Label:createWithTTF(ttfConfig, content, cc.TEXT_ALIGNMENT_CENTER, viewsize.width-20)
	local mNode = cc.Label:createWithSystemFont(content, "Arial", 34)
	mNode:setColor(cc.c3b(80, 19, 0));
	scene:addChild(mNode, 99);
	mNode:setPosition(cc.p(viewsize.width/2, util.PrintPosDiff*20));
	-- 往上飘的时间
	local uTime = 6.5;
	local uAction = cc.Spawn:create(
		cc.FadeOut:create(uTime), 
		cc.MoveBy:create(uTime, cc.p(0, 400))
	);
	local action = cc.Sequence:create(uAction, cc.RemoveSelf:create());
	mNode:runAction(action);
end

function util.exit()
	cc.Director:getInstance():endToLua()
end
-- 播放音效 传入路径
function util.playSound(path, isLoop)
	AudioEngine.playEffect(path, isLoop)
end
function util.playMusic(path, isLoop)
	AudioEngine.playMusic(path, isLoop)
end
-- 震动
function util.playShock(time)
	cc.Device:vibrate(time)
end
-- 普通的点击音效
function util.SoundClick()
	AudioEngine.playEffect("audio/common/Common_Panel_Dialog_Pop_Sound.mp3")
end
-- 返回当前时间 秒
function util.getNow () 
	return os.time()
end

function util.getKey(tab, key)
	-- 字典里面找key
	if tab and tab[key] then
		return tab[key]
	else
		print("错误 表没有找到key", tab, key);
		return
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
-- 使用举例: util.delayCall(self, function() PlayerData:showRedMsg(str2,false) end, 1)
function util.delayCall(node, func, delay, bRepeat)
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

function util.removeSchedulerFun(node, func)
	if node._scheduleFuns then
		for i,j in pairs(node._scheduleFuns) do
			if j == func then
				table.remove(node._scheduleFuns,i)
			end
		end
	end
end
-- 使用举例: 
-- util.addSchedulerFuns(tip, function(dt, isEnd)
--     timePass = timePass + dt
--     if isEnd then
--         hide()
--     else
--         tip.lb_show_laba:setPositionX(startPosX - width * timePass/time)
--     end
-- end, true, 0, time)
function util.addSchedulerFuns(node, func, bRepeat, timeStart, timeEnd, dt)
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
			if (cd and cd > 0) or (timeStart and timeStart > 0) then
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
	end, 0, false)
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

function util.schedulerPairs(tab, fun, node)
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

function util.isVisible(node)
	local parent = node
	while (true) do
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
-- 获取世界坐标的区域
function util.getWorldBoundingBox(node)
	local rect = node:getBoundingBox()
	while node:getParent() ~= self do
		rect.x = rect.x + node:getParent():getPositionX()
		rect.y = rect.y + node:getParent():getPositionY()
		node = node:getParent()
	end
	return rect
end
-- 改变锚点,不移动位置
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

-- 尝试从父辈移除  是否销毁
function util.tryRemove(node)
	if not tolua.isnull(node) and node:getParent() then 
		if debugUI then 
			trace("removed :"..node:getName().."  count:"..node:getParent():getChildrenCount())
		end
		node:removeFromParent()
	end
end

-- 资源图片格式,安卓平台获取的图片由png 变成pkm ios png ->pvr
function util.getImgType()
	return ".png"
end

local function addImgType(path)
	if not string.find(path, util.getImgType()) and not string.find(path, ".jpg") then
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

function util.loadImage(node, path, resType)
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
function util.loadButton(node, path, resType, path1, path2)
	if not tolua.isnull(node) and path then
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

--加载网络图片,Url图片地址,bForceRefer删除缓存强制刷新,callback回调,参数:成功与否,本地图片存放地址
local loadingImg = {}
function util.loadWebImg(Url, bForceRerfer, callback)
	if loadingImg[Url] then
		table.insert(loadingImg[Url], callback)
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
	if imgType ~= ".png" and imgType ~= ".jpg" then
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

function util.setWebImg(node,url)
	if tolua.isnull(node) or not url or url == "" then
		return
	end
	util.loadWebImg(url,false,function(suc,path) if suc then util.setImg(node,path) end end)
end
-- 更换图片
function util.display(node, img)
	if tolua.isnull(node) or not img then
		trace("R:setImg no find image or node")
	end
	if iskindof(node,"cc.Sprite") then
		util.loadSprite(node, img)
	elseif iskindof(node,"ccui.ImageView") then
		util.loadImage(node, img)
	elseif iskindof(node,"ccui.Button") then
		util.loadButton(node, img)
	else
		trace("R:img unknown node")
	end
end

function util.setGray3d(node)
	local vertDefaultSource = "\n"..
	"attribute vec4 a_position;\n" ..
	"attribute vec2 a_texCoord;\n" ..
	"#ifdef GL_ES\n" ..
	"varying mediump vec2 v_texCoord;\n" ..
	"#else\n" ..
	"varying vec2 v_texCoord;\n" ..
	"#endif\n" ..
	"void main()\n" ..
	"{\n" ..
	"gl_Position = CC_MVPMatrix * a_position;\n" ..
	"v_texCoord = a_texCoord;\n" ..
	"}\n"
	 
	local pszFragSource = "#ifdef GL_ES \n" ..
	"varying mediump vec2 v_texCoord;\n" ..
	"#else\n" ..
	"varying vec2 v_texCoord;\n" ..
	"#endif\n" ..
	"void main()\n" ..
	"{\n" ..
	"vec4 color = texture2D(CC_Texture0, v_texCoord);\n" ..
	"float h = 0.3 * color.x + 0.6 * color.y + 0.1 * color.z;//变灰\n" ..
	"gl_FragColor = vec4(h, h, h, 1.0);\n" ..
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

-- 找到两个不同节点的相对相差位置 
function util.moveToOtherWordPoint(mNode, toNode)
    -- 我方-相对父节点世界坐标位置
    -- 目标-相对父节点世界坐标位置
    local oPos = cc.p(toNode:getPositionX(), toNode:getPositionY())
    oPos = toNode:getParent():convertToWorldSpace(oPos)
    -- ### 两者相差
    local sPos = mNode:getParent():convertToNodeSpace(oPos)
    return sPos
end
-- 获得两点之间顺时针旋转的角度
function util.TwoPointAngle(pointFrom, pointTo)
	local dx = math.abs(pointFrom.x - pointTo.x)
	local dy = math.abs(pointFrom.y - pointTo.y)
	local z = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
	local cos = dy / z
	local radina = math.acos(cos) -- 用反三角函数求弧度
	local angle = math.floor(180 / (math.pi / radina)) -- 将弧度转换成角度
	if pointTo.x > pointFrom.x and pointTo.y > pointFrom.y then -- 鼠标在第四象限
        angle = 180 - angle
    elseif pointTo.x == pointFrom.x and pointTo.y > pointFrom.y then -- 鼠标在y轴负方向上
        angle = 180;
    elseif pointTo.x > pointFrom.x and pointTo.y == pointFrom.y then -- 鼠标在x轴正方向上
        angle = 90;
    elseif pointTo.x < pointFrom.x and pointTo.y > pointFrom.y then -- 鼠标在第三象限
        angle = 180 + angle;
    elseif pointTo.x < pointFrom.x and pointTo.y == pointFrom.y then -- 鼠标在x轴负方向
        angle = 270;
    elseif pointTo.x < pointFrom.x and pointTo.y < pointFrom.y then -- 鼠标在第二象限
        angle = 360 - angle;
    end
    angle = 180 - angle;
    return angle;
end
-- textLabel-要处理的label maxNum-最多显示几位中文字符 超过的话显示...
function util.setTextMaxCharCode(str, maxNum)
	maxNum = ifnil(maxNum, 4)
	if #str <= maxNum then
		return str
	else
		-- 区别中英文字符 默认为 9个英文字符长度==5个中文字符等长
        local num = 0
        for i=1,#str do
        	local charCode = string.byte(str, i)
        	if (charCode > 32 and charCode < 127) then
        		num = num + 5/9
        	else
        		num = num + 1
        	end
        	if num > maxNum then
        		str = string.sub(str, 1, i)
        		str = str.."..."
                return str
        	end
        end
        return str
	end
end

function util.getStrLength(str)
	local num = 0
	for i=1,#str do
		local charCode = string.byte(str, i)
		if (charCode > 32 and charCode < 127) then
    		num = num + 5/9
    	else
    		num = num + 1
    	end
	end
	return num
end

function util.rand(st, ed)
	if ed == nil then
		ed = st;
		st = 0;
	end
	return math.random() * (ed - st) + st;
end

function util.randInt(st, ed)
	return math.round(self.rand(st, ed))
end
-- 两点间的距离
-- function util.pointDistance(a, b)
-- 	local x = a.x-b.x, 
-- 	local y = a.y-b.y;
--     return math.sqrt(x * x + y * y)
-- end
-- 洗牌
function util.shuffle(array)
	for i=1,#array do
		local randomIndex = math.floor(math.random()*(i+1)); 
        local itemAtIndex = array[randomIndex]; 
        array[randomIndex] = array[i]; 
        array[i] = itemAtIndex;
	end
end