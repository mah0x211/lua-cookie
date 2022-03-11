require('luacov')
local testcase = require('testcase')
local unpack = require('unpack')
local cookie = require('cookie')

function testcase.bake()
    -- test that bake cookie
    for _, v in ipairs({
        {
            args = {
                'example',
                'val',
            },
            exp = 'example=val',
        },
        {
            args = {
                'example',
                'val',
                {
                    maxage = 1,
                    domain = 'example.com',
                    path = '/',
                    samesite = 'lax',
                    secure = true,
                    httponly = true,
                },
            },
            exp = 'example=val; Expires=[^;]*; Max%-Age=1; Domain=example%.com; Path=/; SameSite=Lax; Secure; HttpOnly',
        },
    }) do
        local c = assert(cookie.bake(unpack(v.args)))
        assert.match(c, v.exp, false)
    end

    -- test that throws error
    for _, v in ipairs({
        {
            args = {
                {},
            },
            exp = 'name must be valid cookie-name',
        },
        {
            args = {
                'foo',
                'bar;',
            },
            exp = 'val must be valid cookie-value',
        },
        {
            args = {
                'foo',
                'bar',
                true,
            },
            exp = 'attr must be table',
        },
        {
            args = {
                'foo',
                'bar',
                {
                    maxage = 'foo',
                },
            },
            exp = 'attr.maxage must be integer',
        },
        {
            args = {
                'foo',
                'bar',
                {
                    secure = 'foo',
                },
            },
            exp = 'attr.secure must be boolean',
        },
        {
            args = {
                'foo',
                'bar',
                {
                    httponly = 'foo',
                },
            },
            exp = 'attr.httponly must be boolean',
        },
        {
            args = {
                'foo',
                'bar',
                {
                    samesite = {},
                },
            },
            exp = 'attr.samesite must be "strict", "lax" or "none"',
        },
        {
            args = {
                'foo',
                'bar',
                {
                    domain = {},
                },
            },
            exp = 'attr.domain must be string',
        },
        {
            args = {
                'foo',
                'bar',
                {
                    path = true,
                },
            },
            exp = 'attr.path must be string',
        },
    }) do
        local err = assert.throws(cookie.bake, unpack(v.args))
        assert.match(err, v.exp)
    end
end

function testcase.parse()
    -- create cookies
    local bin = {}
    for i = 1, 4 do
        bin[i] = string.format('name%d=val%d', i, i)
    end
    local c = table.concat(bin, '; ') .. '  '

    -- test that parse cookies
    local tbl = assert(cookie.parse(c))
    for i = 1, 4 do
        assert.equal(tbl['name' .. i], 'val' .. i)
    end

    -- test that return empty table
    assert.empty(cookie.parse(''))

    -- test that throws an error
    local err = assert.throws(cookie.parse)
    assert.match(err, 'str must be string')
end

function testcase.parse_with_bake_option()
    -- test that parse set-cookie-value
    local c = table.concat({
        'foo= bar',
        'expires =Fri, 11 Mar 2022 08:03:38 GMT',
        'Max-age = -01123',
        'doMain=example.com',
        'patH=/',
        'SECURE',
        'HTTponLy',
        'samesite=lAx',
    }, '; ')
    local tbl = assert(cookie.parse(c, true))
    assert.equal(tbl, {
        name = 'foo',
        value = 'bar',
        expires = 'Fri, 11 Mar 2022 08:03:38 GMT',
        maxage = -1123,
        domain = 'example.com',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'lax',
    })

    -- test that return an error
    for _, v in ipairs({
        {
            val = '',
            exp = 'invalid "Set-Cookie" value',
        },
        {
            val = '=bar',
            exp = 'invalid "Set-Cookie" value',
        },
        {
            val = table.concat({
                'foo= bar',
                'expires',
            }, '; '),
            exp = 'invalid "Expires" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'expires =  ',
            }, '; '),
            exp = 'invalid "Expires" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'max-age',
            }, '; '),
            exp = 'invalid "Max-Age" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'max-age=  ',
            }, '; '),
            exp = 'invalid "Max-Age" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'max-age=foo',
            }, '; '),
            exp = 'invalid "Max-Age" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'domain',
            }, '; '),
            exp = 'invalid "Domain" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'domain=  ',
            }, '; '),
            exp = 'invalid "Domain" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'path=\a ',
            }, '; '),
            exp = 'invalid "Path" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'secure= ',
            }, '; '),
            exp = 'invalid "Secure" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'httponly  =',
            }, '; '),
            exp = 'invalid "HttpOnly" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'samesite',
            }, '; '),
            exp = 'invalid "SameSite" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'samesite=',
            }, '; '),
            exp = 'invalid "SameSite" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'samesite=invalid-value',
            }, '; '),
            exp = 'invalid "SameSite" attribute',
        },
        {
            val = table.concat({
                'foo= bar',
                'unknown-attribute=unknown-value',
            }, '; '),
            exp = 'unknown "unknown-attribute=unknown-value" attribute',
        },
    }) do
        local _, err = cookie.parse(v.val, true)
        assert.match(err, v.exp)
    end

    -- test that throws an error
    local err = assert.throws(cookie.parse, '', {})
    assert.match(err, 'baked must be boolean')
end

function testcase.parse_cookies()
    -- create cookies
    local bin = {}
    for i = 1, 4 do
        bin[i] = string.format('name%d=val%d', i, i)
    end
    local c = table.concat(bin, '; ') .. '  '

    -- test that equivalent to parse(s)
    local tbl = assert(cookie.parse_cookies(c))
    for i = 1, 4 do
        assert.equal(tbl['name' .. i], 'val' .. i)
    end
end

function testcase.parse_baked_cookie()
    -- test that equivalent to parse(s, true)
    local c = table.concat({
        'foo= bar',
        'expires =Fri, 11 Mar 2022 08:03:38 GMT',
        'Max-age = -01123',
        'doMain=example.com',
        'patH=/',
        'SECURE',
        'HTTponLy',
        'samesite=lAx',
    }, '; ')
    local tbl = assert(cookie.parse_baked_cookie(c))
    assert.equal(tbl, {
        name = 'foo',
        value = 'bar',
        expires = 'Fri, 11 Mar 2022 08:03:38 GMT',
        maxage = -1123,
        domain = 'example.com',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'lax',
    })
end

function testcase.new()
    -- test that create a cookie object
    assert(cookie.new('foo'))

    -- test that throws error
    for _, v in ipairs({
        {
            args = {
                true,
            },
            exp = 'name must be valid cookie-name string',
        },
        {
            args = {
                'foo',
                false,
            },
            exp = 'attr must be table',
        },
        {
            args = {
                'foo',
                {
                    domain = true,
                },
            },
            exp = 'attr.domain must be string',
        },
    }) do
        local err = assert.throws(cookie.new, unpack(v.args))
        assert.match(err, v.exp)
    end
end

function testcase.bake_method()
    local c = assert(cookie.new('foo'))

    -- test that bake cookie
    local v = assert(c:bake('barbaz'))
    assert.equal(v, 'foo=barbaz')
end
