
-- local initMsg = _game_require("logic.initMsg")
local initMsg = require("modules.forestdance.initMsg")
local GameViewLayer = class("GameViewLayer", function (scene)
    return cc.Layer:create()
end)

GameViewLayer.Tag = {
    clock_num = 1,
    btn_userlist = 2,
    btn_bankerlist = 3,
    btn_bank = 4,
    btn_sound = 5,
    btn_backRoom = 6,
    btn_help = 7,
    btn_close = 8,
    Tag_GunNum = 200
}
-- 动作Tag
GameViewLayer.AnimalTag =
{
    Tag_Animal = 1
}

function GameViewLayer:ctor(scene)
	self._gameLayer = scene
	-- scene:addChild(self)
	self._colorList = {}
	self.bContinueRecord = true

	self:gameDataInit()
	self:initConstValue()
	self:loadRes()

	-- local me = display.newSprite("2.png")
 --    me:move(display.center)
 --    me:addTo(scene, -1)
 	self:mTest()
end

function GameViewLayer:gameDataInit()
    AudioEngine.stopMusic()
end

function GameViewLayer:initConstValue()
    -- 动物正常动画时间
    local value = { 3.0, 1.65, 1.415, 2.5 }
    self._animalTimeFree = util.readOnly(value)
    -- 动物胜利动画时间
    value = { 5.5, 4, 4, 3 }
    self._animalTimeWin = util.readOnly(value)
    -- 下注筹码
    value = { 10, 50, 100, 100000, 1000000, 10000000 }
    self._jettonArray = util.readOnly(value)
end

function GameViewLayer:loadRes()
	-- ## 等待处理
    -- self._gameLayer:dismissPopWait()
    -- 加载层
    -- self:loading()

    -- 资源是否加载完成
    self._resLoadFinish = false
    -- 2d资源
    self._2dResCount = 0
    self._2dResTotal = 4
    cc.Director:getInstance():getTextureCache():addImageAsync("game_res/game.png", handler(self, self.load2DModelCallBack))
    cc.Director:getInstance():getTextureCache():addImageAsync("game_res/anim_sd.png", handler(self, self.load2DModelCallBack))
    cc.Director:getInstance():getTextureCache():addImageAsync("game_res/anim_sx.png", handler(self, self.load2DModelCallBack))
    cc.Director:getInstance():getTextureCache():addImageAsync("game_res/anim_sy.png", handler(self, self.load2DModelCallBack))

    -- 3D资源
    local modelFiles = { }
    -- table.insert(modelFiles, "3d_res/model_0/wujian.c3b")
    -- table.insert(modelFiles, "3d_res/model_1/wujian02.c3b")
    table.insert(modelFiles, "3d_res/model_2/wujian04.c3b")
    -- table.insert(modelFiles, "3d_res/model_3/wujian03.c3b")
    table.insert(modelFiles, "3d_res/model_4/wujian07.c3b")
    -- table.insert(modelFiles, "3d_res/model_5/wujian07.c3b")
    table.insert(modelFiles, "3d_res/model_6/wujian08.c3b")
    table.insert(modelFiles, "3d_res/model_7/wujian11.c3b")
    table.insert(modelFiles, "3d_res/model_8/wujian10.c3b")
    -- table.insert(modelFiles, "3d_res/model_bottom/dibu.c3b")
    -- table.insert(modelFiles, "3d_res/model_bottom1/dibu2.c3b")
    table.insert(modelFiles, "3d_res/model_monkey/monkey.c3b")
    table.insert(modelFiles, "3d_res/model_lion/lion.c3b")
    table.insert(modelFiles, "3d_res/model_panda/panda.c3b")
    table.insert(modelFiles, "3d_res/model_rabbit/rabbit.c3b")
    table.insert(modelFiles, "3d_res/model_seat/di.c3b")

    self._3dResCount = #modelFiles
    self._3dIndex = 0

    for i, v in ipairs(modelFiles) do
        local file = v
        cc.Sprite3D:createAsync(file, handler(self, self.load3DModelCallBack))
    end
end
function GameViewLayer:load2DModelCallBack(texture)
	self._2dResCount = self._2dResCount + 1
    if self._3dIndex == self._3dResCount and self._2dResCount == self._2dResTotal and self._resLoadFinish == false then
    	self:loadResSuccess();
    end
end

function GameViewLayer:load3DModelCallBack(...)
	self._3dIndex = self._3dIndex + 1
    if self._3dIndex == self._3dResCount and self._2dResCount == self._2dResTotal and self._resLoadFinish == false then
    	self:loadResSuccess();
    end
