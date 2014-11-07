local cookie = require('cookie');
local bin = {};
local c, tbl;

for i = 1, 4 do
    -- create cookies
    bin[i] = ('name%d=val%d'):format( i, i );
    c = table.concat( bin, ';' );
    
    -- parse cookies
    tbl = ifNil( cookie.parse( c ) );
    for j = 1, i do
        ifNotEqual( tbl['name'..j], 'val' .. j );
    end
end

