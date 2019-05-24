-- Creat by Changwei on 2018/03/04 
local forestdance = class("forestdance", function (scene)
    return cc.Layer:create()
end)

local ExternalFun =  appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
-- local g_var = ExternalFun.req_var
local cmd = require("modules.forestdance.cmd_game")

forestdance.Tag = {
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
forestdance.AnimalTag =
{
    Tag_Animal = 1
}
local Tag = forestdance.Tag
forestdance.TopZorder = 30
forestdance.ViewZorder = 20

function forestdance:ctor(scene)
    scene:addChild(self)
    self._room_name   = "森林舞会"
    -- 设置背景图
    print("房间", self._room_name)
    -- ### 初始化常量
    self._userList = { }
    self._colorList = { }
    self._bMenu = false
    self._bSound = true
    self._bMusic = true
    self.bContinueRecord = true
    self:gameDataInit()
    self:initConstValue()
    self:loadRes()

    -- local csbnode = cc.CSLoader:createNode("csb/forest/bgNode.csb");
    -- csbnode:setPosition(display.center)
    -- self._rootNode = csbnode
    -- self:addChild(csbnode)

    -- local me = display.newSprite("img2/2.png")
    -- me:move(display.center)
    -- me:addTo(self, -1)

    -- self.grabredBgNode = ui.loadCS("csb/forest/bgNode")
    -- self:addChild(self.grabredBgNode)
    -- self.grabredBgNode:setScaleX(_gm.bgScaleW)
    -- self.grabredBgNode:setPosition(WIN_center)
    -- ui.setNodeMap(self.grabredBgNode, self)
    print("wocao")
end

function forestdance:gameDataInit()
    self._bMusic = true
    AudioEngine.stopMusic()
    -- 搜索路径
    -- local gameList = self:getParentNode():getParentNode():getApp()._gameList;
    -- local gameInfo = { };
    -- for k, v in pairs(gameList) do
    --     if tonumber(v._KindID) == tonumber(g_var(cmd).KIND_ID) then
    --         gameInfo = v;
    --         break;
    --     end
    -- end
    -- if nil ~= gameInfo._Module then
    --     self._searchPath = device.writablePath .. "game/" .. gameInfo._Module .. "/res/";
    --     cc.FileUtils:getInstance():addSearchPath(self._searchPath);
    -- end
end

function forestdance:readOnly(t)
    local _table = {}
    local mt = {
        __index = t,
        __newindex = function()
            error(" the table is read only ")
        end
    }
    setmetatable(_table, mt)
    return _table
end

function forestdance:initConstValue()
    -- 设置const数组
    --local value = { 13, 13, 14, 13 }
    local value = { 3.0, 1.65, 1.415, 2.5 }
    -- 动物正常动画时间
    self._animalTimeFree = self:readOnly(value)

    value = { 5.5, 4, 4, 3 }
    -- 动物胜利动画时间
    self._animalTimeWin = self:readOnly(value)

    value = { 10, 50, 100, 100000, 1000000, 10000000 }
    --value = { 100, 1000, 10000, 100000, 1000000, 10000000 }
    -- 下注筹码
    self._jettonArray = self:readOnly(value)
end

function forestdance:init3DModel()
    self.m_3dLayer = cc.Layer:create()
    self.m_3dLayer:setGlobalZOrder(1)
    self:addChild(self.m_3dLayer)

    self._camera = cc.Camera:createPerspective(60, display.width / display.height, 1, 1000)
    self._camera:setPosition3D(cmd.Camera_Normal_Vec3)
    self._camera:lookAt(cc.vec3(0, 0, 0))
    self._camera:setCameraFlag(cc.CameraFlag.USER1)
    --self._camera:setDepth(0)
    self.m_3dLayer:addChild(self._camera)

    local sprite = cc.Sprite3D:create("3d_res/model_bottom/dibu.c3b")
    sprite:setScale(1.0)
    sprite:setPosition3D(cc.vec3(0, -1.5, 0))
    sprite:setCameraMask(cc.CameraFlag.USER2)
    self.m_3dLayer:addChild(sprite)

    sprite = cc.Sprite3D:create("3d_res/model_bottom1/dibu2.c3b")
    sprite:setScale(1.0)
    sprite:setPosition3D(cc.vec3(0, -1.5, 0))
    sprite:setRotation3D(cc.vec3(0, 60, 0))
    sprite:setCameraMask(cc.CameraFlag.USER2)
    self.m_3dLayer:addChild(sprite)

    -- @ws 添加游戏场景
    sprite = cc.Sprite3D:create("3d_res/model_4/changjing.c3b")
    sprite:setScale(0.04)
    sprite:setPosition3D(cc.vec3(0,-20,-13))
    sprite:setRotation3D(cc.vec3(90, 0, 180))
    sprite:setCameraMask(cc.CameraFlag.USER1)
    self.m_3dLayer:addChild(sprite)
    -- @ws 加载背景颜色

    -- --local PointLight = cc.PointLight:create(cc.vec3(0,300,0), cc.c3b(255,255,219),2000.0)
    -- --[[
    -- local AmbientLight = cc.DirectionLight:create(cc.vec3(0,-10,-10), cc.c3b(255,255,219))
    
    --     --AmbientLight:retain()
    -- AmbientLight:setCameraMask(cc.CameraFlag.USER2)
    -- self:addChild(AmbientLight)
    -- --]]
    -- -- @ws 墙体
    --  -- @ws 墙体变色
    -- sprite = cc.Sprite3D:create("3d_res/model_4/qiangti_ani.c3b")
    -- sprite:setScale(0.04)
    -- sprite:setPosition3D(cc.vec3(0,-20,-13))
    -- sprite:setRotation3D(cc.vec3(90, 0, 180))
    -- sprite:setVisible(false)
    -- sprite:setCameraMask(cc.CameraFlag.USER1)
    -- self.m_3dLayer:addChild(sprite)

    -- sprite:setTexture("3d_res/model_4/qiangti_ani.png")
    -- sprite:setColor(cc.c3b(235,218,102))
    -- self.m_winColor = sprite


    -- sprite = cc.Sprite3D:create("3d_res/model_4/qiangti_ani.c3b")
    -- sprite:setScale(0.04)
    -- sprite:setPosition3D(cc.vec3(0,-20,-13))
    -- sprite:setRotation3D(cc.vec3(90, 0, 180))
    -- sprite:setCameraMask(cc.CameraFlag.USER1)
    -- self.m_3dLayer:addChild(sprite)

    -- sprite:setTexture("3d_res/model_4/qiangti_lanse.png")

    -- sprite = cc.Sprite3D:create("3d_res/model_4/tiaowen.c3b")
    -- sprite:setScale(0.04)
    -- sprite:setPosition3D(cc.vec3(0,-20,-13))
    -- sprite:setRotation3D(cc.vec3(90, 0, 180))
    -- sprite:setCameraMask(cc.CameraFlag.USER1)
    -- self.m_3dLayer:addChild(sprite)

    -- sprite:setTexture("3d_res/model_4/tiaowen.png")
    -- sprite:setColor(cc.c3b(150,160,25))
    -- self.tiaowen = sprite

    -- --self.tiaowen:runAction(cc.Blink:create(3.0,5))

    -- -- 加载纹理
    -- --local file = "3d_res/model_4/changjing.png"
    -- --sprite:setTexture(file)

    -- for i = 1, 6 do
    --     local wujian1 = cc.Sprite3D:create("3d_res/model_0/wujian.c3b")
    --     wujian1:setScale(1.0)
    --     wujian1:setPosition3D(cc.vec3(0, -0.1, 0))
    --     wujian1:setRotation3D(cc.vec3(0, 60 *(i - 1) + 30, 0))
    --     wujian1:setGlobalZOrder(1)
    --     wujian1:setCameraMask(cc.CameraFlag.USER2)
    --     self.m_3dLayer:addChild(wujian1)

    --     local wujian2 = cc.Sprite3D:create("3d_res/model_1/wujian02.c3b")
    --     wujian2:setScale(1.0)
    --     wujian2:setPosition3D(cc.vec3(0, -0.1, 0))
    --     wujian2:setRotation3D(cc.vec3(0, 60 *(i - 1) + 30, 0))
    --     wujian2:setGlobalZOrder(1)
    --     wujian2:setCameraMask(cc.CameraFlag.USER2)
    --     self.m_3dLayer:addChild(wujian2)

    --     local wujian3 = cc.Sprite3D:create("3d_res/model_3/wujian03.c3b")
    --     wujian3:setScale(1.0)
    --     wujian3:setPosition3D(cc.vec3(0, -0.1, 0))
    --     wujian3:setRotation3D(cc.vec3(0, 60 *(i - 1) + 30, 0))
    --     wujian3:setGlobalZOrder(1)
    --     wujian3:setCameraMask(cc.CameraFlag.USER2)
    --     self.m_3dLayer:addChild(wujian3)

    --     local wujian4 = cc.Sprite3D:create("3d_res/model_2/wujian04.c3b")
    --     wujian4:setScale(1.0)
    --     wujian4:setPosition3D(cc.vec3(0, -0.1, 0))
    --     wujian4:setRotation3D(cc.vec3(0, 60 *(i - 1), 0))
    --     wujian4:setGlobalZOrder(1)
    --     wujian4:setCameraMask(cc.CameraFlag.USER2)
    --     self.m_3dLayer:addChild(wujian4)
    -- end
end

function forestdance:getAnimRes(animIndex)
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

function forestdance:getAnimIMG(animIndex)
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

function forestdance:initAnimal()
    self._animLayer = cc.Sprite3D:create()
    self._animLayer:setPosition3D(cc.vec3(0, 0, 0))
    self.m_3dLayer:addChild(self._animLayer)
    local file1 = "3d_res/model_8/wujian10.c3b"
    local file2 = "3d_res/model_seat/di.c3b"

    self._animals = { }
    -- @ws 座位
    self._SeatAnimals = { }

    self.node = {}

    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

    for i = 1, 24 do
    -- @ws 三色地板
        local angle = 15 *(i - 1)
        local sprite = cc.Sprite3D:create(file1)
        sprite:setScale(0.04)
        
        sprite:setPosition3D(cc.vec3(-2 * math.sin(math.rad(angle)), -26, 2 * math.cos(math.rad(angle))))
        sprite:setRotation3D(cc.vec3(-90, 210 - angle ,0))
        sprite:setGlobalZOrder(2)
        sprite:setCameraMask(cc.CameraFlag.USER1)
        
        self.m_3dLayer:addChild(sprite)

        table.insert(self._colorList, sprite)

        -- @ws 底座修改
        self.model = cc.Sprite3D:create()
        self.model:setPosition3D(cc.vec3(0, 0, 0))
        self._animLayer:addChild(self.model)

        local dizuo = cc.Sprite3D:create(file2)
        dizuo:setScale(0.05)
        dizuo:setPosition3D(cc.vec3(-6 * math.sin(math.rad(angle)) , -31, 6 * math.cos(math.rad(angle)) ))
        dizuo:setRotation3D(cc.vec3(-90, 165 - angle, 0))
        dizuo:setGlobalZOrder(2)
        dizuo:setCameraMask(cc.CameraFlag.USER1)
        dizuo:setTexture("3d_res/model_seat/dizuo.png")
        self.model:addChild(dizuo)
        
        table.insert(self._SeatAnimals, dizuo)
        
        
        -- @ws 圆环
        local icon_win = cc.Sprite3D:create("3d_res/model_5/yuanhuan.c3b")
        icon_win:setScale(0.05)
        icon_win:setPosition3D(cc.vec3(19 * math.sin(math.rad(angle)) , -36, -19 * math.cos(math.rad(angle)) ))
        icon_win:setRotation3D(cc.vec3(-90, 345 - angle, 0))
        icon_win:setVisible(false)
        icon_win:setGlobalZOrder(2)
        icon_win:setCameraMask(cc.CameraFlag.USER1)
        icon_win:setTexture("3d_res/model_5/lv.png")
        self.model:addChild(icon_win)


        local animIndex = math.mod(i - 1, 4)
        local modelFile = self:getAnimRes(animIndex)
        -- @ws 加上纹理
        local texture = self:getAnimIMG(animIndex)

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
        animal:setCameraMask(cc.CameraFlag.USER1)
        self.model:addChild(animal)

        table.insert(self._animals, animal)
        table.insert(self.node, self.model)
       

        animal:runAction(cc.Sequence:create(delay, cc.CallFunc:create( function()
            local fTime = math.random(0, 1) * 5
            local animtion = cc.Animation3D:create(modelFile)
            local delay = cc.DelayTime:create(fTime)
            local action = cc.Animate3D:create(animtion, 0, self._animalTimeFree[animIndex + 1])
            local rep = cc.RepeatForever:create(action)
            rep:setTag(self.AnimalTag.Tag_Animal)
            animal:runAction(rep)
        end )))
    end
        
        
        table.insert(self._SeatAnimals, dizuo)

    -- 透明转动层
    self._alphaSprite = cc.Sprite3D:create("3d_res/model_6/wujian08.c3b")
    self._alphaSprite:setScale(1.0)
    self._alphaSprite:setPosition3D(cc.vec3(0, -9, 1))
    self._alphaSprite:setGlobalZOrder(1)
    self._alphaSprite:setCameraMask(cc.CameraFlag.USER1)
    self.m_3dLayer:addChild(self._alphaSprite)

    local dizuo = cc.Sprite3D:create("3d_res/model_4/dizuo.c3b")
    dizuo:setScale(1.0)
    dizuo:setPosition3D(cc.vec3(0, 0, 0))
    dizuo:setGlobalZOrder(2)
    dizuo:setCameraMask(cc.CameraFlag.USER2)
    self.m_3dLayer:addChild(dizuo)

    self._seat = cc.Sprite3D:create("3d_res/model_5/wujian07.c3b")
    self._seat:setScale(1.0)
    self._seat:setPosition3D(cc.vec3(0, 0, -0.5))
    self._seat:setGlobalZOrder(1)
    self._seat:setCameraMask(cc.CameraFlag.USER2)
    dizuo:addChild(self._seat)

    self._arrow = cc.Sprite3D:create("3d_res/model_7/wujian11.c3b")
    self._arrow:setScale(0.04)
    self._arrow:setPosition3D(cc.vec3(0, -25, -2))
    self._arrow:setGlobalZOrder(2)
    self._arrow:setTexture("3d_res/model_7/hong.png")
    self._arrow:setCameraMask(cc.CameraFlag.USER1)
    self.m_3dLayer:addChild(self._arrow)
end
-- @ws 顶部动画
function forestdance:topAnimation(bool,num)
    self.showNum = self.showNum + 1
    self.showType = self.showType + 1
    if self.showType > 2 then
        self.showType = 0
    end
    if self.showNum > 6 then
        bool = false
    end
    local file = string.format("game_res/game_sence/icon_top_"..self.showType..".png")
    local node_top = self._rootNode:getChildByName("icon_top_frame")
    local mark = node_top:getChildByName("mark")
    local sp_top = mark:getChildByName("icon_top_he")
    if bool then
        sp_top:runAction(cc.Sequence:create(
        cc.MoveTo:create(0.7,cc.p(37,58)),
        cc.CallFunc:create(function()
            sp_top:setPosition(37,-18)
            self:topAnimation(true,num)
            sp_top:setTexture(file)         
        end)
        ))
        
    else
        if not num then
            num = 2
        end
        sp_top:runAction(cc.Sequence:create(cc.CallFunc:create(function() 
            sp_top:setTexture("game_res/game_sence/icon_top_"..num..".png")
            self.showType = -1
            self.showNum = 0
            self.showRotateEffect(5)
        end),cc.MoveTo:create(1,cc.p(37,21))))
      
    end
end
function forestdance:popPlaceJettonLayer(pos)
    if pos == cmd.NormalPos or not pos then
        -- 弹出
        self._PlaceJettonLayer:setVisible(true)
        self._PlaceJettonLayer:runAction(cc.MoveTo:create(0.2, cc.p(display.width / 2, display.height / 2 - 60)))
        self._posStyle = cmd.NormalPos
    elseif pos == cmd.bottomHidden then
        -- 弹到底部
        self._PlaceJettonLayer:setVisible(true)
        self._PlaceJettonLayer:runAction(cc.MoveTo:create(0.2, cc.p(display.width / 2, -250)))
        self._posStyle = cmd.bottomHidden
    elseif pos == cmd.hidden then
        -- 全部隐藏
        self._PlaceJettonLayer:runAction(
        cc.Sequence:create(cc.MoveTo:create(0.2, cc.p(yl.WIDTH / 2, - yl.HEIGHT)),
        cc.CallFunc:create( function()
            self._PlaceJettonLayer:setVisible(false)
            self._posStyle = cmd.hidden
        end ))
        )
    end
end

function forestdance:setJettonIndex(index)
    if index == -1 then
        self:blinkEffect(false)
        return
    end

    self._curJettonIndex = index
    self:blinkEffect(true, index)
end

function forestdance:blinkEffect(isAction, index)
    local circles = { }
    for i = 1, 6 do
        local circle = self._PlaceJettonLayer.rootNode:getChildByName(string.format("circle_%d", i))
        table.insert(circles, circle)
        circle:setVisible(false)
        circle:stopAllActions()
    end

    if true == isAction then
        local circle = circles[index]
        circle:setVisible(true)
        circle:runAction(cc.RepeatForever:create(cc.Blink:create(1, 2)))
    end
end

-- @ws 点击按钮效果
function forestdance:showBtnAreaMark(btnNum,bShow)
    local Node_mark = self._PlaceJettonLayer.rootNode:getChildByName("Node_gray")
    local mark = Node_mark:getChildByName(string.format("gray_%d",btnNum))
    if bShow then
        mark:setVisible(true)
    else
        mark:setVisible(false)
    end
end
function forestdance:PlaceJettonEvent(tag)
    util.mlog("下注", tag)
    -- ## 等待处理
    -- if self._curJettonIndex <= 0 or self.m_wBankerUser == self:GetMeUserItem().wChairID then
    --     return
    -- end

    -- local itemScore = self._selfBetItemScore[tag]
    -- local topLimit = self._gameModel._sceneData.lUserItemBetTopLimit
    -- if itemScore >= topLimit then
    --     return
    -- end


    -- if itemScore + self._jettonArray[self._curJettonIndex] > topLimit then
    --     local index = 1
    --     if self._curJettonIndex == 1 then
    --         index = -1
    --     end
    --     self:setJettonIndex(index)
    --     return
    -- end

    -- local allScore = 0
    -- topLimit = self._gameModel._sceneData.lUserTotalBetTopLimit
    -- for i = 1, g_var(cmd).BET_ITEM_COUNT do
    --     allScore = allScore + self._selfBetItemScore[i]
    -- end

    -- if allScore >= topLimit then
    --     return
    -- end

    -- if allScore + self._jettonArray[self._curJettonIndex] > topLimit then
    --     local index = 1
    --     if self._curJettonIndex == 1 then
    --         index = -1
    --     end
    --     self:setJettonIndex(index)
    --     return
    -- end

    -- local item = self:GetMeUserItem()
    -- local tmp = item.lScore - self._jettonArray[self._curJettonIndex]

    -- if tmp < 0 then
    --     local index = 1
    --     if self._curJettonIndex == 1 then
    --         index = -1
    --     end
    --     self:setJettonIndex(index)
    --     return
    -- end

    -- item.lScore = tmp
    -- self._selfBetItemScore[tag] = self._selfBetItemScore[tag] + self._jettonArray[self._curJettonIndex]
    -- if not self.m_bPlaceRecord then
    --     self.m_lContinueRecord = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ,0,0,0}
    --     self.m_bPlaceRecord = true
    --     self.bContinueRecord = true
    -- end

    -- self.m_lContinueRecord[tag] = self.m_lContinueRecord[tag] + self._jettonArray[self._curJettonIndex]

    -- -- 发送加注
    -- local dataBuffer = CCmd_Data:create(9)
    -- local itemIndex = tag - 1
    -- dataBuffer:pushbyte(itemIndex)
    -- dataBuffer:pushscore(self._jettonArray[self._curJettonIndex])
    -- self:SendData(g_var(cmd).SUB_C_USER_BET, dataBuffer)

    -- self:playEffect("BetItem.wav")
