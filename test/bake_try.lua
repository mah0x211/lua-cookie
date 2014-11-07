local cookie = require('cookie');
local COOKIE_ATTR = {
    domain = 'example.com',
    path = '/',
    expires = 1,
    secure = true,
    httpOnly = true
};

-- test invalid arguments
ifNotNil( cookie.bake( nil, nil ) );
ifNotNil( cookie.bake( 'example', nil ) );
ifNotNil( cookie.bake( 'example', 'val', 1 ) );
-- test invalid attribute
ifNotNil( cookie.bake( 'example', 'val', {
    domain = 0
} ) );
ifNotNil( cookie.bake( 'example', 'val', {
    path = 0
} ) );
ifNotNil( cookie.bake( 'example', 'val', {
    expires = 0/0
} ) );
ifNotNil( cookie.bake( 'example', 'val', {
    secure = 'invalid'
} ) );
ifNotNil( cookie.bake( 'example', 'val', {
    httpOnly = 'invalid'
} ) );
-- test valid
ifNil( cookie.bake( 'example', 'val', nil ) );
ifNil( cookie.bake( 'example', 'val', COOKIE_ATTR ) );

