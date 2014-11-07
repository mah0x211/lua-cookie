local cookie = require('cookie');
local COOKIE_ATTR = {
    domain = 'example.com',
    path = '/',
    expires = 1,
    secure = true,
    httpOnly = true
};
local baker;

-- test invalid arguments
ifNotNil( cookie.Baker.new( nil, nil ) );
ifNotNil( cookie.Baker.new( 'example', 1 ) );
-- test invalid attribute
ifNotNil( cookie.Baker.new( 'example', {
    domain = 0
} ) );
ifNotNil( cookie.Baker.new( 'example', {
    path = 0
} ) );
ifNotNil( cookie.Baker.new( 'example', {
    expires = 0/0
} ) );
ifNotNil( cookie.Baker.new( 'example', {
    secure = 'invalid'
} ) );
ifNotNil( cookie.Baker.new( 'example', {
    httpOnly = 'invalid'
} ) );
-- test valid
ifNil( cookie.Baker.new( 'example' ) );
baker = ifNil( cookie.Baker.new( 'example', COOKIE_ATTR ) );

-- test invalid argumnt
ifNotNil( baker:bake() );
ifNotNil( baker:bake(1) );
ifNotNil( baker:bake(true) );
ifNotNil( baker:bake({}) );
ifNil( baker:bake('test') );