end

function forestdance:continueEvent(index)
    util.mlog("续压", index)
    -- ## 等待处理
    -- if self.m_wBankerUser == self._scene:GetMeUserItem().wChairID then
    --     return
    -- end

    -- local itemScore = self._scene.m_lContinueRecord[index]
    -- local topLimit = self._scene._gameModel._sceneData.lUserItemBetTopLimit
    -- if itemScore >= topLimit then
    --     return
    -- end

    -- local allScore = 0
    -- topLimit = self._scene._gameModel._sceneData.lUserTotalBetTopLimit
    -- for i = 1, g_var(cmd).BET_ITEM_COUNT do
    --     allScore = allScore + self._scene.m_lContinueRecord[i]
    -- end

    -- if allScore >= topLimit then
    --     return
    -- end

    -- local item = self._scene:GetMeUserItem()
    -- local tmp = item.lScore - self._scene.m_lContinueRecord[index]

    -- if tmp < 0 then
    --     return
    -- end

    -- item.lScore = tmp
    -- self._scene._selfBetItemScore[index] = self._scene.m_lContinueRecord[index]

    -- -- 发送加注
    -- local dataBuffer = CCmd_Data:create(9)
    -- local itemIndex = index - 1
    -- dataBuffer:pushbyte(itemIndex)
    -- dataBuffer:pushscore(self._scene.m_lContinueRecord[index])
    -- self._scene:SendData(cmd.SUB_C_USER_BET, dataBuffer)
    
