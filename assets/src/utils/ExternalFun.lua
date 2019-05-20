--
-- Author: zhong
-- Date: 2016-07-29 12:01:42
--

--[[
* 通用扩展
]]
local ExternalFun = {}

--枚举声明
function ExternalFun.declarEnum( ENSTART, ... )
	local enStart = 1;
	if nil ~= ENSTART then
		enStart = ENSTART;
	end

	local args = {...};
	local enum = {};
	for i=1,#args do
		enum[args[i]] = enStart;
		enStart = enStart + 1;
	end

	return enum;
end

function ExternalFun.declarEnumWithTable( ENSTART, keyTable )
	local enStart = 1;
	if nil ~= ENSTART then
		enStart = ENSTART;
	end

	local args = keyTable;
	local enum = {};
	for i=1,#args do
		enum[args[i]] = enStart;
		enStart = enStart + 1;
	end

	return enum;
end

function ExternalFun.SAFE_RELEASE( var )
	if nil ~= var then
		var:release();
	end
end

function ExternalFun.SAFE_RETAIN( var )
	if nil ~= var then
		var:retain();
	end
end

function ExternalFun.enableBtn( btn, bEnable, bHide )
	if nil == btn then
		return
	end
	if nil == bEnable then
		bEnable = false;
	end
	if nil == bHide then
		bHide = false;
	end

	btn:setEnabled(bEnable);
	if bEnable then
		btn:setVisible(true);
		btn:setOpacity(255);
	else
		if bHide then
			btn:setVisible(false);
		else
			btn:setOpacity(125);
		end
	end
end

--格式化长整形
function ExternalFun.formatScore( llScore )
	local str = string.formatNumberThousands(llScore);
	if string.len(str) >= 4 then
		str = string.sub(str, 1, -4);
		str = (string.gsub(str, ",", ""))
		return str;
	else
		return ""
	end	
end

--无小数点 NumberThousands
function ExternalFun.numberThousands( llScore )
	local str = string.formatNumberThousands(llScore);
	if string.len(str) >= 4 then
		return string.sub(str, 1, -4)
	else
		return ""
	end	
end

local debug_mode = nil
--读取网络消息
function ExternalFun.read_datahelper( param )
	if debug_mode then
		print("read: " .. param.strkey .. " helper");
	end
	
	if nil ~= param.lentable then		
		local lentable = param.lentable;
		local depth = #lentable;

		if debug_mode then
			print("depth ==> ", depth);
		end
		
		local tmpT = {};
		for i=1,depth do
			local entryLen = lentable[i];
			if debug_mode then
				print("entryLen ==> ", entryLen);
			end
			
			local entryTable = {};
			for i=1,entryLen do
				local entry = param.fun();
				if debug_mode then					
					if type(entry) == "boolean" then
						print("value ==> ", (entry and "true" or "false"))
					else
						print("value ==> ", entry);
					end
				end

				table.insert(entryTable, entry);
			end					
			table.insert(tmpT, entryTable);
		end

		return tmpT;
	else
		if debug_mode then
			local value = param.fun();
			if type(value) == "boolean" then
				print("value ==> ", (value and "true" or "false"))
			else
				print("value ==> ", value);
			end		
			return value;
		else
			return param.fun();
		end		
	end	
end

function ExternalFun.readTableHelper( param )
	local templateTable = param.dTable or {}
	local strkey = param.strkey or "default"
	if nil ~= param.lentable then		
		local lentable = param.lentable;
		local depth = #lentable;

		if debug_mode then
			print("depth ==> ", depth);
		end
		
		local tmpT = {};
		for i=1,depth do
			local entryLen = lentable[i];
			if debug_mode then
				print("entryLen ==> ", entryLen);
			end
			
			local entryTable = {};
			for i=1,entryLen do
				local entry = ExternalFun.read_netdata(templateTable, param.buffer)
				if debug_mode then					
					dump(entry, strkey .. " ==> " .. i)
				end

				table.insert(entryTable, entry);
			end					
			table.insert(tmpT, entryTable);
		end

		return tmpT
	else
		if debug_mode then
			local value = ExternalFun.read_netdata(templateTable, param.buffer)
			dump(value,strkey )	
			return value
		else
			return ExternalFun.read_netdata(templateTable, param.buffer)
		end		
	end	
end

--[[
******
* 结构体描述
* {k = "key", t = "type", s = len, l = {}}
* k 表示字段名,对应C++结构体变量名
* t 表示字段类型,对应C++结构体变量类型
* s 针对string变量特有,描述长度
* l 针对数组特有,描述数组长度,以table形式,一维数组表示为{N},N表示数组长度,多维数组表示为{N,N},N表示数组长度
* d 针对table类型,即该字段为一个table类型,d表示该字段需要读取的table数据
* ptr 针对数组,此时s必须为实际长度

** egg
* 取数据的时候,针对一维数组,假如有字段描述为 {k = "a", t = "byte", l = {3}}
* 则表示为 变量a为一个byte型数组,长度为3
* 取第一个值的方式为 a[1][1],第二个值a[1][2],依此类推

* 取数据的时候,针对二维数组,假如有字段描述为 {k = "a", t = "byte", l = {3,3}}
* 则表示为 变量a为一个byte型二维数组,长度都为3
* 则取第一个数组的第一个数据的方式为 a[1][1], 取第二个数组的第一个数据的方式为 a[2][1]
******
]]
--读取网络消息
function ExternalFun.read_netdata( keyTable, dataBuffer )
	if type(keyTable) ~= "table" then
		return {}
	end
	local cmd_table = {};

	--辅助读取int64
    local int64 = Integer64.new();
	for k,v in pairs(keyTable) do
		local keys = v;

		------
		--读取数据
		--类型
		local keyType = string.lower(keys["t"]);
		--键
		local key = keys["k"];
		--长度
		local lenT = keys["l"];
		local keyFun = nil;
		if "byte" == keyType then
			keyFun = function() return dataBuffer:readbyte(); end
		elseif "int" == keyType then
			keyFun = function() return dataBuffer:readint(); end
		elseif "word" == keyType then
			keyFun = function() return  dataBuffer:readword(); end
		elseif "dword" == keyType then
			keyFun = function() return  dataBuffer:readdword(); end
		elseif "score" == keyType then
			keyFun = function() return  dataBuffer:readscore(int64):getvalue(); end
		elseif "string" == keyType then
			if nil ~= keys["s"] then
				keyFun = function() return  dataBuffer:readstring(keys["s"]); end
			else
				keyFun = function() return  dataBuffer:readstring(); end
			end			
		elseif "bool" == keyType then
			keyFun = function() return  dataBuffer:readbool(); end
		elseif "table" == keyType then
			cmd_table[key] = ExternalFun.readTableHelper({dTable = keys["d"], lentable = lenT, buffer = dataBuffer, strkey = key})
		elseif "double" == keyType then
			keyFun = function() return  dataBuffer:readdouble(); end
		elseif "float" == keyType then
			keyFun = function() return  dataBuffer:readfloat(); end
		elseif "short" == keyType then
			keyFun = function() return  dataBuffer:readshort(); end
		else
			print("read_netdata error: key ==> type==>", key, keyType);
			error("read_netdata error: key ==> type==>", key, keyType)
		end
		if nil ~= keyFun then
			cmd_table[key] = ExternalFun.read_datahelper({strkey = key, lentable = lenT, fun = keyFun});
		end
	end
	return cmd_table;
end

