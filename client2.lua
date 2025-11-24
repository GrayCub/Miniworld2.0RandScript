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
    {value = 1e36,  name = "涧"},
    {value = 1e32,  name = "沟"},
    {value = 1e28,  name = "穰"},
    {value = 1e24,  name = "秭"},
    {value = 1e20,  name = "垓"},
    {value = 1e16,  name = "京"},
    {value = 1e12,  name = "兆"},
    {value = 1e8,  name = "亿"},
    {value = 1e4,  name = "万"}
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
--------------------元数据分割线--------------------

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
    for k, v in ipairs(Data[player_data[eventobjid].currentRankIndex]) do
        if v.k == tostring(eventobjid) then       -- 改v.k，前100
            found = true
            Customui:setText(eventobjid, ui, my_ui[1], tostring(k))
            Customui:setText(eventobjid, ui, my_ui[2], v.nick or "")
            Customui:setText(eventobjid, ui, my_ui[3], v.k or "")
            Customui:setText(eventobjid, ui, my_ui[4], Convert(v.v) or "")
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
        local dataItem = Data[2][eventobjid][player_data[eventobjid].currentRankIndex]
        vValue = (dataItem and dataItem.v) or ""
        Customui:setText(eventobjid, ui, v, Convert(tonumber(vValue)))
    end
    My_info(eventobjid) -- 渲染自己的信息
end

-- 接收来自server的信息
local function func_event(param, param2)        -- 从server那边搞过来的数据，自定义事件传递
    Data = param
    local data2 = param2
    print(Data, data2)
    for k, _ in pairs(player_data) do
        Render(k)
    end
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
        if player_data[e.eventobjid].page < math.ceil(#Data[player_data[e.eventobjid].currentRankIndex] / pagesize) then
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

ScriptSupportEvent:registerEvent('GetServerData', func_event)
ScriptSupportEvent:registerEvent('UI.Button.Click', LeftPage)
ScriptSupportEvent:registerEvent('UI.Button.Click', RightPage)
ScriptSupportEvent:registerEvent('UI.Button.Click', ChangeRand)
ScriptSupportEvent:registerEvent('UI.Show', OnOpenUI)
ScriptSupportEvent:registerEvent('Game.AnyPlayer.LeaveGame', OnPlayerLeaveGame)
