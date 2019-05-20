
function ifnil( param, default )
	if param == nil then
		return default
	else
		return param
	end
end

-- 在屏幕上打印往上飘一会消失 一般作为临时功能替代标记
function mlog( ... )
	-- 如果遇到bool值好像会出现问题
	local args = {...}
	for k,v in pairs(args) do
		if type(v) == "boolean" then
			args[k] = tostring(v)
		end
	end
	-- 打印出现在屏幕上的初始位置
	PrintPosDiff = ifnil(PrintPosDiff, 15)
	if PrintPosDiff > 1 then
		PrintPosDiff = PrintPosDiff - 1
	else
		PrintPosDiff = PrintPosDiff + 15
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

	local mNode = cc.Label:createWithTTF(ttfConfig, content, cc.TEXT_ALIGNMENT_CENTER, viewsize.width-20)
	mNode:setColor(cc.c3b(80, 19, 0));
	scene:addChild(mNode, 99);
	mNode:setPosition(cc.p(viewsize.width/2, PrintPosDiff*20));
	-- 往上飘的时间
	local uTime = 6.5;
	local uAction = cc.Spawn:create(
		cc.FadeOut:create(uTime), 
		cc.MoveBy:create(uTime, cc.p(0, 400))
	);
	local action = cc.Sequence:create(uAction, cc.RemoveSelf:create());
	mNode:runAction(action);
end

-- 基础node拓展方法
local Node = cc.Node
-- 通用型点击事件绑定
function Node:bindTouch(args)
	if args == nil then
		return
	end
	self:unbindTouch()

	local function onTouchBegan( touch, event )
		local target = event:getCurrentTarget()
		local touchPoint = touch:getLocation()
		local locationInNode = target:convertToNodeSpace(touchPoint)
		local s = target:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		if cc.rectContainsPoint(rect, locationInNode) then
			if args.onTouchBegan then
				return args.onTouchBegan(touch, event)
			end
			return true
		end
	end
	local function onTouchMove( touch, event )
		if args.onTouchMove then
			args.onTouchMove(touch, event)
		end
	end
	local function onTouchEnded( touch, event )
		if args.onTouchEnded then
			args.onTouchEnded(touch, event)
		end
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(onTouchMove, cc.Handler.EVENT_TOUCH_MOVED)
	listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
	self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)

	self._touchListener = listener
	return self
end
-- 接触 bindTouch 事件
function Node:unbindTouch()
	if self._touchListener then
        self:getEventDispatcher():removeEventListener(self._touchListener)
        self._touchListener = nil
    end
    return self;
end

function Node:bindTouchLocate()
	local args = {}
	args.onTouchBegan = function (touch, event)
		-- 为什么这里用 getPosition 只获取到宽？被谁改写过 正常不是返回个ccp么
		self.lBeganPos_ = cc.p(self:getPositionX(), self:getPositionY())
		self.lBeganPoint_ = touch:getLocation();
		return true
	end
	args.onTouchMove = function (touch, event)
		local point = cc.pAdd(self.lBeganPos_, cc.pSub(touch:getLocation(), self.lBeganPoint_))
		self:setPosition(point)
	end
	args.onTouchEnded = function (touch, event)
		local winSize = cc.Director:getInstance():getWinSize()
		local pw,ph = winSize.width, winSize.height
		if self:getParent() ~= nil then
			local size = self:getParent():getContentSize()
			pw = size.width
			ph = size.height
		end
		print("node Location:", self:getPositionX(), self:getPositionY(), "Percentage:", self:getPositionX()/pw, self:getPositionY()/ph)
	end
	self:bindTouch(args)
	return self
end
-- 快速绑定点击事件 
function Node:quickBt(callFunc)
	-- 设置点击cd时间
	self.InCdTime = false  
	local function runResponseCd(cdTime)
		local cdTime = cdTime or 0.3
		self.InCdTime = true
		local delay = cc.DelayTime:create(cdTime)
		local function cFun()
			self.InCdTime = false
		end
		local sequence = cc.Sequence:create(delay, cc.CallFunc:create(cFun))
		self:runAction(sequence)
	end

	local args = {}
	args.onTouchBegan = function (touch, event)
		self.BeganScale_ = self:getScale();
        self.BeganOpacity_ = self:getOpacity();

        self:setScale(self.BeganScale_*0.9);
        self:setOpacity(self.BeganOpacity_*0.9);
		return true
	end
	args.onTouchEnded = function (touch, event)
		self:setScale(self.BeganScale_);
        self:setOpacity(self.BeganOpacity_);
        -- util.playSound("Common_Panel_Dialog_Pop_Sound", false)
        -- 是否点击太快
        if self.InCdTime then
        	print("-------------响应屏蔽------------")
        	return
        end
        runResponseCd(0.5)

        local target = event:getCurrentTarget()
		local touchPoint = touch:getLocation()
		local locationInNode = target:convertToNodeSpace(touchPoint)
		local s = target:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		if cc.rectContainsPoint(rect, locationInNode) then
			if callFunc then
				callFunc()
			end
		end
	end
	self:bindTouch(args)
	return self
end
-- 替换图片或者texture
function Node:display(img)
	if iskindof(self,"cc.Sprite") then
		util.loadSprite(self, img)
	elseif iskindof(self,"ccui.ImageView") then
		util.loadImage(self, img)
	elseif iskindof(self,"ccui.Button") then
		util.loadButton(self, img)
	else
		trace("R:img unknown node")
	end
	return self
end

-- 快速设置在父亲结点的百分比位置, 如果没有父亲则使用设计分辨率
function Node:pp(pxOrCcp, py)
	local px = pxOrCcp;
    if px == nil then
        px = 0.5
        py = 0.5
    elseif py == nil then
        py = pxOrCcp.y
        px = pxOrCcp.x
    end
    local winSize = cc.Director:getInstance():getWinSize()
    local pw,ph = winSize.width, winSize.height
    print("pp winSize", pw, ph)
	if self:getParent() then
		local size = self:getParent():getContentSize()
		pw = size.width
		ph = size.height
	end
    self:setPosition(pw * px, ph * py)

    return self
end
-- 这里等于做一个delayAction 动作成立的前提条件是自身存在 如果被删了事件一起没了  如果要事件成为全局也就是node删除事件还在 参见 util.delayCall
function Node:delayCall(func, delayTime, bRepeat)
	-- if self._delayAction then
	local action = cc.Sequence:create(cc.DelayTime:create(delayTime),cc.CallFunc:create(func))
	if bRepeat then
		if type(bRepeat) == "boolean" then
			action = cc.RepeatForever:create(action)
		elseif type(bRepeat) == "number" and bRepeat > 0 then
			action = cc.Repeat:create(action, bRepeat)
		end
	end
	self:runAction(action)
end


