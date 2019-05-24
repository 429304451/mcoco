-- UI工具
-- Author: gaomeng.ning
-- Date: 2017-3-7
local postedLog = {}
require("utils.ui")

function ui.printCsError(path)
	trace("-----------------------------------------------")
	trace("----------------!!!!!!!!!!!!!!!----------------")
	trace("  ")
	trace("Cs Create Error!!!!!! Cs File Not Found ："..path)
	if not postedLog[path] then
		postedLog[path] = true
		util.postLogToServer("Cs Create Error!!!!!! Cs File Not Found ："..path)
	end
	trace("  ")
	trace("----------------!!!!!!!!!!!!!!!----------------")
	trace("-----------------------------------------------")
end

--创建CS节点
function ui.loadCS(path)
	local resType = string.sub(path,-4,-1)
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

--创建CS动画
function ui.loadCSTimeline(path)
	local resType = string.sub(path,-4,-1)
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

--listview创建
function ui.listViewCreate(data)
	print("错误 需要 listViewCreate BaseListView")
	-- return require("script.public.BaseListView").new(data)
end

--从csd界面转lua的界面创建
function ui.createCsb(obj)
	print("ui.createCsb", obj)
	local pathTable = string.split(obj.uipath,".")
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

--从csd界面转lua的界面创建
function ui.createCsbItem(path)
	local cabPath = string.gsub(path,"%.","/")
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
			-- print(children[i]:getName())
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
