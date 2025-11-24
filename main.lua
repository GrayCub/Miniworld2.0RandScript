local np = {}
local phbdata = {}  -- 存储排行榜原始数据（key=榜名，value=数据列表）
local rankUinCache = {}  -- 存储“榜名→[迷你号数组]”，用于快速查排名

-- ===================== 1. 开放函数配置（无修改，保留“名字”选项） =====================
np.openFnArgs = {
    sz = {
        displayName = "设置排行榜值",  
        params = {
            "设置玩家",Mini.Player,
            "设置榜",Mini.String,
            "值为",Mini.Number,
            "玩家名称",Mini.String,
            "等级",Mini.Number,
            "战力字符串",Mini.String,
            "额外补充数据",Mini.String
        },         
        tips = "额外数据自动按「玩家名称#等级#战力字符串#补充数据」格式拼接；等级必须是数字，战力字符串需带“战力”字样（如“1500战力”）"
    },
    hq = {
        displayName = "获取数据",  
        params = {"获取榜",Mini.String,"前",Mini.Number,"名,正序排序为",Mini.Bool," 注意 每个玩家每分钟限制在一次获取"},         
    },
    zd = {
        returnType = Mini.String,  
        displayName = "获取单个",  
        params = {
            "获取榜",Mini.String,
            "第",Mini.Number,
            "指定",Mini.String,
            "数据(填 迷你号/值/额外数据/等级/战力/名字 没有数据返回空值 需要提前执行获取数据函数)"
        },         
    },
    hwpm = {
        returnType = Mini.Number,  
        displayName = "获取玩家排名",  
        params = {"目标玩家", Mini.Player,"目标排行榜", Mini.String},         
        tips = "需先执行「获取数据」函数；未上榜返回nil"
    },
}

-- ===================== 2. sz：设置排行榜值（无修改） =====================
function np:sz(pid, str, num, name, level, powerStr, extra)
    local targetUin = tostring(pid)
    if type(level) ~= "number" then
        printError("[排行榜] 设置失败：等级必须是数字（如5、10），当前传入：" .. type(level))
        return false
    end
    if not powerStr or powerStr == "" then
        printError("[排行榜] 设置失败：战力字符串不可为空（如“1200战力”）")
        return false
    end

    local extendData = name .. "#" .. tostring(level) .. "#" .. powerStr
    if extra and extra ~= "" then
        extendData = extendData .. "#" .. extra
    end

    local errorCode = Data.Map:SetRankValueAndBlock(str, nil, targetUin, num, extendData)
    if errorCode == ErrorCode.OK then
        print("[排行榜] 成功：玩家" .. targetUin .. "（" .. name .. "）等级" .. level .. "，战力" .. powerStr .. "已加入" .. str)
        return true
    else
        printError("[排行榜] 设置失败：错误码=" .. errorCode .. "，请检查排行榜名称/权限")
        return false
    end
end

-- ===================== 3. hq：获取排行榜列表（无修改） =====================
function np:hq(j, num, zxxx)
    local function GlobalRankCallback(code, _, ascending, datas)
        if code == ErrorCode.OK then            
            phbdata[j] = datas 
            rankUinCache[j] = {}
            for i, data in ipairs(datas) do
                rankUinCache[j][i] = tostring(data.k)
            end
        else
            phbdata[j] = nil
            rankUinCache[j] = nil
            printError("[排行榜] 获取列表失败：错误码=" .. code)
        end
    end
    Data.Map:GetNumValuesAndCallback(j, nil, num, zxxx, GlobalRankCallback)
end

-- ===================== 4. zd：获取单个数据（核心修改：“名字”分支提示逻辑） =====================
function np:zd(j, num, sj)
    if not phbdata[j] or not phbdata[j][num] then
        -- 名次本身不存在的提示（如“第10名不存在”），所有名次统一提示（不修改）
        printError("[排行榜] 获取单个数据失败：排行榜" .. j .. "第" .. num .. "名不存在")
        return nil
    end

    local data = phbdata[j][num]
    local extendData = data["info"] or ""
    local dataSegments = {}
    for seg in string.gmatch(extendData, "([^#]+)") do
        table.insert(dataSegments, seg)
    end

    if sj == "迷你号" then
        return tostring(data["k"]) or nil
    elseif sj == "值" then
        return tostring(data["v"]) or nil
    elseif sj == "额外数据" then
        return extendData or nil
    
    -- 核心修改：“名字”分支——仅第1名无名字时提示，第2名及以后不提示
    elseif sj == "名字" then
        if #dataSegments >= 1 then
            return dataSegments[1] or nil  -- 有名字则正常返回
        else
            -- 仅当名次是第1名时，才打印错误提示；第2名及以后静默返回nil
            if num == 1 then
                printError("[排行榜] 获取名字失败：第1名额外数据格式错误（未存储玩家名称，正确格式：名称#等级#战力）")
            end
            return nil  -- 第2名及以后无名字时，不提示直接返回nil
        end
    
    -- 其他数据类型（等级、战力）的提示逻辑不变（仍正常提示）
    elseif sj == "等级" then
        if #dataSegments >= 2 then
            local level = tonumber(dataSegments[2])
            return level ~= nil and level or nil
        else
            printError("[排行榜] 获取等级失败：第" .. num .. "名额外数据格式错误（缺少等级，正确格式：名称#等级#战力）")
            return nil
        end
    elseif sj == "战力" then
        if #dataSegments >= 3 then
            return dataSegments[3] or nil
        else
            printError("[排行榜] 获取战力失败：第" .. num .. "名额外数据格式错误（缺少战力，正确格式：名称#等级#战力）")
            return nil
        end
    
    else
        printError("[排行榜] 未知数据类型：" .. sj .. "，可选值：迷你号/值/额外数据/等级/战力/名字")
        return nil
    end
end

-- ===================== 5. hwpm：获取玩家排名（无修改） =====================
function np:hwpm(pid, rankName)
    local targetUin = tostring(pid)
    if not rankUinCache[rankName] then
        printError("[排行榜] 获取排名失败：请先执行「获取数据」函数加载" .. rankName .. "数据")
        return nil
    end

    for rank, uin in ipairs(rankUinCache[rankName]) do
        if uin == targetUin then
            return rank
        end
    end

    print("[排行榜] 玩家" .. targetUin .. "未在" .. rankName .. "上榜")
    return nil
end

return np