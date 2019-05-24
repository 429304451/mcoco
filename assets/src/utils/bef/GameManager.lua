-- 游戏管理器
GameManager = {}
_gm = GameManager
_gm.__cname = "GameManager"
--当前场景
_gm.curScene = nil
--当前层
_gm.curLayer = nil
--游戏系统层级ID
_gm.ID_BG    = 1
_gm.ID_Main  = 2
_gm.ID_Menu  = 3
_gm.ID_Win   = 4
_gm.ID_Dlg   = 5
_gm.ID_Guild = 6
_gm.ID_Effect= 7
_gm.ID_SysTip= 8
_gm.ID_Warn  = 9
_gm.ID_Debug = 10

--适配参数计算
function GameManager:fun_calInv()

end
function GameManager:startUIScene()
	
end

--战斗跳转到主场景
function GameManager:turnToUIScene()
end

--打开是否关闭游戏弹出框
function GameManager:openEndGameDialog()
end

--重新加载lua文件
function GameManager:reloadLua()
	for k,v in pairs(package.loaded) do
		--只有lua模块卸载
		local path = string.gsub(k, "%.", "/")
		local filePath = cc.FileUtils:getInstance():fullPathForFilename("luaassets/script/"..path..".luac")
		if filePath == nil or filePath == "" then
			filePath = cc.FileUtils:getInstance():fullPathForFilename("luaassets/script/"..path..".lua")
		end
		if filePath ~= nil and filePath ~= "" then
			package.loaded[k] = nil
			require(k)
		end
	end
end

--游戏重新启动
function GameManager:gameReStart()
end

--退到登陆
function GameManager:backToLogin()
end

--心跳包
function GameManager:sendHeart()
end

--停止心跳包
function GameManager:stopHeart()
end

function GameManager:loginSdk(obj,pCallback)
end

function GameManager:logoutSdk()
end

function GameManager:loadFiles()
	
end