end
-- 资源加载完成的处理
function GameViewLayer:loadResSuccess()
	print("loadResSuccess资源加载完成")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/game.plist")
    cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/anim_sd.plist")
    cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/anim_sx.plist")
    cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/anim_sy.plist")

    initMsg.readAnimation("cj", "CJAnim", 15, 0.07)
    initMsg.readAnimation("sd", "SDAnim", 15, 0.07)
    initMsg.readAnimation("sx", "SXAnim", 15, 0.07)
    initMsg.readAnimation("sy", "SYAnim", 15, 0.07)
    -- 3d背景
    self:init3DModel()
    -- 3d动物资源
    self:initAnimal()

    self:initCsbRes()

    self._resLoadFinish = true
    self._bCaijinStatus = true
    -- 场景初始化
    self:enterInit()
end

function GameViewLayer:init3DModel()
    self.m_3dLayer = cc.Layer:create()
    self.m_3dLayer:setGlobalZOrder(1)
    self:addChild(self.m_3dLayer)

    self._camera = cc.Camera:createPerspective(60, display.width/display.height, 1, 1000)
    self._camera:setPosition3D(initMsg.cmd.Camera_Normal_Vec3)
    self._camera:lookAt(cc.vec3(0, 0, 0))
    self.m_3dLayer:addChild(self._camera)

    -- 游戏默认背景
    sprite = cc.Sprite3D:create("3d_res/model_4/changjing.c3b")
    sprite:setScale(0.04)
    sprite:setPosition3D(cc.vec3(0, -20, -13))
    sprite:setRotation3D(cc.vec3(90, 0, 180))
    self.m_3dLayer:addChild(sprite)
    -- 墙体
    sprite = cc.Sprite3D:create("3d_res/model_4/qiangti_ani.c3b")
    sprite:setScale(0.04)
    sprite:setPosition3D(cc.vec3(0, -20, -13))
    sprite:setRotation3D(cc.vec3(90, 0, 180))
    sprite:setVisible(false)
    self.m_3dLayer:addChild(sprite)
    sprite:setTexture("3d_res/model_4/qiangti_ani.png")
    sprite:setColor(cc.c3b(235,218,102))
    self.m_winColor = sprite
    -- 另一个颜色的墙体
    sprite = cc.Sprite3D:create("3d_res/model_4/qiangti_ani.c3b")
    sprite:setScale(0.04)
    sprite:setPosition3D(cc.vec3(0,-20,-13))
    sprite:setRotation3D(cc.vec3(90, 0, 180))
    self.m_3dLayer:addChild(sprite)
    sprite:setTexture("3d_res/model_4/qiangti_lanse.png")
    -- 墙上的条纹
    sprite = cc.Sprite3D:create("3d_res/model_4/tiaowen.c3b")
    sprite:setScale(0.04)
    sprite:setPosition3D(cc.vec3(0,-20,-13))
    sprite:setRotation3D(cc.vec3(90, 0, 180))
    self.m_3dLayer:addChild(sprite)
    sprite:setTexture("3d_res/model_4/tiaowen.png")
    sprite:setColor(cc.c3b(150,160,25))
    self.tiaowen = sprite
end

function GameViewLayer:getAnimRes(animIndex)
    local res = "3d_res/model_lion/lion.c3b"

    if animIndex == 1 then
        res = "3d_res/model_panda/panda.c3b"
    elseif animIndex == 2 then
        res = "3d_res/model_monkey/monkey.c3b"
    elseif animIndex == 3 then
        res = "3d_res/model_rabbit/rabbit.c3b"
    end

    return res
end

function GameViewLayer:getAnimIMG(animIndex)
    local res = "3d_res/model_lion/tex.jpg"

    if animIndex == 1 then
        res = "3d_res/model_panda/tex.jpg"
    elseif animIndex == 2 then
        res = "3d_res/model_monkey/tex.jpg"
    elseif animIndex == 3 then
        res = "3d_res/model_rabbit/tex.jpg"
    end

    return res
end