end

function forestdance:initPlaceJettonLayer()
    print("initPlaceJettonLayer")
    self._posStyle = cmd.NormalPos
    self._PlaceJettonLayer = ccui.ImageView:create()
    self._PlaceJettonLayer:setContentSize(cc.size(display.width, display.height))
    self._PlaceJettonLayer:setScale9Enabled(true)
    self._PlaceJettonLayer:setAnchorPoint(cc.p(0.5, 0.5))
    self._PlaceJettonLayer:setPosition(display.width / 2, - display.height)
    self._PlaceJettonLayer:setTouchEnabled(true)
    self:addChild(self._PlaceJettonLayer, self.TopZorder)

    self._PlaceJettonLayer:addTouchEventListener( function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            --self:popPlaceJettonLayer(g_var(cmd).bottomHidden)
        end
    end )

    -- 加载CSB
    local csbnode = cc.CSLoader:createNode("game_res/PlaceJetton.csb");
    csbnode:setPosition(display.width / 2, display.height / 2)
    self._PlaceJettonLayer:addChild(csbnode)
    self._PlaceJettonLayer.rootNode = csbnode
    self.msg_PlaceJetton = {};
    ui.setNodeMap(csbnode, self.msg_PlaceJetton)

    --@ws 添加弹出按钮
    -- local icon_yazhu = csbnode:getChildByName("icon_yazhu")
    local bIsShowjettonBg = false

    -- local jettonBg = csbnode:getChildByName("Image_1")
    self.msg_PlaceJetton.icon_yazhu:addTouchEventListener( function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            if bIsShowjettonBg == true then
                self:popPlaceJettonLayer(cmd.NormalPos)
                bIsShowjettonBg = false
            else
                self:popPlaceJettonLayer(cmd.bottomHidden)
                bIsShowjettonBg = true
            end
            
        end
    end )
    -- @ws 添加弹出按钮
   --[[
    icon_yazhu:addTouchEventListener( function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:popPlaceJettonLayer(g_var(cmd).NormalPos)
        end

    end )
    --]]
    -- 初始化按钮事件
    local btns = { }
    for i = 1, 6 do
        local btn = csbnode:getChildByName(string.format("btn_%d", i))
        btn:setTag(i)
        btn:addTouchEventListener( function(sender, eventType)            
            if eventType == ccui.TouchEventType.ended then
                self:setJettonIndex(sender:getTag())
            end
        end )
    end

    -- 下注区域
    for i = 1, 15 do--g_var(cmd).BET_ITEM_COUNT do
        local bet = self._PlaceJettonLayer.rootNode:getChildByName(string.format("btn_bet_%d", i))
        bet:setTag(i)
        assert(bet)
        bet:addTouchEventListener( function(sender, eventType)
            if eventType == ccui.TouchEventType.began then
                self:showBtnAreaMark(i,true)

            elseif eventType == ccui.TouchEventType.ended then
                self:showBtnAreaMark(i,false)
                self:PlaceJettonEvent(sender:getTag())

            end
        end )
    end

    -- 续压
    local btn = self._PlaceJettonLayer.rootNode:getChildByName("btn_continue")
    btn:addTouchEventListener( function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            sender:setEnabled(false)
            self.bContinueRecord = true
            -- 一局只能续压一次
            for i = 1, #self.m_lContinueRecord do
                if self.m_lContinueRecord[i] > 0 then
                    -- 发送加注 i是逻辑索引
                    self:continueEvent(i)
                end
            end
        end
    end )
    -- @ws 自动按钮和取消按钮
    btn = self._PlaceJettonLayer.rootNode:getChildByName("btn_cancel")
    btn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            -- TODO 这里是取消的功能
            
            for i = 1, #self._selfBetItemScore do
                if self._selfBetItemScore[i] > 0 then
                    -- 发送取消                   
                    local total = tonumber(self.totalScore[i]:getString())
                    local myScore = tonumber(self.myScore[i]:getString())
                    local lastTotal = total - myScore
                    self.totalScore[i]:setString(lastTotal)
                    self.myScore[i]:setString("0")
                    self._selfBetItemScore = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,0}
                    self._gameModel._sceneData.lBetTotalCount[1][i] = lastTotal
                    
                    local dataBuffer = CCmd_Data:create(0)
                    -- self:SendData(cmd.SUB_C_CANCEL_BET, dataBuffer) -- ## 等待处理
                   
                end
            end
            
        end
    end)

    btn = self._PlaceJettonLayer.rootNode:getChildByName("btn_auto")
    btn:addTouchEventListener(function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            -- TODO 这里是自动的功能
            --showToast(self,"功能尚未开放",1)
           self:topAnimation(true)
        end
    end)
    print("initPlaceJettonLayer3333")
