-- local GameViewLayer = require("UI.GameViewLayer")
local GameViewLayer = require("modules.forestdance.GameViewLayer")

local GameLayer = class("GameLayer", function (scene)
    return cc.Layer:create()
end)

function GameLayer:ctor(rootWidget)
	rootWidget:addChild(self)
	self:CreateView();
end

--创建场景
function GameLayer:CreateView()
	self._gameView = GameViewLayer:create(self)
	self:addChild(self._gameView)
	return self._gameView
end

return GameLayer;