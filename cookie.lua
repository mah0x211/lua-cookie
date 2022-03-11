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
local format = string.format
local floor = math.floor
local find = string.find
local sub = string.sub
local lower = string.lower
local upper = string.upper
local tointeger = math.tointeger or tonumber
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

--- trim_leading_space
--- @param s string
--- @return string
local function trim_leading_space(s)
    -- remove leading whitespaces
    local _, pos = find(s, '^%s+')
    return pos and sub(s, pos + 1) or s
end

--- trim_trailing_space
--- @param s string
--- @return string
local function trim_trailing_space(s)
    -- remove trailing whitespaces
    local pos = find(s, '%s+$')
    return pos and sub(s, 1, pos - 1) or s
end

--- trim_space
--- @param s string
--- @return string
local function trim_space(s)
    return trim_trailing_space(trim_leading_space(s))
end

--- split_kvpair
---@param s string
---@return string key
---@return string val
local function split_kvpair(s)
    if #s > 1 then
        local sep = find(s, '=', 1, true)
        if sep and sep > 1 then
            --
            -- 5.6.3.  Whitespace
            -- https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-semantics-19#section-5.6.3
            -- OWS  = *( SP / HTAB )
            --      ; optional whitespace
            -- BWS  = OWS
            --      ; "bad" whitespace
            --
            -- remove BWS
            return trim_trailing_space(sub(s, 1, sep - 1)),
                   trim_leading_space(sub(s, sep + 1))
        end
    end
end

--- parse
--- @param str string
--- @param baked boolean
--- @return table cookie
--- @return string err
local function parse(str, baked)
    if type(str) ~= 'string' then
        error('str must be string', 2)
    elseif baked ~= nil and type(baked) ~= 'boolean' then
        error('baked must be boolean', 2)
    elseif sub(str, #str) ~= ';' then
        -- append ';' delimiter to tail
        str = str .. ';'
    end

    ---
    -- 4.2.  Cookie
    -- https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-09.txt#section-4.2
    --
    -- 4.2.1.  Syntax
    --
    -- The user agent sends stored cookies to the origin server in the
    -- Cookie header.  If the server conforms to the requirements in
    -- Section 4.1 (and the user agent conforms to the requirements in
    -- Section 5), the user agent will send a Cookie header that conforms to
    -- the following grammar:
    --
    --   cookie-header = "Cookie:" SP cookie-string
    --   cookie-string = cookie-pair *( ";" SP cookie-pair )
    --
    local tbl = {}
    local head = 1
    local tail = find(str, ';', head, true)
    while tail do
        --
        -- 4.1.1.  Syntax
        -- https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-rfc6265bis-09.txt#section-4.1.1
        --
        -- Informally, the Set-Cookie response header field contains a
        -- cookie, which begins with a name-value-pair, followed by zero or
        -- more attribute-value pairs.  Servers SHOULD NOT send Set-Cookie
        -- header fields that fail to conform to the following grammar:
        --
        --   set-cookie        = set-cookie-string
        --   set-cookie-string = BWS cookie-pair *( BWS ";" OWS cookie-av )
        --   cookie-pair       = cookie-name BWS "=" BWS cookie-value
        --
        local name, value = split_kvpair(trim_space(sub(str, head, tail - 1)))
        --
        --   cookie-name  = 1*cookie-octet
        --   cookie-value = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
        --   cookie-octet = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
        --                  / %x80-FF
        --                ; octets excluding CTLs,
        --                ; whitespace DQUOTE, comma, semicolon,
        --                ; and backslash
        --
        if name and istoken(name) and (value == '' or iscookie(value)) then
            if baked then
                tbl.name = name
                tbl.value = value
                --
                --   cookie-av  = expires-av / max-age-av / domain-av /
                --                path-av / secure-av / httponly-av /
                --                samesite-av / extension-av
                -- parse cookie-av
                head = tail + 1
                tail = find(str, ';', head, true)
                while tail do
                    local av = trim_space(sub(str, head, tail - 1))
                    local k, v = split_kvpair(av)
                    k = lower(k or av)

                    if k == 'expires' then
                        --
                        --   expires-av        = "Expires" BWS "=" BWS sane-cookie-date
                        --   sane-cookie-date  =
                        --       <IMF-fixdate, defined in [HTTPSEM], Section 5.6.7>
                        --
                        -- TODO: parse <sane-cookie-date>
                        if v == nil or #v == 0 then
                            return nil, 'invalid "Expires" attribute'
                        end
                    elseif k == 'max-age' then
                        --
                        --   max-age-av     = "Max-Age" BWS "=" BWS non-zero-digit *DIGIT
                        --                  ; In practice, both expires-av and max-age-av
                        --                  ; are limited to dates representable by the
                        --                  ; user agent.
                        --   non-zero-digit = %x31-39
                        --                  ; digits 1 through 9
                        --
                        if v == nil or #v == 0 or not find(v, '^[+%-]?%d%d*$') then
                            return nil, 'invalid "Max-Age" attribute'
                        end
                        v = tointeger(v)
                        k = 'maxage'
                    elseif k == 'domain' then
                        --
                        --   domain-av    = "Domain" BWS "=" BWS domain-value
                        --   domain-value = <subdomain>
                        --                ; defined in [RFC1034], Section 3.5, as
                        --                ; enhanced by [RFC1123], Section 2.1
                        --
                        -- TODO: parse <domain-value>
                        if v == nil or #v == 0 then
                            return nil, 'invalid "Domain" attribute'
                        end
                    elseif k == 'path' then
                        --
                        --   path-av    = "Path" BWS "=" BWS path-value
                        --   path-value = *av-octet
                        --   av-octet   = %x20-3A / %x3C-7E
                        --              ; any CHAR except CTLs or ";"
                        --
                        -- av-octet pattern: ^[a-zA-Z0-9 !"#$%&'()*+,-./:<=>?@[\\\]^_`{|}~]*$
                        if v == nil or
                            (#v > 0 and
                                not find(v,
                                         [[^[%w !"#$%%&'()*+,%-./:<=>?@[\%]^_`{|}~]*$]])) then
                            return nil, 'invalid "Path" attribute'
                        end
                    elseif k == 'secure' or k == 'httponly' then
                        --   secure-av   = "Secure"
                        --   httponly-av = "HttpOnly"
                        if v ~= nil then
                            return nil, 'invalid "' ..
                                       (k == 'secure' and 'Secure' or 'HttpOnly') ..
                                       '" attribute'
                        end
                        v = true
                    elseif k == 'samesite' then
                        --   samesite-av    = "SameSite" BWS "=" BWS samesite-value
                        --   samesite-value = "Strict" / "Lax" / "None"
                        if v then
                            v = lower(v)
                        end
                        if v == nil or not SAMESITE[v] then
                            return nil, 'invalid "SameSite" attribute'
                        end
                    else
                        return nil, format('unknown %q attribute', av)
                    end

                    tbl[k] = v
                    head = tail + 1
                    tail = find(str, ';', head, true)
                end

                return tbl
            end
            tbl[name] = value
        elseif baked then
            return nil, 'invalid "Set-Cookie" value'
        end

        -- parse next cookie-pair
        head = tail + 1
        tail = find(str, ';', head, true)
    end

    return tbl
end

--- parse_baked_cookie
--- @param str string
--- @return Cookie cookie
--- @return string err
local function parse_baked_cookie(str)
    return parse(str, true)
end

--- parse_cookies
--- @param str string
--- @return table cookies
local function parse_cookies(str)
    return parse(str)
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
    parse_cookies = parse_cookies,
    parse_baked_cookie = parse_baked_cookie,
}

