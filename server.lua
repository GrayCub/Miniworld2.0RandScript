--------------------元数据分割线--------------------
local Player_data = {} -- 当前云服玩家数据
local CloudData = {}   -- 云端Pull下来的数据
local Time = 10        -- 定时上传更新的时间间隔，单位秒，10、20、30，强烈推荐这三个值
local RankMeta = {     -- 排行榜元数据
    {
        rank = "rank_1755894081",
        vValue = "qishi"
    },
    {
        rank = "rank_1755895157",
        vValue = "danshi"
    }
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

local function func_event(param) -- 编码完事后通过迷你的自定义事件把数据传给client
    local ok, json = pcall(JSON.encode, JSON, param)
    Game:dispatchEvent("GetServerData", { customdata = json })
end

local count = 0
local function CountRand()
    count = count + 1
    if count == #RankMeta then
        func_event(CloudData)
        count = 0
    end
end

local function PullServer()
    for index, meta in ipairs(RankMeta) do
        local callback = function(ret, value)
            if ret == ErrorCode.OK and value then
                CloudData[index] = CloudData[index] or {}
                for k, v in ipairs(value) do
                    CloudData[index][k] = v
                end
                CountRand()
            end
        end
        CloudSever:getOrderDataIndexAreaEx(meta.rank, -100, callback)
    end
end

local function PushServer(e)
    local current = e.second
    if (current ~= nil and current >= Time and (current - Time) % Time == 0) then
        Player_Beat_info()
        for index, value in ipairs(RankMeta) do
            for k, v in pairs(Player_data[index]) do
                local ret = CloudSever:setOrderDataBykey(value.rank, k, v) -- 上传
            end
        end
        PullServer()
    end
end

--初始化服务，让排行榜有数据，不然是空的
local function InitServer(e)
    for index, value in ipairs(RankMeta) do
        local result, value = VarLib2:getPlayerVarByName(e.eventobjid, 3, value.vValue)
        Player_data[index] = Player_data[index] or {}
        Player_data[index][e.eventobjid] = value
    end
    PullServer()
end

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
