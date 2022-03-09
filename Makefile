SRCS=$(wildcard $(SRCDIR)/*.c)
OBJS=$(SRCS:.c=.o)
SOBJ=$(SRCS:.c=.so)
INSTALL?=install

.PHONY: all install clean

all: src/istoken.so src/iscookie.so

%.o: %.c
	$(CC) $(CFLAGS) $(WARNINGS) $(COVERAGE) $(CPPFLAGS) -o $@ -c $<

%.$(LIB_EXTENSION): %.o
	$(CC) -o $@ $^ $(LDFLAGS) $(LIBS) $(PLATFORM_LDFLAGS) $(COVERAGE)

install: src/istoken.$(LIB_EXTENSION) src/iscookie.$(LIB_EXTENSION)
	$(INSTALL) -d $(INST_LIBDIR)
	$(INSTALL) src/istoken.$(LIB_EXTENSION) $(INST_LIBDIR)
	$(INSTALL) src/iscookie.$(LIB_EXTENSION) $(INST_LIBDIR)
	$(INSTALL) cookie.lua $(INST_LUADIR)
	rm -f ./src/*.o
	rm -f ./src/*.so
