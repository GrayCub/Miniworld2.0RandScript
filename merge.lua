--------------------元数据分割线--------------------
-- Player_data的第一层是排行榜索引（顺序），第二层是玩家的uin，值是玩家对应的排行数据
-- index是数值，1、2、3、4，它的顺序跟RankMeta是一一对应的
local Player_data = {} -- 当前云服玩家数据
local Players_extra = {} -- 当前云服玩家额外数据
local CloudData = {}   -- 云端Pull下来的数据
local Time = 10        -- 定时上传更新的时间间隔，单位秒，10、20、30，强烈推荐这三个值
local RankMeta = {     -- 排行榜元数据
    {
        rank = "rank_1763899156",
        vValue = "战力"
    },
    {
        rank = "rank_1763899173",
        vValue = "举重"
    },
    {
        rank = "rank_1763899186",
        vValue = "倍率"
    },
    {
        rank = "rank_1763899199",
        vValue = "吞噬"
    },
}
local KvMeta = "datalist_1763899229" -- 存储玩家额外数据的KV表名
local Data = {}
local player_data = {}
local id_ui = {     -- 名字序列(由上到下，不限数量)
    "7567751678838114865-36390_52",
    "7567751678838114865-36390_53",
    "7567751678838114865-36390_54",
    "7567751678838114865-36390_55",
    "7567751678838114865-36390_56",
}

local data_ui = {       -- 排序值序列(由上到下，不限数量)
    "7567751678838114865-36390_65",
    "7567751678838114865-36390_66",
    "7567751678838114865-36390_67",
    "7567751678838114865-36390_68",
    "7567751678838114865-36390_69",
}

local mini_ui = {       -- 迷你号序列(由上到下，不限数量)
    "7567751678838114865-36390_58",
    "7567751678838114865-36390_60",
    "7567751678838114865-36390_61",
    "7567751678838114865-36390_62",
    "7567751678838114865-36390_63",
}

local rand_ui = {       -- 名次序列(由上到下，不限数量)
    "7567751678838114865-36390_46",
    "7567751678838114865-36390_47",
    "7567751678838114865-36390_48",
    "7567751678838114865-36390_49",
    "7567751678838114865-36390_50",
}

local my_ui = {     -- 自己四个数据序列
    "7567751678838114865-36390_51",     --自己排名
    "7567751678838114865-36390_57",         --自己名字
    "7567751678838114865-36390_64",         --自己迷你号
    "7567751678838114865-36390_70",         --自己战力
}

local head_ui = {
    "7567751678838114865-36390_32",
    "7567751678838114865-36390_33",
    "7567751678838114865-36390_34",
    "7567751678838114865-36390_35"
}

local head_content = {
    {
        "排名",
        "名字",
        "迷你号",
        "战力"
    },
    {
        "排名",
        "名字",
        "迷你号",
        "举重"
    },
    {
        "排名",
        "名字",
        "迷你号",
        "倍率"
    },
    {
        "排名",
        "名字",
        "迷你号",
        "吞噬"
    }

}

local page_ui = {       -- 页相关
    "7567751678838114865-36390_74", -- 页码
    "7567751678838114865-36390_75", -- 左翻
    "7567751678838114865-36390_73", -- 右翻
    "已经是第一页了！",-- 左翻提示信息
    "没有更多啦！" -- 右翻提示信息
}

local convert_units = {     --单位转换(科学计数法)
    {value = 1e72,  name = "大数"},
    {value = 1e68,  name = "无量"},
    {value = 1e64,  name = "不可思议"},
    {value = 1e60,  name = "那由他"},
    {value = 1e56,  name = "阿僧祇"},
    {value = 1e52,  name = "恒河沙"},
    {value = 1e48,  name = "极"},
    {value = 1e44,  name = "载"},
    {value = 1e40,  name = "正"},
    {value = 1e36,  name = "涧"},
    {value = 1e32,  name = "沟"},
    {value = 1e28,  name = "穰"},
    {value = 1e24,  name = "秭"},
    {value = 1e20,  name = "垓"},
    {value = 1e16,  name = "京"},
    {value = 1e12,  name = "兆"},
    {value = 1e8,   name = "亿"},
    {value = 1e4,   name = "万"}
}

local ui = "7567751678838114865-36390_16"     -- 当前UI页

local pagesize = 5      -- 每页显示的条数 
local RandPage = {      -- 排行榜按钮(对应UI由上到下，由左到右)
    "7567751678838114865-36390_91",
    "7567751678838114865-36390_92",
    "7567751678838114865-36390_95",
    "7567751678838114865-36390_97"
}
local Rand_vValue = {       --排行的变量名，与RankPage顺序必须一致
    "战力",
    "举重",
    "倍率",
    "吞噬"
}

--------------------元数据分割线-----------------------
local function Player_Beat_info() -- 玩家自己的数据
    for index, meta in ipairs(RankMeta) do
        Player_data[index] = Player_data[index] or {}
        for k, _ in pairs(Player_data[index]) do
            local result, value = VarLib2:getPlayerVarByName(k, 3, meta.vValue) -- 获取要排行的玩家个人数据
            Player_data[index][k] = value                                       -- 添加到全局以便上传
        end
    end