end

function forestdance:initCsbRes()
    print("initCsbRes")
    -- 菜单层
    local rootLayer, csbNode = ExternalFun.loadRootCSB("game_res/Top.csb", self)
    self._rootNode = csbNode
    local btn_close = csbNode:getChildByName("btn_close")
    -- btn_close:setScale(2)
    -- btn_close:quickBt(function ()
    --     util.mlog("quickBt()")
    -- end)

    -- local me = display.newSprite("img2/2.png")
    -- me:move(display.center)
    -- me:addTo(csbNode, 99)
    -- me:quickBt(function ()
    --     util.mlog("quickBt()")
    -- end)

    -- me:onClick(function ()
    --     util.mlog("onClick()")
    -- end)
    -- me:addTouchEventListener(function(sender, eventType)
    --     if eventType == ccui.TouchEventType.ended then
    --         -- TODO 这里是自动的功能
    --         --showToast(self,"功能尚未开放",1)
    --        -- self:topAnimation(true)
    --        util.mlog("addTouchEventListener")
    --     end
    -- end)
    -- 下注层
    self:initPlaceJettonLayer()

    -- -- 派彩层
    -- self:initRewardLayer()

    -- self:initButtonEvent()

    -- self:initUserInfo()
end

function forestdance:load2DModelCallBack(texture)

    self._2dResCount = self._2dResCount + 1
    if self._3dIndex == self._3dResCount and self._2dResCount == self._2dResTotal and not self._resLoadFinish then
        print("load2DModelCallBack")
        cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/game.plist")
        cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/anim_sd.plist")
        cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/anim_sx.plist")
        cc.SpriteFrameCache:getInstance():addSpriteFrames("game_res/anim_sy.plist")
        

        local function readAnimation(file, key, num, time)
            local frames = { }
            local actionTime = time
            for i = 1, num do
                local frameName = string.format(file .. "%d.png", i - 1)
                local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(frameName)
                table.insert(frames, frame)
            end

            local animation = cc.Animation:createWithSpriteFrames(frames, actionTime)
            cc.AnimationCache:getInstance():addAnimation(animation, key)
        end

        readAnimation("cj", "CJAnim", 15, 0.07)
        readAnimation("sd", "SDAnim", 15, 0.07)
        readAnimation("sx", "SXAnim", 15, 0.07)
        readAnimation("sy", "SYAnim", 15, 0.07)

        -- self:removeChildByTag(23) -- ## 等待处理

        self:init3DModel()
        -- self:initAnimal()
        -- self:initCsbRes()
        print("load2DModelCallBack333")

        self._resLoadFinish = true
        self._bCaijinStatus = true

        -- if self._gameModel._bScene then
        --     self._animLayer:setRotation3D(cc.vec3(0, 360 - self._gameModel._sceneData.nAnimalRotateAngle * 15, 0))
        --     self._arrow:setRotation3D(cc.vec3(0, self._gameModel._sceneData.nPointerRatateAngle * 15 + 185, 0))
        -- end

        -- if self._gameStatus <= g_var(cmd).IDI_GAME_BET then
        --     -- 空闲或下注状态
        --     self._loadLayer:removeFromParent()
        --     self._loadLayer = nil

        --     self:updateColor()

        --     self:setGameStatus(self._gameStatus)

        --     if self._gameStatus == g_var(cmd).IDI_GAME_BET then
        --         -- 下注状态
        --         -- 更新区域倍率
        --         self:updateAreaMultiple()
        --         -- 弹出下注层
        --         self:popPlaceJettonLayer()
        --         -- 更新按钮状态
        --         self:updateControl()
        --     end
        -- end
        print("load2DModelCallBack444")
    end
