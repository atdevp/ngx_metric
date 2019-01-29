local _M = { _VERSION = '0.0.1'}
local mt = { __index = _M }

function _M.new(_, dict, prefix, exptime, symbol)
    return setmetatable({
            dict = dict,
            prefix = prefix,
            exptime = exptime,
            symbol = symbol,
    }, mt) 
end


function _M.long_key(self, metric)
    -- ngx.log(ngx.ERR, "------------------------", self.prefix, self.symbol,metric)
    return self.prefix .. self.symbol .. metric
end


local is_num = function(n) return type(n) == "number" end

    
local function safe_incr(dict, key, value, exptime)
    if not is_num(value) then
        ngx.log(ngx.ERR, "failed incr number type")
        return 
    end   
    
    newval, err, forcible =  dict:incr(key, value)
    if not newval then
	    if err ~= "not found" then
            local errmsg = "failed incr key: " .. key .. " errmsg: " .. err
            ngx.log(ngx.ERR, errmsg)
            return
        end
		ok, err = dict:safe_add(key, value, exptime)
		if ok == nil and err == "no memory" then
			ngx.log(ngx.ERR, "no memory to set key")
		end
	end
    return
end


function _M.req_time_statistic(self)
    local key = self:long_key("req_time")
	local value = tonumber(ngx.var.request_time)
    safe_incr(self.dict, key, value, self.exptime)
end


function _M.req_code_statistic(self)
	local code = tonumber(ngx.var.status) or 500
	if code < 400 then
        local key = self:long_key("code_ok")
		safe_incr(self.dict, key, 1, self.exptime)	
	end
	
	if code >= 400 and code < 500 then
        local key = self:long_key("code_4xx")
		safe_incr(self.dict, key, 1, self.exptime)	
	end

	if code >= 500 then
        local key = self:long_key("code_5xx")
		safe_incr(self.dict, key, 1, self.exptime)
	end
end


function _M.record(self)
    self:req_time_statistic()
    self:req_code_statistic()
end

return _M
