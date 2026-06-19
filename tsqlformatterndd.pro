TEMPLATE = lib
LANGUAGE = C++

CONFIG += qt warn_on release
QT += core gui widgets

DEFINES += NDD_EXPORTDLL
win32: DEFINES += _UNICODE UNICODE

HEADERS += \
	src/instanceobj.h \
	src/setting.h \
	src/ndd_formatter_options.h \
	src/fmtcli_runner.h \
	src/version.h

SOURCES += \
	src/pluginexport.cpp \
	src/instanceobj.cpp \
	src/setting.cpp \
	src/ndd_formatter_options.cpp \
	src/fmtcli_runner.cpp

INCLUDEPATH += $$PWD/include
INCLUDEPATH += $$PWD/third_party/qscint/src
INCLUDEPATH += $$PWD/third_party/qscint/src/Qsci
INCLUDEPATH += $$PWD/third_party/qscint/scintilla/include

TARGET = tsqlformatterndd

win32 {
	if(contains(QMAKE_HOST.arch, x86_64)) {
		CONFIG(Debug, Debug|Release) {
			DESTDIR = $$PWD/out/plugin
		} else {
			DESTDIR = $$PWD/out/plugin
		}
		# Link Notepad-- shared qmyedit_qt5.dll (import lib in third_party/ndd_importlib).
		LIBS += -L$$PWD/third_party/ndd_importlib
		LIBS += -lqmyedit_qt5
	}
}

unix {
	if(contains(QMAKE_HOST.arch, x86_64)) {
		CONFIG(Debug, Debug|Release) {
			DESTDIR = $$PWD/out/plugin
			LIBS += -L../../x64/Debug
			LIBS += -lqmyedit_qt5d
		} else {
			DESTDIR = $$PWD/out/plugin
			LIBS += -L../../x64/Release
			LIBS += -lqmyedit_qt5
		}
	}
	UI_DIR = .ui
	MOC_DIR = .moc
	OBJECTS_DIR = .obj
}
