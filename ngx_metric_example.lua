local metric = require("metric.ngx_metric")
local metric_dict = ngx.shared.result_ngx_metric
local exptime = 3600 * 24
local symbol = "|"


local function run()
    local prefix = ngx.var.ngx_metric_name
    if prefix == nil or prefix == "" then
        ngx.log(ngx.ERR, "no valid ngx_metric_name variable")
        return
    end
    ngx_metric = metric:new(metric_dict, prefix, exptime, symbol)
    ngx_metric:record()
end


local function errorlog(err)
    return string.format("%s: %s", err or "", debug.traceback())
end


local status, err = xpcall(run, errorlog)
if not status then
    ngx.log(ngx.ERR, "ngx_metric script failed, err: ", err)
end
