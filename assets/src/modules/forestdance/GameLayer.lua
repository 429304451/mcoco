local GameViewLayer = require("modules.forestdance.GameViewLayer")
local initMsg = require("modules.forestdance.initMsg")
local scheduler = cc.Director:getInstance():getScheduler()

local GameLayer = class("GameLayer", function (scene)
    return cc.Layer:create()
end)

function GameLayer:ctor(rootWidget)
	rootWidget:addChild(self)
	-- 场景资源是否加载完成了
	self._bCaijinStatus = false
	-- 是否有我的下注记录
	self.m_bPlaceRecord = false
	-- 是否处于空闲状态
	self._caijinStatus  = 0
	-- 玩家自己输赢
	self.m_lMeGrade     = 0   
	-- 庄家方位
	self.m_wBankerUser = initMsg.INVALID_CHAIR
	-- 中奖索引 
	self._drawIndex   = 0
	-- 当前筹码索引
	self._curJettonIndex = -1
	-- 剩余时间
	self._clockTimeLeave = 0
	-- 游戏状态
	self._gameStatus = initMsg.cmd.IDI_GAME_DRAW_RESULT
	-- 上庄状态
	self._applyStatus = initMsg.cmd.unApply
	-- 转盘状态
    self._rotateStatus = initMsg.cmd.Stop     
    -- 转盘状态
	self._rotateTime = 0
	-- 续压记录
	self._selfBetItemScore = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} 
    self.m_lContinueRecord  = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

    self._gameModel = {} -- GameFrame:create()
    self:createSchedule()

    -- ## 先用伪造数据初始化场景消息
	self:onEventGameScene()
	self:CreateView()


	
	self:delayCall(function ()
		self._rotateSpeed = initMsg.cmd.RotateMin;
		self._rotateStatus= initMsg.cmd.Speed
		-- 派彩数据 角度
		self._drawData = {}
		self._drawData.nAnimalAngle = 0
  		self._drawData.nPointerAngle = 0

		self._bAnimalAction = true;
	end, 1)
end

--创建场景
function GameLayer:CreateView()
	self._gameView = GameViewLayer:create(self)
	self:addChild(self._gameView)
	return self._gameView
end

-- 场景信息 貌似是进入游戏以前 先了解清楚的目前游戏场景信息 
function GameLayer:onEventGameScene()
	self._gameModel._bScene = true
	-- 进入游戏就获得的数据
	self._gameModel._sceneData = {
	    bAllowApplyBanker     = false,    -- 允许上庄	
	    cbApplyBankerCount    = 0,        -- 申请人数
	    cbBankerKeepCount     = 0,        -- 连庄局数
	    cbBankerListMaxItem   = 0,        -- 上庄上限
	    cbBetItemRatioList = {            -- 赔率列表 
	        {25,40,46,12,20,23,7,11,13,4,7,8}
	    },
	    cbBetTimeCount        = 10,       -- 下注时间
	    cbColorLightIndexList = {         -- 彩灯信息
	        {2,1,1,2,1,1,0,0,2,1,2,2,2,0,2,1,1,0,1,1,0,0,0,2}
	    },
	    cbCurrBankerKeepCount = 0,        -- 连庄局数
	    cbDrawTimeCount       = 23,       -- 开奖时间
	    cbEnjoyIndexList = {              -- 庄闲和倍率
	        {0, 0, 0}
	    },
	    cbFreeTimeCount       = 2,        -- 空闲时间
	    cbPayOutTimeCount     = 23,       -- 派彩时间
	    cbRouteListCount      = 1,        -- 路单数目  
	    dwRouteListData = {               -- 路单数据
	        {0, 0, 0, 0, 0, 0, 0, 8519680}
	    },
	    lApplyBankerScore     = 0,        -- 上庄分数
	    lBankerGrade          = 0,        -- 庄家成绩
	    lBetTotalCount = {                -- 下注金额
	        {0,0,0,0,0,0,0,0,0,0,0,0}
	    },
	    lItemBetTopLimit = {              -- 下注封顶
	        {0,0,0,0,0,0,0,0,0,0,0,0}
	    },
	    lUserItemBetTopLimit  = 10000,    -- 投注封顶
	    lUserTotalBetTopLimit = 100000000,-- 投注封顶
	    nAnimalRotateAngle    = 0,        -- 轮盘角度
	    nPointerRatateAngle   = 0,        -- 指针角度 
	    wApplyBankerList = {              -- 申请列表
	        {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	    },
	    wBankerChairID        = 65535,    -- 庄家方位
	}
	-- 庄家方位
	self.m_wBankerUser = self._gameModel._sceneData.wBankerChairID
	-- 上庄分数
	self.m_lApplyBankerScore = self._gameModel._sceneData.lApplyBankerScore
	-- 庄家成绩
	self.m_lBankerGrade = self._gameModel._sceneData.lBankerGrade
	-- ## 等待处理 我是否也是申请上庄人员
	-- local meItem = self:GetMeUserItem()
 --    for i=1,self._gameModel._sceneData.cbApplyBankerCount do
 --        local userItem = self._gameModel:getUserByChair(self:getUserList(),self._gameModel._sceneData.wApplyBankerList[1][i])
 --        if userItem.wChairID ~= meItem.wChairID then
 --        	self._gameModel:insertBankerList(userItem)
 --        end
 --    end
end

-- function GameLayer:getFrame( )
--     return self._gameFrame
-- end
-- function GameLayer:getUserList()
--     return self._gameFrame._UserList
-- end
-- -- 获取自己椅子
-- function GameModel:GetMeChairID()
--     return self._gameFrame:GetChairID()
-- end
-- -- 获取自己桌子
-- function GameModel:GetMeTableID()
--    return self._gameFrame:GetTableID()
-- end
-- -- 获取自己
-- function GameModel:GetMeUserItem()
--     return self._gameFrame:GetMeUserItem()
-- end
--退出桌子
function GameLayer:onExitTable()
	print("##onExitTable退出桌子")
end
--离开房间
function GameLayer:onExitRoom()
    print("##onExitRoom离开房间")
end

function GameLayer:createSchedule()

    local function update(dt)
    	-- print("dt", dt)
		-- --动物转动
		if true == self._bAnimalAction then
			self._gameView:runRotateAction(dt)
		end
		-- if true == self._bCaijinStatus then
		-- 	if math.mod(self._timeSkip,10) == 0 then
		-- 		self._gameView:updateCaijin()
		-- 	end
		-- end
		-- self._timeSkip = self._timeSkip + 1
    end

   --游戏定时器
    if nil == self.m_scheduleUpdate then
        self._timeSkip = 0
        self.m_scheduleUpdate = scheduler:scheduleScriptFunc(update, 0.02, false)
    end
end

return GameLayer;