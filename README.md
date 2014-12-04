lua-cookie
=========

HTTP Cookie utility module.

---

## Dependencies

- halo: https://github.com/mah0x211/lua-halo
- util: https://github.com/mah0x211/lua-util
- date: https://github.com/Tieske/date

## Installation

```sh
luarocks install cookie --from=http://mah0x211.github.io/rocks/
```


## Methods

### Parse

#### tbl, err = cookie.parse( cookies:string )

```lua
local inspect = require('util').inspect;
local cookie = require('cookie');
local cookiestr = 'cookie1=val1; cookie2=val2';
local tbl, err = cookie.parse( cookiestr );

print( inspect( { tbl, err } ) );
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
local inspect = require('util').inspect;
local cookie = require('cookie');
local str, err = cookie.bake( 'example', 'val', {
    domain = 'example.com',
    path = '/',
    expires = 1,
    secure = true,
    httpOnly = true
});

print( inspect( { str, err } ) );
--[[
{ 
    [1] = "example=val; domain=example.com; expires=Thu, 04 Dec 2014 01:23:34 GMT; max-age=Thu, 04 Dec 2014 01:23:34 GMT; httpOnly; path=/; secure"
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

