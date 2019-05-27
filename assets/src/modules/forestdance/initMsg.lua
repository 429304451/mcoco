local initMsg = {}
-- 由于游戏是直接拷贝进来的 肯定有很多原来的封装函数 公共量 都全部都写到这里 后面改造再移植
initMsg.readAnimation = function (file, key, num, time)
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

-- initMsg.cmd = {}
local cmd = {}
-- cmd.Camera_Normal_Vec3 = cc.vec3(0, 30, -29)
cmd.Camera_Normal_Vec3 = cc.vec3(0, 30, -30)
cmd.Camera_Rotate_Vec3 = cc.vec3(0, 28, -26)
cmd.Camera_Win_Vec3 = cc.vec3(0, 21, -20)

cmd.NormalPos 		 = 0
cmd.bottomHidden     = 1
cmd.hidden     		 = 2

--时间器定义
cmd.IDI_GAME_FREE				=10									--游戏空闲
cmd.IDI_GAME_BET                =11							        --游戏下注
cmd.IDI_GAME_DRAW               =12								    --游戏开奖
cmd.IDI_GAME_DRAW_RESULT        =13									--游戏派彩
cmd.IDI_DRAW_RESULT_SOUND		=14									--开奖结果	

--状态定义
cmd.GAME_STATUS_BET				=100								--下注状态
cmd.GAME_STATUS_DRAW			=101								--开奖状态
cmd.GAME_STATUS_DRAW_RESULT     =102								--派彩结果

--命令定义
cmd.SUB_S_START_FREE            =1                                  --空闲时间
cmd.SUB_S_START_BET             =2                                  --开始下注
cmd.SUB_S_START_DRAW            =3                                  --开始开奖
cmd.SUB_S_DRAW_RESULT			=4                                  --派彩时间
cmd.SUB_S_BETCOUNT_CHANGE       =5                                  --下注额改变
cmd.SUB_S_USER_BET				=6								    --用户下注	
cmd.SUB_S_BET_FAILED            =7                                  --下注失败
cmd.SUB_S_SYSTEM_INFO			=8                                  --系统信息 
cmd.SUB_S_BET_INFO				=9                                  --下注信息
cmd.SUB_S_BANKER_OPERATE		=10								    --庄家操作
cmd.SUB_S_SWITCH_BANKER			=11								    --切换庄家
cmd.SUB_S_BANKERINFO_VARIATION  =12								    --信息更新	

cmd.Clock_Free = 0 --空闲时间
cmd.Clock_Place= 1 --下注时间
cmd.Clock_Reward=2 --开奖时间
cmd.Clock_Back  =3  --返回时间

cmd.Type_Free = 0--空闲时间
cmd.Type_Place= 1--下注时间
cmd.Type_Reward=2--开奖时间
cmd.Type_Back = 3 --返回时间

cmd.Stop        = 0 --静止
cmd.Speed       = 1--加速
cmd.ConSpeed    = 2 --匀速
cmd.SlowDown    = 3--减速
cmd.RightJust   = 4  --调整位置

cmd.applyNone        = 0
cmd.applyed          = 1
cmd.unApply			 = 2

cmd.RotateMin   	 = 1
cmd.RotateMax 	     = 6
cmd.ArrowRotateMax   = 8

initMsg.cmd = cmd


initMsg.INVALID_CHAIR						= 65535










return initMsg