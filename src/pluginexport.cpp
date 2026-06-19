#include <QObject>
#include <QString>
#include <QWidget>
#include <QMenu>
#include <QAction>
#include <QKeySequence>
#include <functional>

#ifdef WIN32
#include <Windows.h>
#endif

#define NDD_EXPORTDLL

#if defined(Q_OS_WIN)
	#if defined(NDD_EXPORTDLL)
		#define NDD_EXPORT __declspec(dllexport)
	#else
		#define NDD_EXPORT __declspec(dllimport)
	#endif
#else
	#define NDD_EXPORT __attribute__((visibility("default")))
#endif

#include <qsciscintilla.h>
#include <pluginGl.h>

#include "instanceobj.h"
#include "version.h"

#ifdef __cplusplus
extern "C" {
#endif

NDD_EXPORT bool NDD_PROC_IDENTIFY(NDD_PROC_DATA* pProcData);
NDD_EXPORT int NDD_PROC_MAIN(QWidget* pNotepad, const QString& strFileName,
	std::function<QsciScintilla*(QWidget*)> getCurEdit,
	std::function<bool(QWidget*, int, void*)> pluginCallBack,
	NDD_PROC_DATA* pProcData);

#ifdef __cplusplus
}
#endif

std::function<QsciScintilla*(QWidget*)> s_getCurEdit;
std::function<bool(QWidget*, int, void*)> s_invokeMainFun;

bool NDD_PROC_IDENTIFY(NDD_PROC_DATA* pProcData)
{
	if (pProcData == nullptr)
		return false;

	pProcData->m_strPlugName = QObject::tr("T-SQL Formatter");
	pProcData->m_strComment = QObject::tr("Poor Man's T-SQL Formatter for Notepad--");
	pProcData->m_version = QString(NDD_TSQL_FORMATTER_VERSION);
	pProcData->m_auther = QStringLiteral("PoorMansTSqlFormatter fork");
	pProcData->m_menuType = 1;
	return true;
}

int NDD_PROC_MAIN(QWidget* pNotepad, const QString& strFileName,
	std::function<QsciScintilla*(QWidget*)> getCurEdit,
	std::function<bool(QWidget*, int, void*)> pluginCallBack,
	NDD_PROC_DATA* pProcData)
{
	if (pProcData == nullptr || pProcData->m_rootMenu == nullptr)
		return -1;

	s_getCurEdit = getCurEdit;
	s_invokeMainFun = pluginCallBack;

	InstanceObj* instance = new InstanceObj(pNotepad, pProcData->m_rootMenu, strFileName);
	instance->setObjectName(QStringLiteral("ndd-tsqlformatter"));

	QAction* formatAction = pProcData->m_rootMenu->addAction(QObject::tr("Format T-SQL"));
	formatAction->setShortcut(QKeySequence(QStringLiteral("Ctrl+Alt+F")));
	QObject::connect(formatAction, &QAction::triggered, instance, &InstanceObj::formatSql);

	pProcData->m_rootMenu->addSeparator();

	QAction* optionsAction = pProcData->m_rootMenu->addAction(QObject::tr("Options..."));
	QObject::connect(optionsAction, &QAction::triggered, instance, &InstanceObj::optionsWin);

	return 0;
}

#ifdef WIN32
BOOL WINAPI DllMain(HINSTANCE, DWORD, LPVOID)
{
	return TRUE;
}
#endif
