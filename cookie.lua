--
-- Copyright (C) 2014 Masatoshi Teruya
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
local concat = table.concat
local date = os.date
local time = os.time
local floor = math.floor
local find = string.find
local sub = string.sub
local lower = string.lower
local upper = string.upper
local type = type
local setmetatable = setmetatable
local istoken = require('cookie.istoken')
local iscookie = require('cookie.iscookie')
-- constants
local DATEFMT = '!%a, %d %b %Y %H:%M:%S GMT'
local SAMESITE = {}
for _, v in ipairs({
    'Strict',
    'Lax',
    'None',
}) do
    SAMESITE[v], SAMESITE[lower(v)], SAMESITE[upper(v)] = v, v, v
end

local INF_POS = math.huge
local INF_NEG = -INF_POS

-- isfinite
--- @param v any
--- @return boolean
local function isfinite(v)
    return type(v) == 'number' and v < INF_POS and v > INF_NEG and floor(v) == v
end

--- verify
--- @param maxage integer
--- @param secure boolean
--- @param httponly boolean
--- @param samesite string
--- @param domain string
--- @param path string
--- @return boolean ok
--- @return string err
local function verify(maxage, secure, httponly, samesite, domain, path)
    if maxage ~= nil and not isfinite(maxage) then
        return false, 'maxage must be integer'
    elseif secure ~= nil and type(secure) ~= 'boolean' then
        return false, 'secure must be boolean'
    elseif httponly ~= nil and type(httponly) ~= 'boolean' then
        return false, 'httponly must be boolean'
    elseif samesite ~= nil and
        (type(samesite) ~= 'string' or not SAMESITE[samesite]) then
        return false, 'samesite must be "strict", "lax" or "none"'
    elseif domain ~= nil and type(domain) ~= 'string' then
        return false, 'domain must be string'
    elseif path ~= nil and type(path) ~= 'string' then
        return false, 'path must be string'
    end
    return true
end

--- trim_space
--- @param s string
--- @return string
local function trim_space(s)
    -- remove leading whitespaces
    local _, pos = find(s, '^%s+')
    if pos then
        s = sub(s, pos + 1)
    end

    -- remove trailing whitespaces
    pos = find(s, '%s+$')
    if pos then
        return sub(s, 1, pos - 1)
    end

    return s
end

--- parse
--- @param cookies string
--- @return table cookies
local function parse(cookies)
    if type(cookies) ~= 'string' then
        error('cookies must be string', 2)
    elseif sub(cookies, #cookies) ~= ';' then
        -- append ';' delimiter to tail
        cookies = cookies .. ';'
    end

    local tbl = {}
    local head = 1
    local tail = find(cookies, ';', head, true)
    while tail do
        local c = trim_space(sub(cookies, head, tail - 1))

        if #c > 0 then
            local sep = find(c, '=', 1, true)
            if sep then
                local name = sub(c, 1, sep - 1)
                local value = sub(c, sep + 1)
                if istoken(name) and iscookie(value) then
                    tbl[name] = value
                end
            end
        end

        head = tail + 1
        tail = find(cookies, ';', head, true)
    end

    return tbl
end

--- todate
--- @param v integer
--- @return string|osdate
local function todate(v)
    return date(DATEFMT, v)
end

--- bake
--- @param name string
--- @param val string
--- @param attr table
--- @return string cookie
local function bake(name, val, attr)
    if type(name) ~= 'string' or not istoken(name) then
        error('name must be valid cookie-name', 2)
    elseif type(val) ~= 'string' or not iscookie(val) then
        error('val must be valid cookie-value', 2)
    elseif attr ~= nil and type(attr) ~= 'table' then
        error('attr must be table', 2)
    end

    attr = attr or {}
    local ok, err = verify(attr.maxage, attr.secure, attr.httponly,
                           attr.samesite, attr.domain, attr.path)
    if not ok then
        error('attr.' .. err, 2)
    end

    local c = {
        name .. '=' .. val,
    }
    if attr.maxage then
        c[#c + 1] = 'Expires=' .. todate(time() + attr.maxage)
        c[#c + 1] = 'Max-Age=' .. tostring(attr.maxage)
    end
    if attr.domain then
        c[#c + 1] = 'Domain=' .. attr.domain
    end
    if attr.path then
        c[#c + 1] = 'Path=' .. attr.path
    end
    if attr.samesite then
        c[#c + 1] = 'SameSite=' .. SAMESITE[attr.samesite]
    end
    if attr.secure then
        c[#c + 1] = 'Secure'
    end
    if attr.httponly then
        c[#c + 1] = 'HttpOnly'
    end

    return concat(c, '; ')
end

--- @class Cookie
--- @field name string
--- @field attr table
local Cookie = {}
Cookie.__index = Cookie

--- bake
--- @param val string
--- @return string cookie
function Cookie:bake(val)
    return bake(self.name, val, self.attr)
end

--- new
--- @param name string
--- @param attr table
--- @return Cookie c
local function new(name, attr)
    if type(name) ~= 'string' or not istoken(name) then
        error('name must be valid cookie-name string', 2)
    elseif attr ~= nil and type(attr) ~= 'table' then
        error('attr must be table', 2)
    end

    attr = attr or {}
    local ok, err = verify(attr.maxage, attr.secure, attr.httponly,
                           attr.samesite, attr.domain, attr.path)
    if not ok then
        error('attr.' .. err, 2)
    end

    return setmetatable({
        name = name,
        attr = attr,
    }, Cookie)
end

return {
    new = new,
    bake = bake,
    parse = parse,
}

