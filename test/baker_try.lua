local Cookie = require('cookie');
local COOKIE_ATTR = {
    domain = 'example.com',
    path = '/',
    expires = 1,
    secure = true,
    httpOnly = true
};
local cookie;

-- test invalid arguments
ifNotNil( Cookie.new( nil, nil ) );
ifNotNil( Cookie.new( 'example', 1 ) );
-- test invalid attribute
ifNotNil( Cookie.new( 'example', {
    domain = 0
} ) );
ifNotNil( Cookie.new( 'example', {
    path = 0
} ) );
ifNotNil( Cookie.new( 'example', {
    expires = 0/0
} ) );
ifNotNil( Cookie.new( 'example', {
    secure = 'invalid'
} ) );
ifNotNil( Cookie.new( 'example', {
    httpOnly = 'invalid'
} ) );
-- test valid
ifNil( Cookie.new( 'example' ) );
cookie = ifNil( Cookie.new( 'example', COOKIE_ATTR ) );

-- test invalid argumnt
ifNotNil( cookie:bake() );
ifNotNil( cookie:bake(1) );
ifNotNil( cookie:bake(true) );
ifNotNil( cookie:bake({}) );
ifNil( cookie:bake('test') );
