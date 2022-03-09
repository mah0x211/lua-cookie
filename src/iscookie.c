/**
 *  Copyright (C) 2022 Masatoshi Fukunaga
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to
 *  deal in the Software without restriction, including without limitation the
 *  rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

#include <lauxhlib.h>

/**
 * https://www.ietf.org/rfc/rfc6265.txt
 * 4.1.1.  Syntax
 *
 * cookie-name  = token (RFC2616)
 * cookie-value = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
 * cookie-octet = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
 *                  ; ! # $ % & ' ( ) * + - . / 0-9 : < = > ? @ A-Z [ ] ^ _ `
 *                  ; a-z { | } ~
 *                  ; US-ASCII characters excluding CTLs,
 *                  ; whitespace DQUOTE, comma, semicolon,
 */
static const unsigned char COOKIE_OCTET[256] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    //  0x21
    '!',
    //  0x22
    0,
    //  0x23-2B
    '#', '$', '%', '&', '\'', '(', ')', '*', '+',
    //  0x2C
    0,
    //  0x2D-3A
    '-', '.', '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':',
    //  0x3B
    0,
    //  0x3C-5B
    '<', '=', '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y',
    'Z', '[',
    //  0x5C
    0,
    //  0x5D-7E
    ']', '^', '_', '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
    'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '{', '|', '}', '~'};

#define DQUOTE '"'

static int iscookie_lua(lua_State *L)
{
    size_t len         = 0;
    unsigned char *str = (unsigned char *)lauxh_checklstring(L, 1, &len);
    size_t i           = 0;

    if (!len) {
        lua_pushboolean(L, 0);
        return 1;
    }

    // found DQUOTE at head
    if (str[0] == DQUOTE) {
        // not found DQUOTE at tail
        if (len == 1 || str[len - 1] != DQUOTE) {
            lua_pushboolean(L, 0);
            return 1;
        }
        // skip DQUOTES
        i++;
        len--;
    }

    for (; i < len; i++) {
        if (!COOKIE_OCTET[str[i]]) {
            lua_pushboolean(L, 0);
            return 1;
        }
    }

    lua_pushboolean(L, 1);
    return 1;
}

LUALIB_API int luaopen_cookie_iscookie(lua_State *L)
{
    lua_pushcfunction(L, iscookie_lua);
    return 1;
}
