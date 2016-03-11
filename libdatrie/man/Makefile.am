EXTRA_DIST = trietool.1

man_MANS = trietool.1

OLD_MAN_NAME=trietool-0.2.1

install-data-hook:
	rm -f $(DESTDIR)$(mandir)/man1/$(OLD_MAN_NAME)
	$(LN_S) trietool.1 $(DESTDIR)$(mandir)/man1/$(OLD_MAN_NAME)

uninstall-hook:
	rm -f $(DESTDIR)$(mandir)/man1/$(OLD_MAN_NAME)

