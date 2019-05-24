-- Create by changwei on 2019/05/23 主要用于对csb的处理
ui = class("ui")
--type:页面类型  id:唯一标识  clear:关闭后是否删除(只有ID_Win 有效)  path:页面地址  backKeytoClose:返回键关闭窗口
-- ui.Login 				= {type=_gm.ID_Main,	id=10001,	clear=false	,path="modules.login.Login",uipath="ui.login.Login"}
-- ui.Login = 1;
-- ui.Login 				= {type=_gm.ID_Main, id=10001, clear=false, path="modules.login.Login", uipath="ui.login.Login"}
-- ui.puchengBomb 	        = {type=_gm.ID_Win,	hideHall = true, clear=true, path="modules.CardGames.puchengBomb.puchengBomb"}
-- ui.puchengBomb 	        = {type=_gm.ID_Win,	hideHall = true, clear=true, path="modules.CardGames.puchengBomb.puchengBomb"}

local postedLog = {}
function ui.printCsError(path)
	trace("-----------------------------------------------")
	trace("----------------!!!!!!!!!!!!!!!----------------")
	trace("Cs Create Error!!!!!! Cs File Not Found ："..path)
	if not postedLog[path] then
		postedLog[path] = true
		print("Cs Create Error!!!!!! Cs File Not Found ："..path)
		-- ## 等待处理
		-- util.postLogToServer("Cs Create Error!!!!!! Cs File Not Found ："..path)
	end
	trace("----------------!!!!!!!!!!!!!!!----------------")
	trace("-----------------------------------------------")
end

-- 创建CS节点
-- 使用举例: ani = ui.loadCS("csb/15_zhadandonghua")
function ui.loadCS(path)
	local resType = string.sub(path, -4, -1)
	local node = nil
	if resType == ".csd" then
		if cc.FileUtils:getInstance():isFileExist(path) then
			node = cc.CSLoader:getInstance():createNodeWithFlatBuffersForSimulator(path)
		else
			ui.printCsError(path)
		end
	else
		if cc.FileUtils:getInstance():isFileExist(path..".csb") then
			node = cc.CSLoader:createNode(path..".csb")
		else
			ui.printCsError(path..".csb")
		end
	end
	return node
end

-- 创建CS动画
-- 使用举例: ani = ui.loadCS("csb/15_zhadandonghua")
-- aniAction = ui.loadCSTimeline("csb/15_zhadandonghua")
-- aniAction:play("donghua", false)
function ui.loadCSTimeline(path)
	local resType = string.sub(path, -4, -1)
	local action = nil
	if resType == ".csd" then
		if cc.FileUtils:getInstance():isFileExist(path) then
			action = ccs.ActionTimelineCache:getInstance():createActionWithFlatBuffersForSimulator(path)
		else
			ui.printCsError(path)
		end
	else
		if cc.FileUtils:getInstance():isFileExist(path..".csb") then
			action = cc.CSLoader:createTimeline(path..".csb")
		else
			ui.printCsError(path..".csb")
		end
	end
	return action
end

-- 从csd界面转lua的界面创建
function ui.createCsb(obj)
	print("ui.createCsb", obj)
	local pathTable = string.split(obj.uipath, ".")
	local cabPath = "csb"

	for i=2,#pathTable do
		cabPath = cabPath .. "/" .. pathTable[i]
	end
	trace("==========从csd界面转lua的界面创建==========",cabPath)
	local node = ui.loadCS(cabPath)
	local tab = tolua.getpeer(node)
	if not tab then
		tab = {}
		tolua.setpeer(node, tab)
	end
	ui.setNodeMap(node, tab)
	return {root = node}
end