function GameViewLayer:initAnimal()
    self._animLayer = cc.Sprite3D:create()
    self._animLayer:setPosition3D(cc.vec3(0, 0, 0))
    self.m_3dLayer:addChild(self._animLayer)
    local file1 = "3d_res/model_8/wujian10.c3b"
    local file2 = "3d_res/model_seat/di.c3b"

    self._animals = {}
    -- @ws 座位
    self._SeatAnimals = {}

    self.node = {}

    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

    for i = 1, 24 do
    	-- @ws 三色地板
        local angle = 15 *(i - 1)
        local sprite = cc.Sprite3D:create(file1)
        sprite:setScale(0.04)

		-- 角度转弧度math.rad
        sprite:setPosition3D(cc.vec3(-2 * math.sin(math.rad(angle)), -26, 2 * math.cos(math.rad(angle))))
        sprite:setRotation3D(cc.vec3(-90, 210 - angle ,0))
        sprite:setGlobalZOrder(2)
        self.m_3dLayer:addChild(sprite)
        table.insert(self._colorList, sprite)

        -- @ws 底座修改
        local model = cc.Sprite3D:create()
        model:setPosition3D(cc.vec3(0, 0, 0))
        self._animLayer:addChild(model)

        local dizuo = cc.Sprite3D:create(file2)
        dizuo:setScale(0.05)
        dizuo:setPosition3D(cc.vec3(-6 * math.sin(math.rad(angle)) , -31, 6 * math.cos(math.rad(angle)) ))
        dizuo:setRotation3D(cc.vec3(-90, 165 - angle, 0))
        dizuo:setGlobalZOrder(2)
        dizuo:setTexture("3d_res/model_seat/dizuo.png")
        model:addChild(dizuo)
        table.insert(self._SeatAnimals, dizuo)
        
        -- 胜利的圆环
        local icon_win = cc.Sprite3D:create("3d_res/model_5/yuanhuan.c3b")
        icon_win:setScale(0.05)
        icon_win:setPosition3D(cc.vec3(19 * math.sin(math.rad(angle)) , -36, -19 * math.cos(math.rad(angle)) ))
        icon_win:setRotation3D(cc.vec3(-90, 345 - angle, 0))
        icon_win:setVisible(false)
        icon_win:setGlobalZOrder(2)
        icon_win:setTexture("3d_res/model_5/lv.png")
        model:addChild(icon_win)


        local animIndex = math.mod(i - 1, 4)
        local modelFile = self:getAnimRes(animIndex)
        -- @ws 加上纹理
        local texture = self:getAnimIMG(animIndex)
        -- 创建动物
        local animal = cc.Sprite3D:create(modelFile)
        if animIndex == 2 then
            animal:setScale(0.05)
        else
            animal:setScale(0.05)
        end
        animal:setTexture(texture)
        animal:setPosition3D(cc.vec3(19 * math.sin(math.rad(angle)), 0, -19 * math.cos(math.rad(angle))))
        animal:setRotation3D(cc.vec3(0, 360 - angle, 0))
        animal:setGlobalZOrder(2)
        animal:setTag(i)
        model:addChild(animal)

        table.insert(self._animals, animal)
        table.insert(self.node, model)
       
        animal:runAction(cc.Sequence:create(delay, cc.CallFunc:create( function()
            local fTime = math.random(0, 1) * 5
            local animtion = cc.Animation3D:create(modelFile)
            local delay = cc.DelayTime:create(fTime)
            local action = cc.Animate3D:create(animtion, 0, self._animalTimeFree[animIndex + 1])
            local rep = cc.RepeatForever:create(action)
            rep:setTag(GameViewLayer.AnimalTag.Tag_Animal)
            animal:runAction(rep)
        end )))
    end

    -- 银河系转动层
    self._alphaSprite = cc.Sprite3D:create("3d_res/model_6/wujian08.c3b")
    self._alphaSprite:setScale(1.0)
    self._alphaSprite:setPosition3D(cc.vec3(0, -9, 1))
    self._alphaSprite:setGlobalZOrder(1)
    self.m_3dLayer:addChild(self._alphaSprite)
    -- 指针
    self._arrow = cc.Sprite3D:create("3d_res/model_7/wujian11.c3b")
    self._arrow:setScale(0.04)
    self._arrow:setPosition3D(cc.vec3(0, -25, -2))
    self._arrow:setRotation3D(cc.vec3(0, 0, 0))
    self._arrow:setGlobalZOrder(2)
    self._arrow:setTexture("3d_res/model_7/hong.png")
    self.m_3dLayer:addChild(self._arrow)
end

function GameViewLayer:initCsbRes()
    -- 菜单层
    -- local uiFront = _game_require("UI.uiFront").create(self)
    -- self:addChild(uiFront);
    -- 下注层
    self:initPlaceJettonLayer()
    -- 派彩层 也称为游戏结束层
    self:initRewardLayer()
