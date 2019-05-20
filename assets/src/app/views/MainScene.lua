
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

MainScene.RESOURCE_FILENAME = "MainScene.csb"

function MainScene:onCreate()
    printf("resource node = %s", tostring(self:getResourceNode()))

    -- local me = 1;
    -- layer:addTo(self)

    local me = display.newSprite("img2/2.png")
    me:move(display.center)
    me:addTo(self, -1)
    local size = me:getContentSize()
    -- print("me", size.width, size.height)
    me:setScaleX(1334/size.width)
    me:setScaleY(display.height/size.height)

    -- me:delayCall(function ()
    --     print("wocao")
    -- end, 1)
    -- me.scaleY = 750/size.height
    -- me:setContentSize(cc.size(1334, 750))

    -- util.delayCall(self, self.wocao, 1)
    -- util.delayCall(me, function() print("22222") end,2)
    -- local action = cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function()
        
    -- end))

    -- me:runAction(action)
    
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