-- 从csd界面转lua的界面创建
-- 使用举例: local tip = ui.createCsbItem("csb.Tips")
-- tip.lbl_tips:setString(str)
function ui.createCsbItem(path)
	local cabPath = string.gsub(path, "%.", "/")
	local node = ui.loadCS(cabPath)
    if node:getName() == "ListItem" then
        local oldNode = node
        local size = oldNode:getContentSize()
        local layout = ccui.Layout:create()
        layout:setContentSize(size)
        for i,v in ipairs(oldNode:getChildren()) do
            v:getParent():removeChild(v, false)
            layout:addChild(v)
        end
        ui.setNodeMap(layout, layout)
        node = layout
	else
		ui.setNodeMap(node, node)
    end
	return node
end

-- 将csb的每个节点昵称都赋给第二个参数可以立即取到
function ui.setNodeMap(node, tbl)
	if not node then
		return
	end
	local findNode
	local children = node:getChildren()
	local childCount = node:getChildrenCount()
	if childCount < 1 then
		return
	end
	for i=1, childCount do
		if "table" == type(children) then
			tbl[children[i]:getName()] = children[i]
			ui.setNodeMap(children[i], tbl)
		end
	end
	return
end

-- 查找CSD下节点
function ui.seekNodeByName(parent, name)
	if not parent then
		return
	end

	if name == parent:getName() then
		return parent
	end

	local findNode
	local children = parent:getChildren()
	local childCount = parent:getChildrenCount()
	if childCount < 1 then
		return
	end
	for i=1, childCount do
		if "table" == type(children) then
			parent = children[i]
		elseif "userdata" == type(children) then
			parent = children:objectAtIndex(i - 1)
		end

		if parent then
			if name == parent:getName() then
				return parent
			end
		end
	end

	for i=1, childCount do
		if "table" == type(children) then
			parent = children[i]
		elseif "userdata" == type(children) then
			parent = children:objectAtIndex(i - 1)
		end

		if parent then
			findNode = ui.seekNodeByName(parent, name)
			if findNode then
				return findNode
			end
		end
	end

	return
end

--data{pos = cc.p(250,613),norPic="a_vip_t.png",selPic="a_vip_t.png",disPic="",scale=0.65,anchor=cc.p(0, 0),procity=-2
--     ,font={txt="",size=12,name="",color=cc.c3b(255, 241, 202),pos=cc.p(250,613)}}
function ui.createButton(data,pListener)
	local btn = ccui.Button:create()
	if data.procity then
		btn:setTouchEnabled(true,data.procity)
	else
		btn:setTouchEnabled(true)
	end
	local disPic = ""
	if data.disPic then
		disPic = data.disPic
	end
	btn:loadTextures(data.norPic, data.selPic, disPic)
	if pListener then
		btn:addTouchEventListener(pListener)
	end
	if data.anchor then
		btn:setAnchorPoint(data.anchor)
	end
	if data.pos then
		btn:setPosition(data.pos)
	end
	if data.scale then
		btn:setScale(data.scale)
	end
	if data.font then
		local btnSize = btn:getContentSize()
		local fontSize = 25
		if data.font.size then
			fontSize = data.font.size
		end
		local fontColor = cc.c3b(0, 0, 0)
		if data.font.color then
			fontColor = data.font.color
		end
		local fontPos = cc.p(btnSize.width/2, btnSize.height/2-2)
		if data.font.pos then
			fontPos.x = fontPos.x + data.font.pos.x
			fontPos.y = fontPos.y + data.font.pos.y
		end
		local lbl
		if is_CCUI_TEXT then
			lbl = ui.createLabel({txt=data.font.txt,size=fontSize,color=fontColor,pos=fontPos,fontName=FONT.HEI})
		else
			lbl = ui.createText({txt=data.font.txt,size=fontSize,color=fontColor,pos=fontPos,fontName=FONT.HEI})
		end
		btn.lbl = lbl
		btn:addChild(lbl)
	end
	if data.parent then
		if data.z then
			data.parent:addChild(btn, data.z)
		else
			data.parent:addChild(btn)
		end
	end
	btn:setZoomScale(-0.1)
	btn:setPressedActionEnabled(true)
	return btn
end