--创建网络消息包
function ExternalFun.create_netdata( keyTable )
	if type(keyTable) ~= "table" then
		print("create auto len")
		return CCmd_Data:create()
	end
	local len = 0;
	for i=1,#keyTable do
		local keys = keyTable[i];
		local keyType = string.lower(keys["t"]);

		--todo 数组长度计算
		local keyLen = 0;
		if "byte" == keyType or "bool" == keyType then
			keyLen = 1;
		elseif "score" == keyType or "double" == keyType then
			keyLen = 8;
		elseif "word" == keyType or "short" == keyType then
			keyLen = 2;
		elseif "dword" == keyType or "int" == keyType or "float" == keyType then
			keyLen = 4;
		elseif "string" == keyType then
			keyLen = keys["s"];
		elseif "tchar" == keyType then
			keyLen = keys["s"] * 2
		elseif "ptr" == keyType then
			keyLen = keys["s"]
		else
			print("error keytype ==> ", keyType);
		end

		len = len + keyLen;
	end
	print("net len ==> ", len)
	return CCmd_Data:create(len);
end

--导入包
function ExternalFun.req_var( module_name )
	if (nil ~= module_name) and ("string" == type(module_name)) then
		return require(module_name);
	end
end

--加载界面根节点，设置缩放达到适配
function ExternalFun.loadRootCSB( csbFile, parent )
	local rootlayer = ccui.Layout:create()
		:setContentSize(1335,750) --这个是资源设计尺寸
		:setScale(yl.WIDTH / 1335);
	if nil ~= parent then
		parent:addChild(rootlayer);
	end

	local csbnode = cc.CSLoader:createNode(csbFile);
	rootlayer:addChild(csbnode);

	return rootlayer, csbnode;
end

--加载csb资源
function ExternalFun.loadCSB( csbFile, parent )
	local csbnode = cc.CSLoader:createNode(csbFile);
	if nil ~= parent then
		parent:addChild(csbnode);
	end
	return csbnode;	
end

--加载 帧动画
function ExternalFun.loadTimeLine( csbFile )
	return cc.CSLoader:createTimeline(csbFile);	 
end

--注册node事件
function ExternalFun.registerNodeEvent( node )
	if nil == node then
		return
	end
	local function onNodeEvent( event )
		if event == "enter" and nil ~= node.onEnter then
			node:onEnter()
		elseif event == "enterTransitionFinish" 
			and nil ~= node.onEnterTransitionFinish then
			node:onEnterTransitionFinish()
		elseif event == "exitTransitionStart" 
			and nil ~= node.onExitTransitionStart then
			node:onExitTransitionStart()
		elseif event == "exit" and nil ~= node.onExit then
			node:onExit()
		elseif event == "cleanup" and nil ~= node.onCleanup then
			node:onCleanup()
		end
	end

	node:registerScriptHandler(onNodeEvent)
end

--注册touch事件
function ExternalFun.registerTouchEvent( node, bSwallow )
	if nil == node then
		return false
	end
	local function onNodeEvent( event )
		if event == "enter" and nil ~= node.onEnter then
			node:onEnter()
		elseif event == "enterTransitionFinish" then
			--注册触摸
			local function onTouchBegan( touch, event )
				if nil == node.onTouchBegan then
					return false
				end
				return node:onTouchBegan(touch, event)
			end

			local function onTouchMoved(touch, event)
				if nil ~= node.onTouchMoved then
					node:onTouchMoved(touch, event)
				end
			end

			local function onTouchEnded( touch, event )
				if nil ~= node.onTouchEnded then
					node:onTouchEnded(touch, event)
				end       
			end

			local listener = cc.EventListenerTouchOneByOne:create()
			bSwallow = bSwallow or false
			listener:setSwallowTouches(bSwallow)
			node._listener = listener
		    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
		    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
		    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
		    local eventDispatcher = node:getEventDispatcher()
		    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)

			if nil ~= node.onEnterTransitionFinish then
				node:onEnterTransitionFinish()
			end
		elseif event == "exitTransitionStart" 
			and nil ~= node.onExitTransitionStart then
			node:onExitTransitionStart()
		elseif event == "exit" then	
			if nil ~= node._listener then
				local eventDispatcher = node:getEventDispatcher()
				eventDispatcher:removeEventListener(node._listener)
			end			

			if nil ~= node.onExit then
				node:onExit()
			end
		elseif event == "cleanup" and nil ~= node.onCleanup then
			node:onCleanup()
		end
	end
	node:registerScriptHandler(onNodeEvent)
	return true
end

local filterLexicon = {}
--加载屏蔽词库
function ExternalFun.loadLexicon( )
	local startTime = os.clock()
	local str = cc.FileUtils:getInstance():getStringFromFile("public/badwords.txt")

	if "{" ~= string.sub(str, 1, 1) or "}" ~= string.sub(str, -1, -1) then
		print("[WARN] load lexicon error!!!")
		return
	end
	str = "return" .. str
	local fuc = loadstring(str)
	
	if nil ~= fuc and type(fuc) == "function" then
		filterLexicon = fuc()
	end
	local endTime = os.clock()
	print("load time ==> " .. endTime - startTime)
end
ExternalFun.loadLexicon()

--判断是否包含过滤词
function ExternalFun.isContainBadWords( str )
	local startTime = os.clock()

	print("origin ==> " .. str)
	--特殊字符过滤
	str = string.gsub(str, "[%w '|/?·`,;.~!@#$%^&*()-_。，、+]", "")
	print("gsub ==> " .. str)
	--是否直接为敏感字符
	local res = filterLexicon[str]
	--是否包含
	for k,v in pairs(filterLexicon)	do
		local b,e = string.find(str, k)
		if nil ~= b or nil ~= e then
			res = true
			break
		end
	end

	local endTime = os.clock()
	print("excute time ==> " .. endTime - startTime)

	return res ~= nil
end

