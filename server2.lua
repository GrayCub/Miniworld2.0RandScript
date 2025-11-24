--------------------元数据分割线--------------------
-- Player_data的第一层是排行榜索引（顺序），第二层是玩家的uin，值是玩家对应的排行数据
-- index是数值，1、2、3、4，它的顺序跟RankMeta是一一对应的
local Player_data = {} -- 当前云服玩家数据
local Players_extra = {} -- 当前云服玩家额外数据
local CloudData = {}   -- 云端Pull下来的数据
local Time = 10        -- 定时上传更新的时间间隔，单位秒，10、20、30，强烈推荐这三个值
local RankMeta = {     -- 排行榜元数据
    {
        rank = "rank_1763838039",
        vValue = "战力"
    },
    {
        rank = "rank_1763838056",
        vValue = "举重"
    },
    {
        rank = "rank_1763838177",
        vValue = "倍率"
    },
    {
        rank = "rank_1763874679",
        vValue = "吞噬"
    },
}
local KvMeta = "datalist_1763837930" -- 存储玩家额外数据的KV表名

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

local function func_event(param1,param2) -- 编码完事后通过迷你的自定义事件把数据传给client（前端）
    local data = {}
    data[1] = param1
    data[2] = param2
    Game:dispatchEvent("GetServerData", { customdata = data })
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
                func_event(CloudData,Players_extra)
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
            func_event(CloudData,Players_extra)
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
