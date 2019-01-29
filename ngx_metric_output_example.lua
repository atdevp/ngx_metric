local json = require("cjson")
local metric_dict = ngx.shared.result_ngx_metric
local symbol = "|"

local function split(str, d)
    local lst = { }
    local n = string.len(str)
    local start = 1
    while start <= n do
        local i = string.find(str, d, start)
        if i == nil then
            table.insert(lst, string.sub(str, start, n))
            break
        end
        table.insert(lst, string.sub(str, start, i-1))
        if i == n then
            table.insert(lst, "")
            break
        end
        start = i + 1
    end
    return lst
end


local function output(all_keys)
    local ret = {}

    for _, long_key in pairs(all_keys) do

        local split_table = split(long_key, symbol)
        if #split_table == 2 then
            local prefix = split_table[1]
            local suffix = split_table[2]

            if not ret[prefix] then ret[prefix] = {} end
            ret[prefix][suffix] = metric_dict:get(long_key)
        else
            ngx.log(ngx.ERR, "failed split key: ", long_key)
        end
    end
    return ret
end


local function run()
    local data = {}
    local all_keys = metric_dict:get_keys()

    ngx.header.content_type = "application/json"

    if #all_keys == 0 then
        res = json.encode(data)
        ngx.say(res)
        return ngx.exit(200)
    end
    
    data = output(all_keys)
    res = json.encode(data)
    ngx.say(res)
    return ngx.exit(200)
end


local function errorlog(err)
    return string.format("%s: %s", err or "", debug.traceback())
end


local status, err = xpcall(run, errorlog)
if not status then
    ngx.log(ngx.ERR, "ngx_metric_output script failed, err: ", err)
end
