package = "cookie"
version = "1.0-0"
source = {
    url = "git://github.com/mah0x211/lua-cookie.git",
    tag = "v1.0.0"
}
description = {
    summary = "HTTP Cookie utility",
    homepage = "https://github.com/mah0x211/lua-cookie", 
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "halo >= 1.1",
    "date >= 2.1.1-1"
}
build = {
    type = "builtin",
    modules = {
        cookie = "cookie.lua",
    }
}