end

local function Convert(num)
    if num == nil then
        return ""
    end
    if num < 10000 then
        if num == math.floor(num) then
            return tostring(math.floor(num))
        else
            return tostring(num)
        end
    end
    
    for _, unit in ipairs(convert_units) do
        if num >= unit.value then
            local quotient = num / unit.value
            quotient = math.floor(quotient * 100) / 100
            if quotient == math.floor(quotient) then
                quotient = math.floor(quotient)
            end
            return tostring(quotient) .. unit.name
        end
    end
end

local function My_info(eventobjid)      -- 自己数据的处理
    local found = false
    for k, v in ipairs(Data[1][player_data[eventobjid].currentRankIndex]) do
        if v.k == tostring(eventobjid) then       -- 改v.k，前100
            found = true
            vValue = Data[2] and Data[2][tonumber(v.k)] and Data[2][tonumber(v.k)][player_data[eventobjid].currentRankIndex] or ""
            Customui:setText(eventobjid, ui, my_ui[1], tostring(k))
            Customui:setText(eventobjid, ui, my_ui[2], v.nick or "")
            Customui:setText(eventobjid, ui, my_ui[3], v.k or "")
            Customui:setText(eventobjid, ui, my_ui[4], Convert(vValue) or "")
            break
        end
    end
    if not found then
        Customui:setText(eventobjid, ui, my_ui[1], "99+")
        local result,name=Player:getNickname(eventobjid)
        Customui:setText(eventobjid, ui, my_ui[2], name)
        Customui:setText(eventobjid, ui, my_ui[3], tostring(eventobjid) or "")
        local result, value = VarLib2:getPlayerVarByName(eventobjid, 3, Rand_vValue[player_data[eventobjid].currentRankIndex])
        Customui:setText(eventobjid, ui, my_ui[4], Convert(value) or "")
    end
end

