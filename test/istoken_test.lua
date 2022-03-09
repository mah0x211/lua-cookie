local testcase = require('testcase')
local istoken = require('cookie.istoken')

function testcase.istoken()
    -- test that return a true
    for _, v in ipairs({
        'foo',
        'foo-bar-baz',
    }) do
        assert.is_true(istoken(v))
    end

    -- test that return a false
    for _, v in ipairs({
        '',
        'foo barbaz',
        'foo;barbaz',
        'foobar=',
    }) do
        assert.is_false(istoken(v))
    end
end

