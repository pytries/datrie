AM_CPPFLAGS = -I$(top_srcdir)

bin_PROGRAMS = trietool

trietool_SOURCES = trietool.c
trietool_LDADD = \
	$(top_builddir)/datrie/libdatrie.la	\
	$(ICONV_LIBS)

OLD_PROG_NAME=trietool-0.2

install-data-hook:
	rm -f $(DESTDIR)$(bindir)/$(OLD_PROG_NAME)
	$(LN_S) trietool $(DESTDIR)$(bindir)/$(OLD_PROG_NAME)

uninstall-hook:
	rm -f $(DESTDIR)$(bindir)/$(OLD_PROG_NAME)

