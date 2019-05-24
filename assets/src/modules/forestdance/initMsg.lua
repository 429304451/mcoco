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
cmd.Camera_Normal_Vec3 = cc.vec3(0, 30, -29)
cmd.Camera_Rotate_Vec3 = cc.vec3(0, 28, -26)
cmd.Camera_Win_Vec3 = cc.vec3(0, 21, -20)

initMsg.cmd = cmd















return initMsg