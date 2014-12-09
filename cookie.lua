--[[
  
  Copyright (C) 2014 Masatoshi Teruya

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
  
  cookie.lua
  Created by Masatoshi Teruya on 14/11/07.
  
--]]

-- modules
local date = require('date');
local isCookieName = require('rfcvalid.6265').isCookieName;
local isCookieValue = require('rfcvalid.6265').isCookieValue;
local typeof = require('util').typeof;
local EATTR = 'attr.%s must be %s';
-- constants
-- attribute names are not case-sensitive
local ATTRS = { 
    domain = 'string',
    path = 'string',
    expires = 'int',
    secure = 'boolean',
    httpOnly = 'boolean'
};


local function parseAttr( attr, callback )
    local v;
    
    if not typeof.table( attr ) then
        return 'attr must be table';
    elseif not typeof.Function( callback ) then
        return 'callback must be function';
    end
    
    for k, t in pairs( ATTRS ) do
        v = attr[k];
        if v ~= nil then
            if not typeof[t]( v ) then
                if t == 'int' then
                    return EATTR:format( k, 'integer' );
                else
                    return EATTR:format( k, t );
                end
            end
            err = callback( k, v, t );
            if err then
                return err;
            end
        end
    end
end


-- class
local Cookie = require('halo').class.Cookie;

function Cookie.parse( cookies )
    local tbl = {};
    
    if not cookies then
        return tbl;
    elseif not typeof.string( cookies ) then
        return nil, 'cookie must be string';
    end
    
    for k, v in cookies:gmatch( '([^;%s]+)=([^;]+)' ) do
        tbl[k] = v;
    end
    
    return tbl;
end


function Cookie.bake( name, val, attr )
    local c, err
    
    -- with trim option
    name = isCookieName( name, true );
    if not name then
        err = 'name must be valid cookie-name string';
    elseif not isCookieValue( val ) then
        err = 'val must be valid cookie-value string';
    else
        c = name .. '=' .. val;
        err = parseAttr( attr or {}, function( k, v, t )
            if t == 'string' then
                c = c .. '; ' .. k .. '=' .. v;
            elseif k == 'expires' then
                local exp = date(true);
                exp:addseconds( v );
                exp = exp:fmt('${rfc1123}');
                c = c .. '; expires=' .. exp .. '; max-age=' .. exp;
            elseif t == 'boolean' and v then
                c = c .. '; ' .. k;
            end
        end);
    end
    
    if err then
        return nil, err;
    end
    
    return c;
end


function Cookie:__index( field )
    local own = protected(self);
    
    if field == 'name' then
        return own.name;
    end
    
    return own.attr[field];
end


function Cookie:init( name, attr )
    local own = protected(self);
    local tbl = {};
    local err;
    
    if not isCookieName( name ) then
        err = 'name must be valid cookie-name string';
    elseif attr then
        err = parseAttr( attr, function( k, v, t )
            tbl[k] = v;
        end);
    end
    
    if err then
        return nil, err;
    end
    own.name = name;
    own.attr = tbl;
    
    return self;
end


function Cookie:bake( val )
    local own = protected(self);
    
    return Cookie.bake( own.name, val, own.attr );
end


return Cookie.exports;

