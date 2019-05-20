
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"

function MainScene:onCreate()
    printf("resource node = %s", tostring(self:getResourceNode()))

    -- local me = 1;
    -- layer:addTo(self)
    print("111111")

    local me = display.newSprite("HelloWorld.png")
    me:move(display.center)
    me:addTo(self)

    -- util.delayCall(self, self.wocao, 1)
    -- util.delayCall(me, function() print("22222") end,2)
    local action = cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        -- if self._defAni then
        --     self:setRoleAct(self._defAni)
        -- end
        print("wocao")

        print("2")

        print("3")
    end))

    me:runAction(action)
    
    --[[ you can create scene with following comment code instead of using csb file.
    -- add background image
    display.newSprite("HelloWorld.png")
        :move(display.center)
        :addTo(self)

    -- add HelloWorld label
    cc.Label:createWithSystemFont("Hello World", "Arial", 40)
        :move(display.cx, display.cy + 200)
        :addTo(self)
    ]]
end


return MainScene
