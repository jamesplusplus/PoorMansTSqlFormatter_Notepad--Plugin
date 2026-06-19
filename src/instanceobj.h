#pragma once

#include <QObject>
#include <QWidget>
#include <QMenu>
#include <QString>

class QsciScintilla;

class InstanceObj : public QObject
{
	Q_OBJECT

public:
	InstanceObj(QWidget* pNotepad, QMenu* pMenu, const QString& pluginDllPath);
	~InstanceObj();

	QWidget* m_pNotepad;
	QMenu* m_rootMenu;

public slots:
	void formatSql();
	void optionsWin();

private:
	QString m_pluginDllPath;
	QString configFilePath() const;
	QString formatterExePath() const;
	bool runFormatter(const QString& input, QString& output, int& exitCode, QString& stderrText, bool force);
	void applyFormattedText(QsciScintilla* editor, const QString& text, bool selectionOnly);

	InstanceObj(const InstanceObj&) = delete;
	InstanceObj& operator=(const InstanceObj&) = delete;
};
