#pragma once

#include <QString>
#include <QMenu>

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

struct ndd_proc_data
{
	QString m_strPlugName;
	QString m_strFilePath;
	QString m_strComment;
	QString m_version;
	QString m_auther;
	int m_menuType;
	QMenu* m_rootMenu;

	ndd_proc_data() : m_rootMenu(nullptr), m_menuType(0) {}
};

typedef struct ndd_proc_data NDD_PROC_DATA;

typedef bool (*NDD_PROC_IDENTIFY_CALLBACK)(NDD_PROC_DATA* pProcData);