--utf8字符串分割为单个字符
function ExternalFun.utf8StringSplit( str )
	local strTable = {}
	for uchar in string.gfind(str, "[%z\1-\127\194-\244][\128-\191]*") do
		strTable[#strTable+1] = uchar
	end
	return strTable
end

function ExternalFun.replaceAll(src, regex, replacement)
	return string.gsub(src, regex, replacement)
end

function ExternalFun.cleanZero(s)
	-- 如果传入的是空串则继续返回空串
    if"" == s then    
        return ""
    end

    -- 字符串中存在多个'零'在一起的时候只读出一个'零'，并省略多余的单位
    
    local regex1 = {"零仟", "零佰", "零拾"}
    local regex2 = {"零亿", "零万", "零元"}
    local regex3 = {"亿", "万", "元"}
    local regex4 = {"零角", "零分"}
    
    -- 第一轮转换把 "零仟", 零佰","零拾"等字符串替换成一个"零"
    for i = 1, 3 do    
        s = ExternalFun.replaceAll(s, regex1[i], "零")
    end

    -- 第二轮转换考虑 "零亿","零万","零元"等情况
    -- "亿","万","元"这些单位有些情况是不能省的，需要保留下来
    for i = 1, 3 do
        -- 当第一轮转换过后有可能有很多个零叠在一起
        -- 要把很多个重复的零变成一个零
        s = ExternalFun.replaceAll(s, "零零零", "零")
        s = ExternalFun.replaceAll(s, "零零", "零")
        s = ExternalFun.replaceAll(s, regex2[i], regex3[i])
    end

    -- 第三轮转换把"零角","零分"字符串省略
    for i = 1, 2 do
        s = ExternalFun.replaceAll(s, regex4[i], "")
    end

    -- 当"万"到"亿"之间全部是"零"的时候，忽略"亿万"单位，只保留一个"亿"
    s = ExternalFun.replaceAll(s, "亿万", "亿")
    
    --去掉单位
    s = ExternalFun.replaceAll(s, "元", "")
    return s
end

--人民币阿拉伯数字转大写
function ExternalFun.numberTransiform(strCount)
	local big_num = {"零","壹","贰","叁","肆","伍","陆","柒","捌","玖"}
	local big_mt = {__index = function() return "" end }
	setmetatable(big_num,big_mt)
	local unit = {"元", "拾", "佰", "仟", "万",
                  --拾万位到千万位
                  "拾", "佰", "仟",
                  --亿万位到万亿位
                  "亿", "拾", "佰", "仟", "万",}
    local unit_mt = {__index = function() return "" end }
    setmetatable(unit,unit_mt)
    local tmp_str = ""
    local len = string.len(strCount)
    for i = 1, len do
    	tmp_str = tmp_str .. big_num[string.byte(strCount, i) - 47] .. unit[len - i + 1]
    end
    return ExternalFun.cleanZero(tmp_str)
end

--人民币阿拉伯数字转大写(带零)
function ExternalFun.numberTransiformEx(strCount)
	local big_num = {"零","壹","贰","叁","肆","伍","陆","柒","捌","玖"}
	local big_mt = {__index = function() return "" end }
	setmetatable(big_num,big_mt)
	local unit = {"元", "拾", "佰", "仟", "万",
                  --拾万位到千万位
                  "拾", "佰", "仟",
                  --亿万位到万亿位
                  "亿", "拾", "佰", "仟", "万",}
    local unit_mt = {__index = function() return "" end }
    setmetatable(unit,unit_mt)
    local tmp_str = ""
    local len = string.len(strCount)
    for i = 1, len do
    	tmp_str = tmp_str .. big_num[string.byte(strCount, i) - 47] .. unit[len - i + 1]
    end
    return strCount == 0 and ExternalFun.replaceAll(tmp_str, "元", "") or ExternalFun.cleanZero(tmp_str)
end

--播放音效 (根据性别不同播放不同的音效)
function ExternalFun.playSoundEffect( path, useritem )
	local sound_path = path
	if nil == useritem then
		sound_path = "sound_res/" .. path
	else
		-- 0:女/1:男
		local gender = useritem.cbGender
		sound_path = string.format("sound_res/%d/%s", gender,path)
	end
	if GlobalUserItem.bSoundAble then
		AudioEngine.playEffect(sound_path,false)
	end	
end

function ExternalFun.playClickEffect( )
	if GlobalUserItem.bSoundAble then
		AudioEngine.playEffect(cc.FileUtils:getInstance():fullPathForFilename("sound/Click.wav"),false)
	end
end
--点击游戏列表
function ExternalFun.playGameClickEffect( name )
	if GlobalUserItem.bSoundAble then
		if "default" == name then
			AudioEngine.playEffect(cc.FileUtils:getInstance():fullPathForFilename("sound/game_click.mp3"),false)
		else
			AudioEngine.playEffect(cc.FileUtils:getInstance():fullPathForFilename("sound/"..name),false)
		end
		
	end
end

--播放背景音乐
function ExternalFun.playBackgroudAudio( bgfile )
	local strfile = bgfile
	if nil == bgfile then
		strfile = "backgroud.wav"
	end
	strfile = "sound_res/" .. strfile
	if GlobalUserItem.bVoiceAble then
		AudioEngine.playMusic(strfile,true)
	end	
end

--播放背景音乐
function ExternalFun.playBackgroudMusic(bgfile)
	local strfile = bgfile
	if nil == bgfile then
		strfile = "sound_res/backgroud.wav"
	end
	if GlobalUserItem.bVoiceAble then
		AudioEngine.playMusic(strfile,true)
	end	
end

--播放大厅背景音乐
function ExternalFun.playPlazzBackgroudAudio( )
	if GlobalUserItem.bVoiceAble then
		AudioEngine.playMusic(cc.FileUtils:getInstance():fullPathForFilename("sound/bg.mp3"),true)
	end
end

--中文长度计算(同步pc,中文长度为2)
function ExternalFun.stringLen(szText)
	local len = 0
	local i = 1
	while true do
		local cur = string.sub(szText,i,i)
		local byte = string.byte(cur)
		if byte == nil then
			break
		end
		if byte > 128 then
			i = i + 3
			len = len + 2
		else
			i = i + 1
			len = len + 1
		end
	end
	return len
end

--webview 可见设置(已知在4s设备上设置可见会引发bug)
function ExternalFun.visibleWebView(webview, visible)
	if nil == webview then
		return
	end

	local target = cc.Application:getInstance():getTargetPlatform()
	if target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
		local size = cc.Director:getInstance():getOpenGLView():getFrameSize()
		local con = math.max(size.width, size.height)
		if con ~= 960 then
	        webview:setVisible(visible)
	        return true
	    end
	else
		webview:setVisible(visible)
		return true
	end	
	return false
end

-- 过滤emoji表情
-- 编码为 226 的emoji字符,不确定是否是某个中文字符
-- [%z\48-\57\64-\126\226-\233][\128-\191] 正则匹配式去除了226
function ExternalFun.filterEmoji(str)
	local newstr = ""
	print(string.byte(str))
	for unchar in string.gfind(str, "[%z\25-\57\64-\126\227-\240][\128-\191]*") do
		newstr = newstr .. unchar
	end
	print(newstr)
	return newstr
end

-- 判断是否包含emoji
-- 编码为 226 的emoji字符,不确定是否是某个中文字符
function ExternalFun.isContainEmoji(str)
	if nil ~= containEmoji then
		return containEmoji(str)
	end
	local origincount = string.utf8len(str)
	print("origin " .. origincount)
	local count = 0
	for unchar in string.gfind(str, "[%z\25-\57\64-\126\227-\240][\128-\191]*") do
		--[[print(string.len(unchar))
		print(string.byte(unchar))]]
		if string.len(unchar) < 4 then
			count = count + 1
		end		
	end
	print("newcount " .. count)
	return count ~= origincount
end

local TouchFilter = class("TouchFilter", function(showTime, autohide, msg)
		return display.newLayer(cc.c4b(0, 0, 0, 0))
	end)
function TouchFilter:ctor(showTime, autohide, msg)
	ExternalFun.registerTouchEvent(self, true)
	showTime = showTime or 2
	self.m_msgTime = showTime
	if autohide then			
		self:runAction(cc.Sequence:create(cc.DelayTime:create(showTime), cc.RemoveSelf:create(true)))
	end	
	self.m_filterMsg = msg
end

function TouchFilter:onTouchBegan(touch, event)
	return self:isVisible()
end

function TouchFilter:onTouchEnded(touch, event)
	print("TouchFilter:onTouchEnded")
	if type(self.m_filterMsg) == "string" and "" ~= self.m_filterMsg then
		showToast(self, self.m_filterMsg, self.m_msgTime)
	end
end

local TOUCH_FILTER_NAME = "__touch_filter_node_name__"
--触摸过滤
function ExternalFun.popupTouchFilter( showTime, autohide, msg, parent )
	local filter = TouchFilter:create(showTime, autohide, msg)
	local runScene = parent or cc.Director:getInstance():getRunningScene()
	if nil ~= runScene then
		local lastfilter = runScene:getChildByName(TOUCH_FILTER_NAME)
		if nil ~= lastfilter then
			lastfilter:stopAllActions()
			lastfilter:removeFromParent()
		end
		if nil ~= filter then
			filter:setName(TOUCH_FILTER_NAME)
			runScene:addChild(filter, yl.ZORDER.Z_FILTER_LAYER)
		end
	end
end

function ExternalFun.dismissTouchFilter()
	local runScene = cc.Director:getInstance():getRunningScene()
	if nil ~= runScene then
		local filter = runScene:getChildByName(TOUCH_FILTER_NAME)
		if nil ~= filter then
			filter:stopAllActions()
			filter:removeFromParent()
		end
	end
end

-- eg: 10000 转 1.0万
function ExternalFun.formatScoreText(score)
	local scorestr = ExternalFun.formatScore(score)
	if score < 10000 then
		return scorestr
	end

	if score < 100000000 then
		scorestr = string.format("%.2f万", score / 10000)
		return scorestr
	end
	scorestr = string.format("%.2f亿", score / 100000000)
	return scorestr
end

function ExternalFun.formatScoreText_2(score)
	local scorestr = ExternalFun.formatScore(score)
	if score < 10000 then
		return scorestr
	end

	if score < 100000000 then
		scorestr = string.format("%d万", score / 10000)
		return scorestr
	end
	scorestr = string.format("%d亿", score / 100000000)
	return scorestr
end

-- 随机ip地址
local external_ip_long = 
{
	{ 607649792, 608174079 }, -- 36.56.0.0-36.63.255.255
    { 1038614528, 1039007743 }, -- 61.232.0.0-61.237.255.255
    { 1783627776, 1784676351 }, -- 106.80.0.0-106.95.255.255
    { 2035023872, 2035154943 }, -- 121.76.0.0-121.77.255.255
    { 2078801920, 2079064063 }, -- 123.232.0.0-123.235.255.255
    { -1950089216, -1948778497 }, -- 139.196.0.0-139.215.255.255
    { -1425539072, -1425014785 }, -- 171.8.0.0-171.15.255.255
    { -1236271104, -1235419137 }, -- 182.80.0.0-182.92.255.255
    { -770113536, -768606209 }, -- 210.25.0.0-210.47.255.255
    { -569376768, -564133889 }, -- 222.16.0.0-222.95.255.255
}
function ExternalFun.random_longip()
	local rand_key = math.random(1, 10)
	local bengin_long = external_ip_long[rand_key][1] or 0
	local end_long = external_ip_long[rand_key][2] or 0
	return math.random(bengin_long, end_long)
end

function ExternalFun.long2ip( value )
	if not value then
		return {p=0,m=0,s=0,b=0}
	end
	if nil == bit then
		print("not support bit module")
		return {p=0,m=0,s=0,b=0}
	end
	local tmp 
	if type(value) ~= "number" then
		tmp = tonumber(value)
	else
		tmp = value
	end
	return
	{
		p = bit.rshift(bit.band(tmp,0xFF000000),24),
		m = bit.rshift(bit.band(tmp,0x00FF0000),16),
		s = bit.rshift(bit.band(tmp,0x0000FF00),8),
		b = bit.band(tmp,0x000000FF)
	}
end

function string.getConfig(fontfile,fontsize)
    local config = {}
    local tmpEN = cc.LabelTTF:create("A", fontfile, fontsize)
    local tmpCN = cc.LabelTTF:create("网", fontfile, fontsize)
    local tmpen = cc.LabelTTF:create("a", fontfile, fontsize)
    local tmpNu = cc.LabelTTF:create("2", fontfile, fontsize)
    config.upperEnSize = tmpEN:getContentSize().width
    config.cnSize = tmpCN:getContentSize().width
    config.lowerEnSize = tmpen:getContentSize().width
    config.numSize = tmpNu:getContentSize().width
    return config
end

function string.EllipsisByConfig(szText, maxWidth,config)
    if not config then
        return szText
    end
    --当前计算宽度
    local width = 0
    --截断结果
    local szResult = "..."
    --完成判断
    local bOK = false
     
    local i = 1

    local endwidth = 3*config.numSize
     
    while true do
        local cur = string.sub(szText,i,i)
        local byte = string.byte(cur)
        if byte == nil then
            break
        end
        if byte > 128 then
            if width <= maxWidth - endwidth then
                width = width + config.cnSize
                i = i + 3
            else
                bOK = true
                break
            end
        elseif  byte ~= 32 then
            if width <= maxWidth - endwidth then
                if string.byte('A') <= byte and byte <= string.byte('Z') then
                    width = width + config.upperEnSize
                elseif string.byte('a') <= byte and byte <= string.byte('z') then
                    width = width + config.lowerEnSize
                else
                    width = width + config.numSize
                end
                i = i + 1
            else
                bOK = true
                break
            end
        else
            i = i + 1
        end
    end
     
    if i ~= 1 then
        szResult = string.sub(szText, 1, i-1)
        if(bOK) then
            szResult = szResult.."..."
        end
    end
    return szResult
end

--依据宽度截断字符
function string.stringEllipsis(szText, sizeE,sizeCN,maxWidth)
    --当前计算宽度
    local width = 0
    --截断结果
    local szResult = "..."
    --完成判断
    local bOK = false
     
    local i = 1
     
    while true do
        local cur = string.sub(szText,i,i)
        local byte = string.byte(cur)
        if byte == nil then
            break
        end
        if byte > 128 then
            if width <= maxWidth - 3*sizeE then
                width = width + sizeCN
                i = i + 3
            else
                bOK = true
                break
            end
        elseif  byte ~= 32 then
            if width <= maxWidth - 3*sizeE then
                width = width +sizeE
                i = i + 1
            else
                bOK = true
                break
            end
        else
            i = i + 1
        end
    end
     
    if i ~= 1 then
        szResult = string.sub(szText, 1, i-1)
        if(bOK) then
            szResult = szResult.."..."
        end
    end
    return szResult
end

-- 获取余数
function math.mod(a, b)
    return a - math.floor(a/b)*b
end

function string.formatNumberThousands(num,dot,flag)

    local formatted 
    if not dot then
        formatted = string.format("%0.2f",tonumber(num))
    else
        formatted = tonumber(num)
    end
    local sp
    if not flag then
        sp = ","
    else
        sp = flag
    end
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1'..sp..'%2')
        if k == 0 then break end
    end
    return formatted
end

-- 下标组合
local tabCombinations = {}
-- param[num] 
-- param[need] 
function ExternalFun.idx_combine( num, need, bSort )
	if type(num) ~= "number" or type(need) ~= "number" then
		print("param invalid")
		return {}
	end
	bSort = bSort or false
	local key = string.format("%d_combine_%d_bsort_%s", num, need, tostring(bSort))
	if nil ~= tabCombinations[key] then
		return tabCombinations[key]
	end

	-- 排序下标
	local key_idx = {}
	if bSort then
		for i = 1, num do
			key_idx[i] = num - i + 1
		end
	end
	local combs = {}
    local comb = {}
    local function _combine( m, k )
    	for i = m, k, -1 do
    		comb[k] = i
    		if k > 1 then
    			_combine(i - 1, k - 1)
    		else
    			local tmp = {}
    			if bSort then
    				for k, v in pairs(comb) do
	    				table.insert(tmp, 1, key_idx[v])
	    			end
    			else
    				tmp = clone(comb)
    			end
    			table.insert(combs, tmp)
    		end
    	end
    end
    _combine( num, need )

    if 0 ~= #combs then
    	tabCombinations[key] = combs
    end
    return combs
end

-- 获取文件名
function ExternalFun.getFileName(filename)
	if nil == filename then
		return ""
	end
    return string.match(string.gsub(filename, "\\", "/"), ".+/([^/]*%.%w+)$")
end

-- 获取扩展名
function ExternalFun.getExtension(filename)
    return filename:match(".+%.(%w+)$")
end

-- 排序规则
function ExternalFun.sortRule( a, b )
	if type(a) ~= "number" or type(b) ~= "number" then
		print("sort param invalid ", a, b)
		return false
	end
	return a < b
end

--转化为万
function ExternalFun.formatScoreText(score)
    local scorestr = ExternalFun.formatScore(score)
    if score > -10000  and   score < 10000  then
        return scorestr
    end
    if score > 0 then
        if score < 100000000 then
            scorestr = string.format("%.2f万", score / 10000)
            return scorestr
        end
        scorestr = string.format("%.2f亿", score / 100000000)
    elseif score < 0 then
        if score < -100000000 then
            scorestr = string.format("%.2f亿", score / 100000000)
            return scorestr
        end
        scorestr = string.format("%.2f万", score / 10000)
    end
    return scorestr
end

--创建节点尺寸调试框
function ExternalFun.createDebugBox(obj,fillColor,outlineColor,outlineWidth)
    local fColor = fillColor or cc.c4f(1,0,0,0.2)
    local oColor = outlineColor or cc.c4f(0,1,0,0.6)
    local oWidth = outlineWidth or 1
    local objSize = obj:getContentSize()
    local drawNode = cc.DrawNode:create()
    obj:addChild(drawNode,1000)
    local points = {
        cc.p(0,0),
        cc.p(objSize.width, 0),
        cc.p(objSize.width, objSize.height),
        cc.p(0, objSize.height)
    }
    drawNode:drawPolygon(points, #points, fColor, oWidth, oColor)
end

--根据rect创建尺寸调试框
function ExternalFun.createDebugBoxByRect(obj,rect,fillColor,outlineColor,outlineWidth)
    local fColor = fillColor or cc.c4f(1,0,0,0.2)
    local oColor = outlineColor or cc.c4f(0,1,0,0.6)
    local oWidth = outlineWidth or 1
    local drawNode = cc.DrawNode:create()
    obj:addChild(drawNode,1000)
    local points = {
        cc.p(rect.x,rect.y),
        cc.p(rect.x + rect.width, rect.y),
        cc.p(rect.x + rect.width, rect.y + rect.height),
        cc.p(rect.x, rect.y + rect.height)
    }
    drawNode:drawPolygon(points, #points, fColor, oWidth, oColor)
end

--------------------------------------------------------------------------------------
-- @name ExternalFun.getByteCount
-- @description 获取字符字节数(字符)
-- @param byteStr 字符
-- @return 字节数
--------------------------------------------------------------------------------------
function ExternalFun.getByteCount(byteStr)
    local byteCount = 0
    if byteStr >= 0 and byteStr <= 127 then
        byteCount = 1
        -- 1字节字符
    elseif byteStr >= 192 and byteStr <= 223 then
        byteCount = 2
        -- 双字节字符
    elseif byteStr >= 224 and byteStr <= 239 then
        byteCount = 3
        -- 汉字
    elseif byteStr >= 240 and byteStr <= 247 then
        byteCount = 4
        -- 4字节字符
    end
    return byteCount
end

--------------------------------------------------------------------------------------
-- @name ExternalFun.createText
-- @description 创建显示文字
-- @param fontStr 显示文本（默认为""）
-- @param fontSize 文字尺寸（默认为18）
-- @param fontColor 文字颜色（默认为cc.c3b(0, 0, 0)）
-- @param anchorPoint 文字锚点（默认为cc.p(0.5, 0.5)）
-- @param fontName 文字名称（默认为"Microsoft Yahei"）
-- @return 创建后的文字
--------------------------------------------------------------------------------------
function ExternalFun.createText(fontStr, fontSize, fontColor, anchorPoint, fontName)
    local fStr = fontStr or ""
    local fSize = fontSize or 18
    local fColor = fontColor or cc.c3b(0, 0, 0)
    local aPoint = anchorPoint or cc.p(0.5, 0.5)
    local fName = fontName or "Microsoft Yahei"
    local textLabel = ccui.Text:create()
    textLabel:setString(fStr)
    textLabel:setFontSize(fSize)
    textLabel:setTextColor(fColor)
    textLabel:setAnchorPoint(aPoint)
    textLabel:setFontName(fName)
    return textLabel
end

--------------------------------------------------------------------------------------
-- @name ExternalFun.subStringByWidth
-- @description 根据需要最大宽度截取字符串长度
-- @param strOrg 源字符串
-- @param maxWidth 最大宽度（包含后缀宽度）
-- @param suffix 后缀（默认为""）
-- @param fontSize 字体大小（默认为20）
-- @param fontName 字体名称（默认为"fonts/msyhbd.ttf"）
-- @return 截取后的字符串
--------------------------------------------------------------------------------------
function ExternalFun.subStringByWidth(strOrg, maxWidth, suffix, fontSize, fontName)
    local strRet = strOrg or ''
    strRet = tostring(strRet)
    local lenInByte = #strRet
    local setFontSize = fontSize or 20
    local setFontName = fontName or ''
    local backSuffix = suffix or ''
    local width = 0
    local suffixWidth = 0
    local strBack = ''
    local strOrgText = ExternalFun.createText(strOrg, setFontSize, nil, nil, setFontName)
    if strOrgText:getContentSize().width > maxWidth then
        local j = 1
        --计算后缀长度
        while
            (j <= #backSuffix)
        do
            local curByte = string.byte(backSuffix, j)
            local byteCount = ExternalFun.getByteCount(curByte)
            local char = string.sub(backSuffix, j, j + byteCount - 1)
            j = j + byteCount
            local fontText = ExternalFun.createText(char, setFontSize, nil, nil, setFontName)
            suffixWidth = suffixWidth + fontText:getContentSize().width
        end
        --总长度减去后缀长度
        maxWidth = maxWidth - suffixWidth
    end
    local i = 1
    --获取最终字符串
    while
        (i <= lenInByte)
    do
        local curByte = string.byte(strRet, i)
        local byteCount = ExternalFun.getByteCount(curByte)
        local char = string.sub(strRet, i, i + byteCount - 1)
        i = i + byteCount
        --计算单字宽度
        local fontText = ExternalFun.createText(char, setFontSize, nil, nil, setFontName)
        width = width + fontText:getContentSize().width
        if width > maxWidth then
            break
        end
        strBack = strBack .. char
    end
    --添加后缀
    if strBack ~= strRet then
        strBack = strBack .. backSuffix
    end
    return strBack
end


--------------------------------------------------------------------------------------
-- @name ExternalFun.addEffectNode
-- @description 添加特效
-- @param parentNode 父节点
-- @param prePath 文件地址前缀
-- @param fileName 文件名
-- @param pos 位置
-- @param name 设置名称（方便父节点获取）
-- @param fristIdx 起始帧
-- @param aniName 动作名称
-- @param isLoop 是否循环
-- @return 特效节点
--------------------------------------------------------------------------------------
function ExternalFun.addEffectNode(parentNode, prePath, fileName, pos, name, fristIdx, aniName, isLoop)
    name = name or 'effectNode'
    fristIdx = fristIdx or 0
    aniName = aniName or 'animation'

    local setLoop = true
    if isLoop ~= nil then
        setLoop = isLoop
    end

    local jsonName = string.format('%s%s/%s.json', prePath, fileName, fileName)
    local atlasName = string.format('%s%s/%s.atlas', prePath, fileName, fileName)
    local effectNode = sp.SkeletonAnimation:create(jsonName, atlasName, 1.0)
    :setPosition(pos)
    :addTo(parentNode)
    :setAnimation(fristIdx, aniName, setLoop)
    :setName(name)

    return effectNode
end


--------------------------------------------------------------------------------------
-- @name ExternalFun.addEffectNodeButton
-- @description 添加特效按钮
-- @param parentNode 父节点
-- @param prePath 文件地址前缀
-- @param fileName 文件名
-- @param buttonSize 按钮尺寸
-- @param buttonPos 按钮位置
-- @param effectPos 特效位置
-- @param callBack 点击后回调
-- @param unPlayCommonEffect 点击不播放音效（部分按钮会播放其他点击音效）
-- @return 特效按钮节点
--------------------------------------------------------------------------------------
function ExternalFun.addEffectNodeButton(parentNode, prePath, fileName, buttonSize, buttonPos, effectPos, callBack, unPlayCommonEffect)
    local effectButton = ccui.Button:create()
    effectButton.canClick = true
    effectButton:setAnchorPoint(cc.p(0.5, 0.5))
    effectButton:ignoreContentAdaptWithSize(true)
    effectButton:setContentSize(buttonSize)
    effectButton:setScale9Enabled(true)
    :addTo(parentNode)
    :setPosition(buttonPos)
    :addTouchEventListener(function(ref, type)
        if type == ccui.TouchEventType.ended then
            if not ref.canClick then return end
            ref.canClick = false
            local clickDelayTime = cc.DelayTime:create(0.3)
            local setClick = cc.CallFunc:create(function ()
                if not tolua.isnull(ref) then
                    ref.canClick = true
                end
            end)
            local seq = cc.Sequence:create(clickDelayTime, setClick)
            ref:runAction(seq)
            
            if not unPlayCommonEffect then
                ExternalFun.playCommonButtonClickEffect()
            end
            local effectNode = effectButton:getChildByName('effectNode')
            if not tolua.isnull(effectNode) then
                effectNode:stopAllActions()
                effectNode:setScale(1.0)
                local scaleBig = cc.ScaleTo:create(0.05, 1.02)
                local scaleSrc = cc.ScaleTo:create(0.05, 1.0)
                local callFun = cc.CallFunc:create(function()
                    if callBack then
                        callBack()
                    end
                end)
                local seq = cc.Sequence:create(scaleBig, scaleSrc, callFun)
                effectNode:runAction(seq)
            end
            return true
        end
    end)
    
    ExternalFun.addEffectNode(effectButton, prePath, fileName, effectPos)

    return effectButton
end



--------------------------------------------------------------------------------------
-- @name ExternalFun.getHeadImage
-- @description 获取头像
-- @param useritem 用户数据
-- @return 头像节点
--------------------------------------------------------------------------------------
function ExternalFun.getHeadImage(useritem)
    local MAX_HEAD_INDEX = 5
    local faceid = useritem.wFaceID or 0
    if useritem.wFaceID > MAX_HEAD_INDEX then
		faceid = useritem.wFaceID % (MAX_HEAD_INDEX + 1)
	end
    local headImage = nil
    local str = string.format("Avatar%d.png", faceid)
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(str)
	if nil ~= frame then
		headImage = cc.Sprite:createWithSpriteFrame(frame)
	end
    return headImage
end


--获取裁切头像
function ExternalFun.getClipHeadImage(useritem, clippingfile)
	if nil == useritem then return end
    local headImage = ExternalFun.getHeadImage(useritem)
    if tolua.isnull(headImage) then return end

	--创建裁剪
	local clipSp = nil
    local clip = nil
	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(clippingfile)
	if nil ~= frame then
		clipSp = cc.Sprite:createWithSpriteFrame(frame)
	else
		clipSp = cc.Sprite:create(clippingfile)
	end
    
	if nil ~= clipSp then
        local headImageSize = headImage:getContentSize()
        local clipSpSize = clipSp:getContentSize()
        local scaleX = clipSpSize.width/headImageSize.width
        local scaleY = clipSpSize.height/headImageSize.height
        headImage:setScale(scaleX, scaleY)
		--裁剪
		clip = cc.ClippingNode:create()
		clip:setStencil(clipSp)
--		clip:setAlphaThreshold(1.0)
        clip:setInverted(false)
		clip:addChild(headImage)
	end
    return clip
end



--创建一个Layout按钮
function ExternalFun.createLayoutButton(parentNode, size, pos, callBack)
    local layoutButton = ccui.Layout:create()
    :setAnchorPoint(cc.p(0.5, 0.5))
    :setContentSize(size)
    :setPosition(pos)
    :addTo(parentNode)
--    :setBackGroundColorType(LAYOUT_COLOR_SOLID)
--    :setBackGroundColor(cc.c4b(255,0,0,10))
    layoutButton:setCascadeOpacityEnabled(true)

    local function touchCallBack(event)
        if event.name == "ended" then
            ExternalFun.playCommonButtonClickEffect()
            if not tolua.isnull(layoutButton) then
                layoutButton:stopAllActions()
                layoutButton:setScale(1.0)
                local scaleBig = cc.ScaleTo:create(0.05, 1.05)
                local scaleSrc = cc.ScaleTo:create(0.05, 1.0)
                local callFun = cc.CallFunc:create(function()
                    if callBack then
                        callBack()
                    end
                end)
                layoutButton:setTouchEnabled(false)
                local timeDelay = cc.DelayTime:create(0.5)
                local callFun2 = cc.CallFunc:create(function()
                    layoutButton:setTouchEnabled(true)
                end)
                local seq = cc.Sequence:create(scaleBig, scaleSrc, callFun, timeDelay, callFun2)
                layoutButton:runAction(seq)
            end
        end
    end

    layoutButton:setTouchEnabled(true)
    layoutButton:onTouch(touchCallBack)

    return layoutButton
end


--添加Layout按钮图标
function ExternalFun.addLayoutButtonIocn(parentNode, iconPath, textPicPath)
    local parentNodeSize = parentNode:getContentSize()

    local icon = display.newSprite(iconPath)
    :setPosition(parentNodeSize.width/2, parentNodeSize.height/2 + 10)
    :addTo(parentNode)

    local textPic = display.newSprite(textPicPath)
    :setPosition(parentNodeSize.width/2, 10)
    :addTo(parentNode)
end

--播放按钮点击通用音效
function ExternalFun.playCommonButtonClickEffect()
	if GlobalUserItem.bSoundAble then
		AudioEngine.playEffect(cc.FileUtils:getInstance():fullPathForFilename("sound/Click.mp3"),false)
	end
end

--播放关闭按钮点击音效
function ExternalFun.playCloseButtonClickEffect()
	if GlobalUserItem.bSoundAble then
		AudioEngine.playEffect(cc.FileUtils:getInstance():fullPathForFilename("sound/Click.mp3"),false)
	end
end

--播放音效(通用)
function ExternalFun.playSoundEffectCommon(path)
	if GlobalUserItem.bSoundAble then
		AudioEngine.playEffect(cc.FileUtils:getInstance():fullPathForFilename(path),false)
	end
end

--加载夜间模式
function ExternalFun.loadNightModel(sceneNode)
    if GlobalUserItem.bAutoAble then
        GlobalUserItem.setDayAble(false)
        local isShowNight = false
        local nowDate = os.date("*t", os.time())
	    if nowDate.hour <= 6 and nowDate.hour >= 18 then
            isShowNight = true
	    end
        if not tolua.isnull(sceneNode) then
            local nightLayer = sceneNode:getChildByName('nightLayer')
            if tolua.isnull(nightLayer) then
                nightLayer = display.newLayer(cc.c4b(0, 0, 0, 76.5))
                :setPosition(0, 0)
                :addTo(sceneNode, 200)
                :setName('nightLayer')
            end
            nightLayer:setVisible(isShowNight)
        end
    else
        if not tolua.isnull(sceneNode) then
            local nightLayer = sceneNode:getChildByName('nightLayer')
            if tolua.isnull(nightLayer) then
                nightLayer = display.newLayer(cc.c4b(0, 0, 0, 76.5))
                :setPosition(0, 0)
                :addTo(sceneNode, 200)
                :setName('nightLayer')
            end
            dump(nightLayer)
            dump('11111')
            dump(not GlobalUserItem.bDayAble)
            nightLayer:setVisible(not GlobalUserItem.bDayAble)
        end
    end
end

-- spine by cgq
function ExternalFun.newAnimationSpine(pkid,name,path,timeScale)
    if timeScale == nil then
        timeScale = 1.0
	end
	if ExternalFun.spineResList == nil then
		ExternalFun.spineResList = {}
	end
	if ExternalFun.spineResList[pkid] == nil then
		ExternalFun.spineResList[pkid] = {}
	end
	local animation = sp.SkeletonAnimation:create(path..name..".json",path..name..".atlas",timeScale)
	ExternalFun.spineResList[pkid][path..name] = path..name..".png"
	-- 播放动画
	function animation:playAnimation(name,trackIndex,isLoop)
		if trackIndex == nil then
			trackIndex = 0
		end
		if isLoop == nil then
			isLoop = false
		end
		self:setToSetupPose()
		self:setAnimation(trackIndex,name,isLoop)
		return self
	end
	-- stop
	function animation:stopAnimation()
		self:clearTracks()
		return self
	end
    
    return animation
end

function ExternalFun.removeAnimationSpine(pkid)
	if ExternalFun.spineResList and ExternalFun.spineResList[pkid] then
		for key,var in pairs(ExternalFun.spineResList[pkid]) do
			cc.Director:getInstance():getTextureCache():removeTextureForKey(var)
		end
		ExternalFun.spineResList[pkid] = nil
	end
end

function ExternalFun.newTimelineToNode(file)
    local node = cc.CSLoader:createNode(file)
	local ani = cc.CSLoader:createTimeline(file)
	node.ani = ani

    -- func
    if node.playTimeline == nil then
        -- by name
        function node:playAnimation(name,isLoop,callback)
            self:stopAnimation()
			self:stopAllActions()
			self:runAction(self.ani)
			self.ani:play(name,isLoop)
			if not isLoop then
				schedule(self,function()
					if not self.ani:isPlaying() then
						self:removeFromParent()
						if callback then
							callback()
						end
					end
				end,0.1)
			end
            return self
        end
        -- by index
        function node:playAnimationByIndex(startIndex,endIndex,isLoop,callback)
            self:stopAnimation()
            self:stopAllActions()
            self:runAction(self.ani)
            self.ani:gotoFrameAndPlay(startIndex,endIndex,isLoop)
            if not isLoop then
				schedule(self,function()
					if not self.ani:isPlaying() then
						self:removeFromParent()
						if callback then
							callback()
						end
					end
				end,0.1)
			end
            return self
        end
        -- stop
        function node:stopAnimation()
            if self.ani:isPlaying() then
                self:removeFromParent()
            end
            return self
        end
    end
    
    return node
end

-- fg
function checknumber(value, base)
	return tonumber(value, base) or 0
end
function ExternalFun.formatnumberthousands(num,fg)
	local formatted = tostring(checknumber(num))
	local k
	local sf = '%1,%2'
	if fg then
		sf = '%1'..fg..'%2'
	end
	while true do
	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", sf)
	if k == 0 then break end
	end
	return formatted
end

-- 数字滚动，增减，变色 by cgq
function ExternalFun.digitalScroll(txt,changeNum,parame,callback,isPercentile)
	if txt == nil then
		return
	end
	local numper = changeNum/15
	local numperA = 15
	local color = txt:getColor()
	local isColor = parame and parame.isColor or false
	if changeNum == 0 then
		return
	elseif changeNum > 0 then
		if isColor then
			txt:setColor(cc.c3b(57,245,207))
		end
	else
		if isColor then
			txt:setColor(cc.c3b(245,57,101))
		end
		changeNum = -changeNum
	end

	local charAdd = parame and parame.charAdd or nil
	local charSub = parame and parame.charSub or nil
	local charFg = parame and parame.charFg or nil

	local str = txt:getString()
	print("--------------->1",str)
	if charFg then
		str = tonumber((string.gsub(str,charFg,"")))
	end
	local num = tonumber(str)
	if num == nil then
		num = 0
	end

	--格式化金币
local function formatGold( object, score )
    local str = string.format('%.02f',score)
    object:setString(str)
end

	-- 开启计时器1
	local function tmCallback()
		num = num+numper
		numperA = numperA-1
		if numperA <= 0 then
			txt:stopAllActions()
			if isColor then
				txt:setColor(color)
			end

			--  if num < 0 then num = 0 end

			-- 回调
			if callback then
				callback()
			end
		end
		local tonum = math.floor(num+0.5)
		local tonumO = tonum
		if charFg and tonum >= 1000 then
			tonum = ExternalFun.formatnumberthousands(tonum,charFg)
		end
		
		if charAdd and tonumO > 0 then
			tonum = ""..charAdd..tonum
		elseif charSub and tonumO < 0 then
			tonum = ""..charSub..tonum
		end

		txt:setString(tonum)
	end
	-- 开启计时器2 用于数字后面有小数点
	local function tmCallback2()
		num = num+numper
		numperA = numperA-1
		if numperA <= 0 then
			txt:stopAllActions()
			if isColor then
				txt:setColor(color)
			end

			--  if num < 0 then num = 0 end

			-- 回调
			if callback then
				callback()
			end
		end
		local tonum = math.floor(num*100+0.5)/100
		local tonumO = tonum
		
		if charAdd and tonumO > 0 then
			tonum = ""..charAdd..tonum
		elseif charSub and tonumO < 0 then
			tonum = ""..charSub..tonum
		end

		formatGold(txt, tonum)
	end
	local percentile = isPercentile
	if percentile then 
		schedule(txt,tmCallback2,0.05)
	else
		schedule(txt,tmCallback,0.05)
	end

end

-- ui open action by cgq
function ExternalFun.openLayerAction(node,callback)
    node:setScale(0.3)
    node:runAction(cc.Sequence:create(cc.ScaleTo:create(0.15,1.05),cc.ScaleTo:create(0.1,1.0),cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)))
end
function ExternalFun.closeLayerAction(node,callback)
    node:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1,1.01),cc.ScaleTo:create(0.15,0.1),cc.CallFunc:create(function()
        if callback then
            callback()
        end
    end)))
