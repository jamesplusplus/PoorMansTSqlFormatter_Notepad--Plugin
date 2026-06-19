#include "instanceobj.h"

#include <QsciScintilla.h>
#include <Scintilla.h>

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMessageBox>

#include "fmtcli_runner.h"
#include "setting.h"
#include "version.h"

extern std::function<QsciScintilla*(QWidget*)> s_getCurEdit;

namespace {

int editorLength(QsciScintilla* editor)
{
	return (int)editor->SendScintilla(SCI_GETTEXTLENGTH);
}

bool editorHasSelection(QsciScintilla* editor)
{
	const long start = editor->SendScintilla(SCI_GETSELECTIONSTART);
	const long end = editor->SendScintilla(SCI_GETSELECTIONEND);
	return start != end;
}

QString getAllText(QsciScintilla* editor)
{
	const int len = editorLength(editor);
	if (len <= 0)
		return QString();

	QByteArray buf(len + 1, Qt::Uninitialized);
	editor->SendScintilla(SCI_GETTEXT, (uintptr_t)(len + 1), buf.data());
	buf[len] = '\0';
	return QString::fromUtf8(buf.constData(), len);
}

QString getSelectedText(QsciScintilla* editor)
{
	// Match QScintilla selectedText(): size first, then buffer (not wParam/lParam overload).
	const int size = (int)editor->SendScintilla(SCI_GETSELTEXT, 0);
	if (size <= 1)
		return QString();

	QByteArray buf(size, Qt::Uninitialized);
	editor->SendScintilla(SCI_GETSELTEXT, buf.data());
	return QString::fromUtf8(buf.constData());
}

QString trimSelectionOutput(QString text)
{
	while (text.endsWith(QLatin1Char('\n')) || text.endsWith(QLatin1Char('\r')))
		text.chop(1);
	return text;
}

void replaceSelection(QsciScintilla* editor, const QString& text)
{
	QByteArray bytes = text.toUtf8();
	bytes.append('\0');
	editor->SendScintilla(SCI_REPLACESEL, (uintptr_t)0, bytes.constData());
}

void replaceDocument(QsciScintilla* editor, const QString& text)
{
	const QByteArray bytes = text.toUtf8();
	if (bytes.isEmpty())
	{
		editor->SendScintilla(SCI_CLEARALL);
		editor->SendScintilla(SCI_EMPTYUNDOBUFFER);
		return;
	}

	// Notepad-- fork: full replace must use SCI_SET_UTF8_TEXT (setText() crashes from plugins).
	editor->SendScintilla(SCI_SET_UTF8_TEXT, (uintptr_t)bytes.size(), bytes.constData());
	editor->SendScintilla(SCI_EMPTYUNDOBUFFER);
}

} // namespace

InstanceObj::InstanceObj(QWidget* pNotepad, QMenu* pMenu, const QString& pluginDllPath)
	: QObject(pNotepad), m_pNotepad(pNotepad), m_rootMenu(pMenu), m_pluginDllPath(pluginDllPath)
{
}

InstanceObj::~InstanceObj()
{
}

QString InstanceObj::configFilePath() const
{
	return Setting::configPathForPlugin(m_pluginDllPath);
}

QString InstanceObj::formatterExePath() const
{
#if defined(Q_OS_WIN)
	const QString exeName = QStringLiteral("PoorMansTSqlFormatterFmtCli.exe");
#else
	const QString exeName = QStringLiteral("PoorMansTSqlFormatterFmtCli");
#endif
	QFileInfo dllInfo(m_pluginDllPath);
	return dllInfo.absolutePath() + QDir::separator() + exeName;
}

bool InstanceObj::runFormatter(const QString& input, QString& output, int& exitCode, QString& stderrText, bool force)
{
	const QString fmtExe = formatterExePath();
	if (!QFile::exists(fmtExe))
	{
		stderrText = QObject::tr("Formatter not found: %1").arg(fmtExe);
		return false;
	}

	QStringList args;
	if (force)
		args << QStringLiteral("--force");

	const QString cfg = configFilePath();
	if (QFile::exists(cfg))
	{
		args << QStringLiteral("--config") << cfg;
	}

	return runFmtCliProcess(fmtExe, QFileInfo(fmtExe).absolutePath(), args, input, output, exitCode, stderrText);
}

void InstanceObj::applyFormattedText(QsciScintilla* editor, const QString& text, bool selectionOnly)
{
	if (selectionOnly)
		replaceSelection(editor, trimSelectionOutput(text));
	else
		replaceDocument(editor, text);
}

void InstanceObj::formatSql()
{
	if (!s_getCurEdit)
		return;

	QsciScintilla* editor = s_getCurEdit(m_pNotepad);
	if (editor == nullptr || editorLength(editor) == 0)
		return;

	const bool selectionOnly = editorHasSelection(editor);
	const QString input = selectionOnly ? getSelectedText(editor) : getAllText(editor);
	if (input.isEmpty())
		return;

	QString output;
	QString stderrText;
	int exitCode = 0;
	if (!runFormatter(input, output, exitCode, stderrText, false))
	{
		QMessageBox::warning(m_pNotepad, QObject::tr("T-SQL Format"), stderrText);
		return;
	}

	if (exitCode == 2)
	{
		const auto answer = QMessageBox::question(
			m_pNotepad,
			QObject::tr("T-SQL Format"),
			QObject::tr("Parse warnings were encountered. Continue formatting anyway?"),
			QMessageBox::Yes | QMessageBox::No,
			QMessageBox::No);
		if (answer != QMessageBox::Yes)
			return;

		if (!runFormatter(input, output, exitCode, stderrText, true))
		{
			QMessageBox::warning(m_pNotepad, QObject::tr("T-SQL Format"), stderrText);
			return;
		}
	}

	if (exitCode != 0)
	{
		QMessageBox::warning(m_pNotepad, QObject::tr("T-SQL Format"),
			stderrText.isEmpty() ? QObject::tr("Formatting failed (exit %1).").arg(exitCode) : stderrText);
		return;
	}

	if (output.isEmpty() && !input.isEmpty())
	{
		QMessageBox::warning(m_pNotepad, QObject::tr("T-SQL Format"),
			QObject::tr("Formatter returned no output."));
		return;
	}

	applyFormattedText(editor, output, selectionOnly);
}

void InstanceObj::optionsWin()
{
	Setting* dlg = new Setting(m_pNotepad, configFilePath());
	dlg->setAttribute(Qt::WA_DeleteOnClose);
	dlg->setWindowFlag(Qt::Window);
	dlg->setWindowTitle(QObject::tr("T-SQL Formatter Options"));
	dlg->resize(420, 220);
	dlg->show();
}
