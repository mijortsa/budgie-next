-include $(top_srcdir)/common.mk

EXTRA_DIST =

panel_resources = $(shell glib-compile-resources --sourcedir=$(top_srcdir)/data --generate-dependencies $(top_srcdir)/data/budgie-panel.gresource.xml)

BUILT_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c

CLEANFILES = \
	$(BUILT_SOURCES)

# resources
budgie-panel-resources.h: $(top_srcdir)/data/budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-header --c-name budgie_next_panel $<

budgie-panel-resources.c: $(top_srcdir)/data/budgie-panel.gresource.xml $(panel_resources)
	glib-compile-resources --target=$@ --sourcedir=$(top_srcdir)/data --generate-source --c-name budgie_next_panel $<


bin_PROGRAMS = budgie-next-panel

budgie_next_panel_SOURCES = \
	budgie-panel-resources.h \
	budgie-panel-resources.c \
	Animation.vala \
	AudioPane.vala \
	BudgieMenuWindow.vala \
	MprisClient.vala \
	MprisGui.vala \
	MprisWidget.vala \
	ncenter.vala \
	panel.vala \
	utils.vala

budgie_next_panel_CFLAGS = \
	-DWNCK_I_KNOW_THIS_IS_UNSTABLE \
	$(GOBJECT_CFLAGS) \
	$(GTK3_CFLAGS) \
	$(WNCK3_CFLAGS) \
	$(GMENU_CFLAGS) \
	$(GVC_CFLAGS) \
	-I${top_srcdir}/gvc/ \
	-DGMENU_I_KNOW_THIS_IS_UNSTABLE \
	-DMODULE_DIR=\"$(MODULEDIR)\" \
	-DMODULE_DATA_DIR=\"$(MODULE_DATA_DIR)\" \
	-DDATADIR=\"$(datadir)/budgie-next\" \
	-DLOCALEDIR=\"$(localedir)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\"

budgie_next_panel_LDADD = \
	$(GOBJECT_LIBS) \
	$(GTK3_LIBS) \
	$(WNCK3_LIBS) \
	$(GMENU_LIBS) \
	$(GVC_LIBS) \
	../gvc/libgvc.la \
	-lm

budgie_next_panel_VALAFLAGS = \
	--vapidir=${top_srcdir} \
	--pkg gvc-1.0 \
	--pkg gtk+-3.0 \
	--pkg libwnck-3.0 \
	--pkg gio-unix-2.0 \
	--pkg libgnome-menu-3.0 \
	$(VALAFLAGS)