end
-- 加载层
function forestdance:loading()
    -- self:dismissPopWait() -- ## 等待处理
    if self._loadLayer then
        self._loadLayer:removeFromParent()
    end
    self._loadLayer = cc.Layer:create()
    self:addChild(self._loadLayer, forestdance.TopZorder)

    -- 加载背景
    local bg = cc.Sprite:create("load_res/im_loadbg_0.png")
    bg:setAnchorPoint(cc.p(0.5, 0.5))
    bg:setPosition(display.center)
    self._loadLayer:addChild(bg)

    -- title
    local title = cc.Sprite:create("load_res/im_title_0.png")
    title:setAnchorPoint(cc.p(0.5, 0.5))
    title:setVisible(false)
    title:setPosition(display.center)
    self._loadLayer:addChild(title)

    local frames = { }
    for j = 1, 2 do
        local frame = cc.SpriteFrame:create("load_res/" .. string.format("im_loadbg_%d.png", j - 1), cc.rect(0, 0, 1334, 750))
        table.insert(frames, frame)
    end
    local animation = cc.Animation:createWithSpriteFrames(frames, 0.5)
    local animate = cc.Animate:create(animation)
    bg:runAction(cc.RepeatForever:create(animate))

    frames = { }
    for j = 1, 2 do
        local frame = cc.SpriteFrame:create("load_res/" .. string.format("im_title_%d.png", j - 1), cc.rect(0, 0, 782, 375))
        table.insert(frames, frame)
    end
    animation = cc.Animation:createWithSpriteFrames(frames, 0.5)
    animate = cc.Animate:create(animation)
    title:runAction(cc.RepeatForever:create(animate))