end

--创建序列帧动画
function ExternalFun.createFramesAnimation(prefix, fileName, frameName, fps, isLoop, isAutoRemove, startIdx, endIdx, waitTime)
    ExternalFun.framesCache = ExternalFun.framesCache or {}

    waitTime = waitTime or 0

    local plistName = string.format('%s%s.plist', prefix, fileName)
    local pngName = string.format('%s%s.png', prefix, fileName)

    if not ExternalFun.framesCache[fileName] then
        cc.SpriteFrameCache:getInstance():addSpriteFrames(plistName, pngName)
        ExternalFun.framesCache[fileName] = true
    end
    local framesNum = 0
    if startIdx and endIdx then
        framesNum = endIdx - startIdx + 1
    else
        local plistPath = cc.FileUtils:getInstance():fullPathForFilename(plistName)  
        local plistDict = cc.FileUtils:getInstance():getValueMapFromFile(plistPath)  
        local plistFrames = plistDict['frames']
        dump(plistFrames,"信息输出", 10)
        
        local numTable = {}
        for k,v in pairs(plistFrames) do
            local index, endindex = string.find(k, frameName)
            if index then
                local num = string.gsub(k, frameName, '')
                num = string.gsub(num, '.png', '')
                num = tonumber(num)
                table.insert(numTable, num)
            end
        end

        table.sort(numTable, function(a, b)
            return a < b
        end)
        startIdx = numTable[1]
        framesNum = #numTable
    end

    local frameFile = string.format('%s%%02d.png', frameName)
    dump(frameFile, "文件名是", 10)
    local frames = display.newFrames(frameFile, startIdx, framesNum)
    local sprite = display.newSprite('#' .. string.format(frameFile, startIdx))

    local seqTable = {}
    local animation = display.newAnimation(frames, fps)
    local act = cc.Animate:create(animation)
    local cFun = cc.CallFunc:create(function()
        print('end')
        if not tolua.isnull(sprite) then
            sprite:removeFromParent()
        end
    end)

    table.insert(seqTable, act)
    if not isLoop and isAutoRemove then
        table.insert(seqTable, cFun)
    end
    
    if waitTime ~= 0 then
        local delayTimeEnd = cc.DelayTime:create(waitTime)
        table.insert(seqTable, delayTimeEnd)
    end

    local seq = cc.Sequence:create(seqTable)
    local rep = cc.RepeatForever:create(seq)
    if isLoop then
        sprite:runAction(rep)
    else
        sprite:runAction(seq)
    end
    
    return sprite
