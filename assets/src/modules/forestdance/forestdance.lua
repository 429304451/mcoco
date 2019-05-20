-- Creat by Changwei on 2018/03/04 
local forestdance = class("forestdance", function (scene)
    return cc.Layer:create()
end)

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

    local csbnode = cc.CSLoader:createNode("csb/forest/bgNode.csb");
    csbnode:setPosition(display.center)
    self._rootNode = csbnode
    self:addChild(csbnode)

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




return forestdance