end
-- 下注层
function GameViewLayer:initPlaceJettonLayer()
    
end
-- 派彩层 也称为游戏结束层
function GameViewLayer:initRewardLayer()

end
-- 刷新彩灯
function GameViewLayer:updateColor(colorList)
	if not (self._resLoadFinish) then
		return;
	end

	-- colorList = {2,1,1,2,1,1,0,0,2,1,2,2,2,0,2,1,1,0,1,1,0,0,0,2}
	colorList = ifnil(colorList, {2,1,1,2,1,1,0,0,2,1,2,2,2,0,2,1,1,0,1,1,0,0,0,2})

	for i = 1, #colorList do
        local color = colorList[i]
        local file = "3d_res/model_8/hong.png"
        if color == 1 then
            file = "3d_res/model_8/lv.png"
        elseif color == 2 then
            file = "3d_res/model_8/huang.png"
        end

        local mess = self._colorList[i]

        local function callBackWithArgs(param)
            local ret
            ret = function()
                mess:setTexture(param)
            end
            return ret
        end

        self._colorList[i]:runAction(cc.Sequence:create(cc.DelayTime:create(0.03 *(i - 1)), cc.CallFunc:create(callBackWithArgs(file))))
    end
end
-- 指针转动
function GameViewLayer:arrowRunAction(nPointerAngle)
	nPointerAngle = ifnil(nPointerAngle, 0)

	local stopAngle = math.mod(nPointerAngle * 15 + 275, 360)
	stopAngle = stopAngle + 360 * 12
	local action = cc.EaseCircleActionInOut:create(cc.RotateTo:create(14, cc.vec3(0, stopAngle, 0)))
	self._arrow:runAction(action)
	self._alphaSprite:runAction(action:clone())
end
-- 动物转动起来
function GameViewLayer:runRotateAction(dt)
	if self._gameLayer._rotateStatus == initMsg.cmd.Stop then
        return
    end
	-- 限制条件稍后再说
	self._gameLayer._rotateTime = self._gameLayer._rotateTime + dt
	local angle = self._animLayer:getRotation3D().y - self._gameLayer._rotateSpeed
	angle =(angle < 0) and(angle + 360) or(math.mod(angle, 360))
    self._animLayer:setRotation3D(cc.vec3(0, angle, 0))

	if self._gameLayer._rotateStatus == initMsg.cmd.Speed then
		self._gameLayer._rotateSpeed = self._gameLayer._rotateSpeed + dt * 0.8
		if self._gameLayer._rotateSpeed > initMsg.cmd.RotateMax then
			self._gameLayer._rotateSpeed = initMsg.cmd.RotateMax
			self._gameLayer._rotateStatus = initMsg.cmd.ConSpeed
		end
	elseif self._gameLayer._rotateStatus == initMsg.cmd.ConSpeed then
		if self._gameLayer._rotateTime > 8 then
			local angle = self._animLayer:getRotation3D().y
			local angle0 = 360 - self._gameLayer._drawData.nAnimalAngle * 15
			local angle1 = angle0 - 120

			if angle1 < 0 then
				angle1 = angle1 + 360
				if angle < angle0 or angle < angle1 then
					self._gameLayer._rotateStatus = initMsg.cmd.SlowDown
				end
			elseif angle < angle0 and angle > angle1 then
				self._gameLayer._rotateStatus = initMsg.cmd.SlowDown
			end
		end
	elseif self._gameLayer._rotateStatus == initMsg.cmd.SlowDown then
		self._gameLayer._rotateSpeed = self._gameLayer._rotateSpeed - dt * 1.1
		if self._gameLayer._rotateSpeed < initMsg.cmd.RotateMin then
			self._gameLayer._rotateStatus = initMsg.cmd.RightJust
			self._gameLayer._rotateSpeed = initMsg.cmd.RotateMin
		end
	elseif self._gameLayer._rotateStatus == initMsg.cmd.RightJust then
		local angle = self._animLayer:getRotation3D().y
		local stopAngle = 360 - self._gameLayer._drawData.nAnimalAngle * 15
		local _angle = angle - stopAngle
		if math.abs(_angle) < initMsg.cmd.RotateMin then
			self._animLayer:setRotation3D(cc.vec3(0, stopAngle, 0))
			self._gameLayer._rotateStatus = initMsg.cmd.Stop
			self._gameLayer._bAnimalAction = false
			self:rotateEnd()
		end
	end
end