end


function ExternalFun.StringToTable(s)  
    local tb = {}
    --[[  
    UTF8的编码规则：  
    1. 字符的第一个字节范围： 0x00—0x7F(0-127),或者 0xC2—0xF4(194-244); UTF8 是兼容 ascii 的，所以 0~127 就和 ascii 完全一致  
    2. 0xC0, 0xC1,0xF5—0xFF(192, 193 和 245-255)不会出现在UTF8编码中   
    3. 0x80—0xBF(128-191)只会出现在第二个及随后的编码中(针对多字节编码，如汉字)   
    ]]  
    for utfChar in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do  
        table.insert(tb, utfChar)  
    end
    return tb  
end
 
-- 计算字符数
function ExternalFun.GetUTFLen(s)  
    local sTable = ExternalFun.StringToTable(s)
    return #sTable  
end

-- 获取指定字符个数的字符串的实际长度
function ExternalFun.GetUTFLenWithCount(s, count)  
    local sTable = ExternalFun.StringToTable(s)
    local len = 0  
    local charLen = 0
    for i=1,#sTable do  
        local utfCharLen = string.len(sTable[i])  
        if utfCharLen > 1 then -- 长度大于1的就认为是中文  
            charLen = 2  
        else  
            charLen = 1  
        end
        len = len + utfCharLen
        count = count -1
        if count <= 0 then  
            break  
        end  
    end
    return len  
