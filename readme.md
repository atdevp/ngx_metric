

# Description
ngx_metric - calculation nginx location request_time sum and request_count sum a period of time
 
# Table of Contents
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [record](#record)
* [Result](#result)
* [See Also](#see-also)


# Synopsis

```lua
lua_package_path  "/path/to/lualib/?.lua;/path/to/lualib/ngx_metric/?.lua;;";
lua_shared_dict  result_ngx_metric 2m;

server {
    listen 80;
    server_name _ api.test.com;
    
    location /hello/world {
        proxy_pass http://127.0.0.1:9090;
        set $ngx_metric_name "/hello/world";
        
        log_by_lua_block {
            local metric = require("metric.ngx_metric")
            local metric_dict = ngx.shared.result_ngx_metric
            local exptime = 3600 * 24
            local symbol = "|"
            local prefix = ngx.var.ngx_metric_name
            
            if prefix == nil or prefix == "" then
                ngx.log(ngx.ERR, "no valid ngx_metric_name variable")
                return
            end
            
            ngx_metric = metric:new(metric_dict, prefix, exptime, symbol)
            ngx_metric:record()
        }
    }
    
    location /hello/ngx {
        proxy_pass http://127.0.0.1:9090;
        set $ngx_metric_name "/hello/ngx";
        log_by_lua_file "/path/to/lualib/ngx_metric/ngx_metric_example.lua";
    }
    
    location /status {
        content_by_lua_file "/path/to/lualib/ngx_metric/ngx_metric_output_example.lua";
    }
    
}
```

# Methods
[Back to TOC](#table-of-contents)
## new

**syntax:** `obj = class.new(dict, prefix, exptime, symbol)`

Instantiates an object of this class. The class value is returned by the call require `metric.ngx_metric`.

This method takes the following arguments:

* `dict`: lua_shared_dict, we use `<ngx_metric_name>:<metric>` string as a unique state identifier inside the shared dict.
* `prefix`: The prefix parameter specified in every location .  For example, set $ngx_metric_name "/hello/world".
* `exptime`: Specify the expiration time of the key in memory.
* `symbol`: Key separator in memory.

[Back to TOC](#table-of-contents)

## record

**syntax:** `obj = class.record()`

Fires a new request incoming event and start to calculates request_time sum and request_count. finally, put the result to shared dict.

[Back to TOC](#table-of-contents)


# Result

 - First request ngx metric status
```json
{
  "/hello/world": {
    "req_time": 12662.673000007,
    "code_ok": 39186
  },
  "/hello/ngx": {
    "req_time": 12233.748000018,
    "code_ok": 96952
  }
}
```
  - Second request ngx metric status
```json
{
  "/hello/world": {
    "code_5xx": 42,
    "req_time": 12524.213000018,
    "code_ok": 99212
  },
  "/hello/ngx": {
    "req_time": 12963.532000007,
    "code_ok": 40117
  }
}
```
  
# See Also

* the ngx_lua module: https://github.com/openresty/lua-nginx-module
* OpenResty: https://openresty.org/

[Back to TOC](#table-of-contents)
