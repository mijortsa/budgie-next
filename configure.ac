AC_INIT([Budgie Next], 1, [ikey@solus-project.com], [budgie-next], [https://solus-project.com/])
AM_INIT_AUTOMAKE([-Wno-portability no-dist-gzip dist-xz foreign subdir-objects])
AC_PROG_CC
AC_PROG_CC_STDC
LT_PREREQ(2.2)
AC_CONFIG_HEADERS([config.h])
AC_PREFIX_DEFAULT(/usr/local)
AM_SILENT_RULES([yes])
LT_INIT([disable-static])

GLIB_GSETTINGS

GETTEXT_PACKAGE=budgie-next
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE",
                   [The prefix for our gettext translation domains.])

# Package requirements
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= 2.40.0])
PKG_CHECK_MODULES([GIO], [gio-2.0 >= 2.40.0])
PKG_CHECK_MODULES([GTK3], [gtk+-3.0 >= 3.14.0])

PULSE_MIN_VERS=2.0

MODULEDIR=${libdir}/budgie-next
AC_SUBST(MODULEDIR)
AC_DEFINE_UNQUOTED(MODULEDIR, "$MODULEDIR",
                   [Installation directory for Budgie plugins])

# Technically unused right now but might be used in the future
MODULE_DATA_DIR=${datadir}/budgie-next/plugins
AC_SUBST(MODULE_DATA_DIR)
AC_DEFINE_UNQUOTED(MODULE_DATA_DIR, "$MODULEDIR",
                   [Installation directory for Budgie plugin data])

PKG_CHECK_MODULES(GVC, libpulse >= $PULSE_MIN_VERS libpulse-mainloop-glib gobject-2.0)


# Wnck required for budgie-panel
PKG_CHECK_MODULES([WNCK3], [libwnck-3.0 >= 3.4.7])

# Required for menu in the panel
PKG_CHECK_MODULES([GMENU], [libgnome-menu-3.0 >= 3.10.1])

# Networking.
PKG_CHECK_MODULES([NM], [libnm-glib >= 0.9.8, libnm-util >= 0.9.8])

# WM
AC_ARG_ENABLE(wm, AS_HELP_STRING([--enable-wm], [enable wm @<:@default=yes@:>@]),
             [], [enable_wm=yes])
AS_IF([test "x$enable_wm" = "xyes"],
       [AC_DEFINE([BUILD_WM], [1], [Building window manager])],
       [])
AM_CONDITIONAL([BUILD_WM], [test x$enable_wm = x"yes"])

if test "x$enable_wm" = "xyes"; then
    # Required for Window Manager component
    PKG_CHECK_MODULES([MUTTER], [libmutter >= 3.14.0])
fi

# Because we target Linux.
PKG_CHECK_MODULES([GIO_UNIX], [gio-unix-2.0 >= 2.38.0])

AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

AC_CONFIG_MACRO_DIR([m4])

GOBJECT_INTROSPECTION_CHECK([1.38.0])

# Need Vala.
AM_PROG_VALAC([0.26], [], [AC_MSG_ERROR([valac is required to build Budgie Desktop])])


AC_SUBST(VALAFLAGS)

GETTEXT_PACKAGE=budgie-next
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, ["$GETTEXT_PACKAGE"], [Define the gettext package to be used])

AC_CONFIG_FILES([Makefile
                data/Makefile
                gvc/Makefile
                imports/Makefile
                imports/natray/Makefile
                panel/Makefile
                wm/Makefile])
AC_OUTPUT

AC_MSG_RESULT([
        budgie-next $VERSION
        ========

        prefix:                 ${prefix}
        libdir:                 ${libdir}
        sysconfdir:             ${sysconfdir}
        exec_prefix:            ${exec_prefix}
        bindir:                 ${bindir}
        datarootdir:            ${datarootdir}

        compiler:               ${CC}
        cflags:                 ${CFLAGS}
        ldflags:                ${LDFLAGS}

        wm:                     ${enable_wm}
])