end  

-- 截取指定长度
function ExternalFun.GetMaxLenString(s, maxLen, suffix)
    local len = ExternalFun.GetUTFLen(s)  
    local backSuffix = suffix or '...'
    local dstString = s 
    if len > maxLen then  
        dstString = string.sub(s, 1, ExternalFun.GetUTFLenWithCount(s, maxLen))  
        dstString = dstString .. backSuffix
    end
    return dstString  
end  


--根据字体数、单字体宽度和最大限制宽度获取缩放比例
function ExternalFun.getScaleByMaxWidth(s, fontWidth, maxWidth)
    local len = ExternalFun.GetUTFLen(s)  
    local fixWidth = math.floor(maxWidth/len)
    if fixWidth < fontWidth then
    	local fixScale = fixWidth/fontWidth
        return fixScale - fixScale%0.01
    end
    return 1.0  
end


--创建轮播图
function ExternalFun.createRoundBanner(parentNode, pos, contentSize, pageCount, scrollTime)

	local setTime = scrollTime or 4.0

	local page = ccui.PageView:create()
	:setAnchorPoint(cc.p(0.5,0.5))
	:setContentSize(contentSize)
	:setPosition(pos)
	:addTo(parentNode)
    :setTouchEnabled(true)

	local function addPageToView(pIdx, iIdx)
	    local newPage = ccui.Layout:create()
	    newPage:setContentSize(contentSize)
	    newPage:setPosition(0,0)
	    newPage:setTag(pIdx)
	    page:insertPage(newPage, iIdx)
	end

	local pointSpace = 20
	local pointTable = {}
	for i = 1, pageCount do
		local posX = pos.x - (pageCount - 1)*(pointSpace/2) + (pointSpace)*(i - 1)
		local posY = pos.y - contentSize.height/2 + 40
		local point = ccui.Button:create('plaza/dot2.png', 'plaza/dot2.png')
        :setPosition(posX, posY)
        :addTo(parentNode, 1)
        :setName('point')
        pointTable[i] = point
	end

	local function setPointLight(itemIdx)
		local item = page:getItem(itemIdx)
		if not tolua.isnull(item) then
			local itemTag = item:getTag() == 1 and 2 or 1
			for i = 1, #pointTable do
				if i == itemTag then
					pointTable[i]:loadTextures('plaza/dot1.png', 'plaza/dot1.png')
				else
					pointTable[i]:loadTextures('plaza/dot2.png', 'plaza/dot2.png')
				end
			end
		end
	end


	local pageIdx = 1

	local pages = pageCount
	local function callback(event)
		if event.name == "TURNING" then
			local curIdx = page:getCurrentPageIndex()
			-- dump(curIdx)
			if pageIdx < curIdx then
				-- print('左移')
				if 3 == curIdx then
					page:setCurrentPageIndex(1)
					pageIdx = 1
				else
					pageIdx = curIdx
				end
			elseif pageIdx > curIdx then
				-- print('右移')
				if 0 == curIdx then
					page:setCurrentPageIndex(2)
					pageIdx = 2
				else
					pageIdx = curIdx
				end
			else
				--不变
				pageIdx = curIdx
			end
			setPointLight(pageIdx)
    	end
	end

	page:onEvent(callback)
	
	local idx = 0
	for i = 1, 2 do
		for j = 1, pageCount do
			addPageToView(j, idx)
			idx = idx + 1
		end
	end
	page:setCurrentPageIndex(pageIdx)
	setPointLight(pageIdx)
	
	local itemCount = #page:getItems()

	local function pageUpdate(dt)
		print('pageUpdate')
		if not tolua.isnull(page) then
			local curIdx = page:getCurrentPageIndex()
			local goIdx = curIdx + 1 > itemCount - 1 and itemCount - 1 or curIdx + 1
			page:scrollToItem(goIdx)
			setPointLight(goIdx)
		end
	end
	local schedulerPage = cc.Director:getInstance():getScheduler():scheduleScriptFunc(pageUpdate, setTime, false)

	return page, schedulerPage
