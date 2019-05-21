
function ifnil( param, default )
	if param == nil then
		return default
	else
		return param
	end
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
-- 快速绑定点击事件  快速绑定点击函数 touchSilence-是否静默点击 Shield-是否有点击cdTime
function Node:quickBt(callFunc, touchSilence, Shield)
	self.lastClickTime = 0; -- 上次点击时间
	self.clickCdTime = 0.3  -- 毫秒
    self.canTouch = true;

    local args = {}
	args.onTouchBegan = function (touch, event)
		if self.canTouch == false then
			return false
		end
		self.BeganScale_ = self:getScale();
        self.BeganOpacity_ = self:getOpacity();

        if not touchSilence then
        	self:setScale(self.BeganScale_*0.9);
        	self:setOpacity(self.BeganOpacity_*0.9);
        end
       
		return true
	end
	args.onTouchEnded = function (touch, event)
		-- if self.canTouch == false then
		-- 	return false
		-- end
		if not touchSilence then
        	self:setScale(self.BeganScale_);
        	self:setOpacity(self.BeganOpacity_);
        	-- util.mlog("soundClick")
        	util.SoundClick()
        end
        if not Shield then
        	local now = util.getNow()
        	if now - self.lastClickTime < self.clickCdTime then
        		print("---屏蔽过快点击---")
        		return
        	end
        	self.lastClickTime = now;
        end

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
function Node:delayCall(callFunc, delayTime, bRepeat)
	local action = cc.Sequence:create(cc.DelayTime:create(delayTime),cc.CallFunc:create(callFunc))
	if bRepeat then
		if type(bRepeat) == "boolean" then
			action = cc.RepeatForever:create(action)
		elseif type(bRepeat) == "number" and bRepeat > 0 then
			action = cc.Repeat:create(action, bRepeat)
		end
	end
	self:runAction(action)
end

-- ### 上面是对所有的node的拓展的 下面几个是对button属性的进行拓展的
local Widget = ccui.Widget
function Widget:onClick(callFunc, touchSilence, Shield)
	self.lastClickTime = 0; -- 上次点击时间
	self.clickCdTime = 0.3  -- 毫秒

    self:setSwallowTouches(true)

    local oldScale = self:getScale()
    local clickScale = oldScale*0.9
    local oldOpacity = self:getOpacity()
    local clickOpacity = oldOpacity*0.9

    self:onTouch(function(event)
        -- local pSender = event.target
        if "began" == event.name then
            if not touchSilence then
	            self:setScale(clickScale)
	            self:setOpacity(clickOpacity)
	        end
        elseif "moved" == event.name then
        	-- 没做移动处理
        elseif "ended" == event.name then
        	if not touchSilence then
	            self:setScale(oldScale)
	            self:setOpacity(oldOpacity)
	            util.SoundClick()
	        end
	        if not Shield then
		        local now = util.getNow()
	            if now - self.lastClickTime < self.clickCdTime then
	                print("---屏蔽过快点击---")
	                return
	            end
	            self.lastClickTime = now
	        end
            if callFunc then
				callFunc()
			end
        else
        	print("走到这里的一般是取消吧")
            if not touchSilence then
	            self:setScale(oldScale)
	            self:setOpacity(oldOpacity)
	        end
        end

    end, false, swallowTouches)
    return self
end
