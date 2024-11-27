lua-cookie
=========

[![test](https://github.com/mah0x211/lua-cookie/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-cookie/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-cookie/branch/master/graph/badge.svg)](https://codecov.io/gh/mah0x211/lua-cookie)


HTTP Cookie utility module.


## Installation

```sh
luarocks install cookie
```

---

## tbl, err = cookie.parse( str [, baked] )

parse a value of the `Cookie` or `Set-Cookie` header.

**Parameters**

- `str:string`: a semicolon `;` separated cookie values.
- `baked:boolean`: set `true` to parse a `Set-Cookie` value.

**Returns**

- `tbl:table`: a table that contains a parsed cookie values.
- `err:any`: error message.


**Example**

```lua
local dump = require('dump')
local cookie = require('cookie')
local tbl = assert(cookie.parse('cookie1=val1; cookie2=val2'))

print(dump(tbl))
-- {
--     cookie1 = "val1",
--     cookie2 = "val2"
-- }

tbl = assert(cookie.parse('foo= bar; expires =Fri, 11 Mar 2022 08:03:38 GMT; Max-age = -01123; doMain=example.com; patH=/; SECURE; HTTponLy; samesite=lAx', true)
print(dump(tbl))
-- {
--     domain = "example.com",
--     expires = "Fri, 11 Mar 2022 08:03:38 GMT",
--     httponly = true,
--     maxage = -1123,
--     name = "foo",
--     path = "/",
--     samesite = "lax",
--     secure = true,
--     value = "bar"
-- }
```


## tbl, err = cookie.parse_cookies( str )

parse a value of the `Cookie` header.  
equivalent to `cookie.parse(str)`.


## tbl, err = cookie.parse_baked_cookie( str )

parse a value of the `Set-Cookie` header.  
equivalent to `cookie.parse(str, true)`.


## str = cookie.bake( name, val [, attr] )

create a cookie string.

**Parameters**

- `name:string`: cookie name.
- `val:string`: cookie value.
- `attr:table`: cookie attributes.
  - `domain:string`: append `Domain` attribute.
  - `path:string`: append `Path` attribute.
  - `maxage:integer`: append `Max-Age` and `Expires` attributes.
  - `secure:boolean`: append `Secure` attribute.
  - `httponly:boolean`: append `HttpOnly` attribute.
  - `samesite:string`: append `SameSite` attribute.


**Returns**

- `str:string`: a cookie string.


**Example**

```lua
local cookie = require('cookie')
local str = cookie.bake('example', 'val', {
    domain = 'example.com',
    path = '/',
    maxage = 1,
    secure = true,
    httponly = true,
    samesite = 'lax',
})

print(str)
-- example=val; Expires=Wed, 09 Mar 2022 06:37:15 GMT; Max-Age=1; Domain=example.com; Path=/; SameSite=Lax; Secure; HttpOnly
```