function GameViewLayer:rotateEnd()
    self._gameLayer._caijinStatus = 0

    if self._gameLayer._gameStatus ~= initMsg.cmd.IDI_GAME_DRAW then
        return
    end

    -- if 0 ~= bit:_and(self._gameLayer._drawData.dwAnimationFlag, initMsg.cmd.ANIMATION_PAYOUTGUN) then
    --     self:gunDeal()
    --     -- 打枪处理
    --     return
    -- elseif 0 ~= bit:_and(self._gameLayer._drawData.dwAnimationFlag, initMsg.cmd.ANIMATION_PAYOUTDSY) then
    --     self:showSeatAnim(1)
    --     return
    -- elseif 0 ~= bit:_and(self._gameLayer._drawData.dwAnimationFlag, initMsg.cmd.ANIMATION_PAYOUTDSX) then
    --     self:showSeatAnim(0)
    --     return
    -- else
    --     local index =(initMsg.cmd.BET_ITEM_TOTAL_COUNT - self._gameLayer._drawData.nAnimalAngle) +(initMsg.cmd.BET_ITEM_TOTAL_COUNT - self._gameLayer._drawData.nPointerAngle)
    --     index = math.mod(index, initMsg.cmd.BET_ITEM_TOTAL_COUNT)

    --     self._gameLayer._drawIndex = index + 1

    --     for i, v in ipairs(self._animals) do
    --         local animal = v
    --         if animal:getTag() == self._gameLayer._drawIndex then
    --             -- @ws           
    --             self:arrowAni(0,1)
                
    --             print("the tag is ================" .. animal:getTag())
    --             local angle = self._animLayer:getRotation3D().y
    --             angle = 360 - angle + 180
    --             animal:runAction(cc.MoveTo:create(0.5, cc.vec3(0 , 3, 0)))
    --             animal:runAction(cc.RotateTo:create(0.5, cc.vec3(0, angle, 0)))
                
    --             print("----------wwwwwwwwwwww"..angle)

               
    --             local resType = math.mod(index, 4)
    --             local modelFile = self:getAnimRes(resType)
    --             if self._gameLayer.winColor == 0 then
    --                 self.m_winColor:setColor(cc.c3b(217,26,3))
    --                 self._arrow:setTexture("3d_res/model_7/hong.png")
    --             elseif self._gameLayer.winColor == 1 then
    --                 self.m_winColor:setColor(cc.c3b(79,201,40))
    --                 self._arrow:setTexture("3d_res/model_7/lv.png")
    --             else
    --                 self.m_winColor:setColor(cc.c3b(217,201,103))
    --                 self._arrow:setTexture("3d_res/model_7/huang.png")
    --             end

    --             local animtion = cc.Animation3D:create(modelFile)
    --             animal:stopActionByTag(GameViewLayer.AnimalTag.Tag_Animal)
    --             local animate = cc.Animate3D:create(animtion, self._animalTimeFree[resType + 1], self._animalTimeWin[resType + 1])
    --             local action = cc.RepeatForever:create(animate)
    --             action:setTag(GameViewLayer.AnimalTag.Tag_Animal)
    --             animal:runAction(action)

    --             local soundIndex = resType * 3 + self._gameLayer._drawData.cbPointerColor
    --             self:playEffect(string.format("Animal_%d.wav", soundIndex))
    --             break
    --         end
    --     end

    --     if 0 ~= bit:_and(self._gameLayer._drawData.dwAnimationFlag, initMsg.cmd.ANIMATION_PAYOUTMGOLD) then
    --         self:showSeatAnim(1)
    --     else
    --         self:showSeatAnim(0)
    --     end
    --     self:playEffect("START_DRAW.wav")
    --     self._camera:runAction(cc.MoveTo:create(0.5, initMsg.cmd.Camera_Win_Vec3))
    -- end

    
end

-- 初始化信息 #模型加载完成 根据场景数据完成初始化
function GameViewLayer:enterInit()
	-- 彩灯信息
	self:updateColor(self._gameLayer._gameModel._sceneData.cbColorLightIndexList[1])
	-- dump(self._gameLayer._sceneData.cbColorLightIndexList, "self._gameLayer._sceneData.cbColorLightIndexList")
	
	-- self:updateColor(self._gameLayer._sceneData.cbColorLightIndexList)
	-- body
end

function GameViewLayer:mTest () 
	-- self:updateColor()
	self:delayCall(function ()
		-- self:updateColor()

		-- self:arrowRunAction()
	end, 1.5)
end

return GameViewLayer;