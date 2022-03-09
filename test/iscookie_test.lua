local testcase = require('testcase')
local iscookie = require('cookie.iscookie')

function testcase.iscookie()
    -- test that returns a true
    for _, v in ipairs({
        'foo',
        'foobarbaz',
        '"foobarbaz"',
    }) do
        assert.is_true(iscookie(v))
    end

    -- test that returns a false
    for _, v in ipairs({
        '',
        'f oo',
        'foo,barbaz',
        'foobar;baz',
        '"foobarbaz',
        'foobarbaz"',
    }) do
        assert.is_false(iscookie(v))
    end
end