end

function forestdance:loadRes()
    -- self:dismissPopWait() -- ## 等待处理
    -- 加载层
    -- self:loading()
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
    table.insert(modelFiles, "3d_res/model_0/wujian.c3b")
    table.insert(modelFiles, "3d_res/model_1/wujian02.c3b")
    table.insert(modelFiles, "3d_res/model_2/wujian04.c3b")
    table.insert(modelFiles, "3d_res/model_3/wujian03.c3b")
    table.insert(modelFiles, "3d_res/model_4/wujian07.c3b")
    table.insert(modelFiles, "3d_res/model_5/wujian07.c3b")
    table.insert(modelFiles, "3d_res/model_6/wujian08.c3b")
    table.insert(modelFiles, "3d_res/model_7/wujian11.c3b")
    table.insert(modelFiles, "3d_res/model_8/wujian10.c3b")
    table.insert(modelFiles, "3d_res/model_bottom/dibu.c3b")
    table.insert(modelFiles, "3d_res/model_bottom1/dibu2.c3b")
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
function forestdance:load3DModelCallBack(...)
    print("load 3d model")
    self._3dIndex = self._3dIndex + 1

    if self._3dIndex == self._3dResCount and self._2dResCount == self._2dResTotal and not self._resLoadFinish then
        -- self._scene._scene:removeChildByTag(23)
        self:init3DModel()
        self:initAnimal()
        self:initCsbRes()
        self._resLoadFinish = true
        -- self._scene._bCaijinStatus = true

        -- if self._scene._gameModel._bScene then
        --     self._animLayer:setRotation3D(cc.vec3(0, 360 - self._scene._gameModel._sceneData.nAnimalRotateAngle * 15, 0))
        --     self._arrow:setRotation3D(cc.vec3(0, self._scene._gameModel._sceneData.nPointerRatateAngle * 15 + 185, 0))
        -- end

        -- if self._scene._gameStatus <= g_var(cmd).IDI_GAME_BET then
        --     -- 空闲或下注状态
        --     self._loadLayer:removeFromParent()
        --     self._loadLayer = nil
        --     self:updateColor()

        --     self:setGameStatus(self._scene._gameStatus)

        --     if self._scene._gameStatus == g_var(cmd).IDI_GAME_BET then
        --         -- 下注状态
        --         -- 更新区域倍率
        --         self:updateAreaMultiple()
        --         -- 弹出下注层
        --         self.popPlaceJettonLayer()
        --         -- 更新按钮状态
        --         self:updateControl()
        --     end
        -- end
    end
end

return forestdance