local function Render(eventobjid)       -- 渲染主函数
    local startIndex = (player_data[eventobjid].page - 1) * pagesize + 1
    local endIndex = math.min(player_data[eventobjid].page * pagesize, #Data[1][player_data[eventobjid].currentRankIndex])
    Customui:setText(eventobjid, ui, page_ui[1], player_data[eventobjid].page)      -- 页码
    for k, v in ipairs(head_ui) do
        Customui:setText(eventobjid, ui, v, head_content[player_data[eventobjid].currentRankIndex][k])
    end
    for k, v in ipairs(rand_ui) do
        local index = startIndex + k - 1
        local rand = (index >= startIndex and index <= endIndex) and tostring(index) or ""
        Customui:setText(eventobjid, ui, v, rand)
    end
    for k, v in ipairs(id_ui) do
        local index = startIndex + k - 1
        local dataItem = Data[1][player_data[eventobjid].currentRankIndex][index]
        local nick = (dataItem and dataItem.nick) or ""
        Customui:setText(eventobjid, ui, v, nick)
    end
    for k, v in ipairs(mini_ui) do
        local index = startIndex + k - 1
        local dataItem = Data[1][player_data[eventobjid].currentRankIndex][index]
        local kValue = (dataItem and dataItem.k) or ""
        Customui:setText(eventobjid, ui, v, kValue)
    end
    for k, v in ipairs(data_ui) do
        local index = startIndex + k - 1
        local uin = (Data[1][player_data[eventobjid].currentRankIndex] and Data[1][player_data[eventobjid].currentRankIndex][index] and Data[1][player_data[eventobjid].currentRankIndex][index].k) or ""
        vValue = Data[2] and Data[2][tonumber(uin)] and Data[2][tonumber(uin)][player_data[eventobjid].currentRankIndex] or ""
        Customui:setText(eventobjid, ui, v, Convert(tonumber(vValue)))
    end
    My_info(eventobjid) -- 渲染自己的信息
end

local function LeftPage(e)      -- 左翻
    if e.uielement == page_ui[2] then
        if player_data[e.eventobjid].page > 1 then
            player_data[e.eventobjid].page = player_data[e.eventobjid].page - 1
            Render(e.eventobjid)
        else
            local result = Player:notifyGameInfo2Self(e.eventobjid, page_ui[4])
        end
    end
end

local function RightPage(e)     -- 右翻
    if e.uielement == page_ui[3] then
        if player_data[e.eventobjid].page < math.ceil(#Data[1][player_data[e.eventobjid].currentRankIndex] / pagesize) then
            player_data[e.eventobjid].page = player_data[e.eventobjid].page + 1
            Render(e.eventobjid)
        else
            local result = Player:notifyGameInfo2Self(e.eventobjid, page_ui[5])
        end
    end
end

local function ChangeRand(e)
    for index, value in ipairs(RandPage) do
        if value == e.uielement then
            player_data[e.eventobjid].currentRankIndex = index
            player_data[e.eventobjid].page = 1
            Render(e.eventobjid)
            break
        end
    end
end

local function OnOpenUI(e)      -- 每次打开页面都渲染，打开逻辑需要自己加，或者触发器里拼
    player_data[e.eventobjid] = {page = 1, currentRankIndex = 1}
    Render(e.eventobjid)
end

local function OnPlayerLeaveGame(e)
    player_data[e.eventobjid] = nil
end

-- 接收来自server的信息
local function func_event(param)        -- 从server那边搞过来的数据，自定义事件传递
    Data = param
    for k, _ in pairs(player_data) do
        Render(k)
    end
end

local function MixData(data1, data2)
    local data = {}
    data[1] = data1
    data[2] = data2
    func_event(data)
end

local function PullServer()
    local pullTotal = #RankMeta + 1 -- 总任务数：排行榜数（4）+ 玩家额外数据（1）
    local pullDone = 0 -- 已完成任务数
    for index, meta in ipairs(RankMeta) do
        local callback = function(ret, value)
            if ret == ErrorCode.OK and value then
                CloudData[index] = CloudData[index] or {}
                for k, v in ipairs(value) do
                    CloudData[index][k] = v
                end
            end
            pullDone = pullDone + 1 -- 完成一个任务
            if pullDone == pullTotal then -- 所有任务完成，再触发MixData
                MixData(CloudData,Players_extra)
            end
        end
        CloudSever:getOrderDataIndexAreaEx(meta.rank, -100, callback)
    end
    local callback = function (ret,k,v)
        if ret == ErrorCode.OK then
            Players_extra = v or {}
        end
        pullDone = pullDone + 1 -- 完成一个任务
        if pullDone == pullTotal then -- 所有任务完成，再触发MixData
            MixData(CloudData,Players_extra)
        end
    end
    local ret = CloudSever:getDataListByKeyEx(KvMeta,"Players",callback)
end

local isPushing = false -- 防止重入的标志位
local lastPushTime = 0       -- 记录上次成功执行的时间
local function PushServer(e)
    local current = e.second
    if (current ~= nil and current >= Time and (current - lastPushTime) % Time == 0 and not isPushing) then
        isPushing = true        -- 上锁
        Player_Beat_info()
        for index, value in ipairs(RankMeta) do
            for k, v in pairs(Player_data[index]) do
                local ret = CloudSever:setOrderDataBykey(value.rank, k, v) -- 上传
            end
        end
        local callback = function (ret,key, value)
            if ret == 0 then
                value = value or {}
                local data = value
                for k1, v1 in pairs(Player_data) do
                    for k2, v2 in pairs(v1) do
                        if value[k2] == nil then
                            value[k2] = {}
                        end
                        -- 玩家的迷你号是第一层，排行榜索引（玩家属性）是第二层，跟Player_data反过来
                        data[k2][k1] = v2
                    end
                end
                value = data
                return value
            end
        end
        -- 异步更新，消耗两次请求次数
        -- 理论上来讲放在这次数可能不太够用，但实测下来还行（已经解决）
        -- 如果第一次请求，可能会出现没有创建该键的情况，只需要等待下一次定时拉取即可
        -- 我不想消耗太多请求，我打算直接在回调里面做遍历更新并返回，虽然这可能有点繁琐
        CloudSever:UpdateDataListByKey(KvMeta,'Players',callback)
        -- 拉取是异步的，放前放后都没啥区别，只要保证定时拉取就行
        PullServer()
        lastPushTime = current
        isPushing = false       -- 解锁
    end
end

-- 初始化服务，让排行榜有数据，不然是空的
local function InitServer(e)
    for index, value in ipairs(RankMeta) do
        local result, value = VarLib2:getPlayerVarByName(e.eventobjid, 3, value.vValue)
        Player_data[index] = Player_data[index] or {}
        Player_data[index][e.eventobjid] = value
    end
    PullServer()
end

-- 这个函数是为了避免请求上限的，如果玩家离开了就把数据清理掉，防止浪费请求次数
local function Player_Close(e)
    for index, value in ipairs(RankMeta) do
        Player_data[index] = Player_data[index] or {}
        Player_data[index][e.eventobjid] = nil
    end
end

-- 仨事件都能看得懂，定时上传、初始化、清理
ScriptSupportEvent:registerEvent("Game.RunTime", PushServer)
ScriptSupportEvent:registerEvent("Game.AnyPlayer.EnterGame", InitServer)
ScriptSupportEvent:registerEvent("Game.AnyPlayer.LeaveGame", Player_Close)
ScriptSupportEvent:registerEvent('GetServerData', func_event)
ScriptSupportEvent:registerEvent('UI.Button.Click', LeftPage)
ScriptSupportEvent:registerEvent('UI.Button.Click', RightPage)
ScriptSupportEvent:registerEvent('UI.Button.Click', ChangeRand)
ScriptSupportEvent:registerEvent('UI.Show', OnOpenUI)
ScriptSupportEvent:registerEvent('Game.AnyPlayer.LeaveGame', OnPlayerLeaveGame)
