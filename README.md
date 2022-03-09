lua-cookie
=========

[![test](https://github.com/mah0x211/lua-cookie/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-cookie/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-cookie/branch/master/graph/badge.svg)](https://codecov.io/gh/mah0x211/lua-cookie)


HTTP Cookie utility module.

---

## Installation

```sh
luarocks install cookie --from=http://mah0x211.github.io/rocks/
```


## Methods

### Parse

#### tbl, err = cookie.parse( cookies:string )

```lua
local dump = require('dump')
local cookie = require('cookie')
local cookiestr = 'cookie1=val1; cookie2=val2'
local tbl, err = cookie.parse( cookiestr )

print( dump( { tbl, err } ) );
--[[ 
{ 
    [1] = { 
        cookie1 = "val1",
        cookie2 = "val2"
    }
}
--]]
```

### Bake

#### str, err = cookie.bake( name:string, val:string [, attr:table] )

```lua
local dump = require('dump')
local cookie = require('cookie')
local str, err = cookie.bake( 'example', 'val', {
    domain = 'example.com',
    path = '/',
    expires = 1,
    secure = true,
    httpOnly = true
})

print( dump( { str, err } ) )
--[[
{
    [1] = "example=val; Expires=Wed, 09 Mar 2022 04:57:19 GMT; Max-Age=1; Domain=example.com; Path=/; Secure; HttpOnly"
}
--]]
```

**Parameters**

- `name`: string - cookie name.
- `val`: string - cookie value.
- `attr`: table - cookie attributes.
  - `domain`: string - domain name for cookie.
  - `path`: string - path string for cookie.
  - `expires`: int - seconds.
  - `secure`: boolean - append secure attribute.
  - `httpOnly`: boolean - append httpOnly attribute.

