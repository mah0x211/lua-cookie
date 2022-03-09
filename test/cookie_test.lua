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
        bin[i] = ('name%d=val%d'):format(i, i)
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
    assert.match(err, 'cookies must be string')
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
