
TARGET = DesktopEditors
DESTDIR = $$PWD

include(defaults.pri)

INCLUDEPATH += $$PWD/src/prop \
                $$PWD/src

HEADERS += \
    #src/prop/csplash_p.h \
    src/prop/defines_p.h \
    src/prop/cascapplicationmanagerwrapperintf.h \
    src/prop/version_p.h

SOURCES += \
    src/prop/cmainwindowimpl.cpp \
    src/prop/utils.cpp

#DEFINES += _GLIBCXX_USE_CXX11_ABI=0
DEFINES += __DONT_WRITE_IN_APP_TITLE
DEFINES += APP_ICON_PATH=\"./res/icons/desktopeditors.ico\"

message($$PLATFORM_BUILD)

#win32 {
    # SCRIVAR-REBRAND: the suite's built-in updater is DISABLED on purpose.
    # Updates are owned by the Scrivar Office LAUNCHER (electron-updater against
    # the Scrivar channel, releases-office/). Leaving _UPDMODULE on would compile
    # in a SECOND updater that talks to ONLYOFFICE's update service and links to
    # their download page — two updaters fighting, one of them pointing upstream.
    # Neutralised here rather than by simply not passing the `updmodule` CONFIG
    # flag, so it stays off no matter how build_tools invokes qmake.
    # Do not re-enable — see apps/scrivar-office/CLAUDE.md.
    updmodule:!build_xp {
        # DEFINES += _UPDMODULE
        message(SCRIVAR: updates module is turned OFF - launcher owns updates)
    }
#}

core_windows {
    RC_FILE = $$PWD/version.rc
    OTHER_FILES += $$PWD/version.rc
}

core_linux {
    GLIB_RESOURCE_FILES += $$PWD/res/gresource.xml

    glib_resources.name = gresource
    glib_resources.input = GLIB_RESOURCE_FILES
    glib_resources.output = $$PWD/res/${QMAKE_FILE_IN_BASE}.c
    glib_resources.commands = glib-compile-resources --target ${QMAKE_FILE_OUT} --sourcedir ${QMAKE_FILE_IN_PATH} --generate-source ${QMAKE_FILE_IN}
    glib_resources.variable_out = SOURCES
    QMAKE_EXTRA_COMPILERS += glib_resources
}

HEADERS += \
    src/prop/cmainwindowimpl.h