end


--------------------------------------------------------------------------------------
-- @name ExternalFun.copyNumberAndOpenWeChat
-- @description 从字符串中复制数字并打开微信
-- @param parentNode 父节点
-- @param str 字符串
-- @param canJump 是否允许不连续（默认为截取连续数字）
--------------------------------------------------------------------------------------
function ExternalFun.copyNumberAndOpenWeChat(parentNode, str, canJump)
	local strTable = ExternalFun.utf8StringSplit(str)
	local numStr = ''
	local findIdx = 0
	for i = 1, #strTable do
		local strChar = strTable[i]
		if tonumber(strChar) then
			if findIdx~= 0 and i - findIdx >= 2 and not canJump then
				break
			end
			findIdx = i
			numStr = numStr .. strChar
		end
	end
	if numStr == '' then
		showToast(parentNode, "无可用数字!", 2)
		return
	end
	local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
    local res, msg = MultiPlatform:getInstance():copyToClipboard(numStr)
	if true == res then
		local QueryDialog = appdf.req("app.views.layer.other.QueryDialog_Ex")
		local tipStr = string.format('微信号:「%s」已拷贝，是否打开微信？', numStr)
        local pupDialog = QueryDialog:create(tipStr, function(ok)
            if ok == true then
                MultiPlatform:getInstance():openWeChat()
            end
        end)
        :setCanTouchOutside(false)
        :addTo(parentNode, 200)
	else
		showToast(parentNode, "复制失败!", 2)
	end
end


--  cjxx fix no use function
function ExternalFun.formatScoreRatioEx(str)
    return tostring(str)
end

function ExternalFun.formatScoreRatio(str)
    return tostring(str)
end

function ExternalFun.adapterWHScale(str)
    return 1.0
end



return ExternalFun