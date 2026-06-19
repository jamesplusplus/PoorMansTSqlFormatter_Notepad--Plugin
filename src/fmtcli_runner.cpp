#include "fmtcli_runner.h"

#include <QByteArray>
#include <QDir>
#include <QFileInfo>

#include <string>
#include <vector>

#if defined(Q_OS_WIN)
#include <Windows.h>

namespace {

QString quoteWinArg(const QString& arg)
{
	if (arg.isEmpty())
		return QStringLiteral("\"\"");
	if (!arg.contains(QLatin1Char('"')) && !arg.contains(QLatin1Char(' ')) && !arg.contains(QLatin1Char('\t')))
		return arg;
	QString quoted = QStringLiteral("\"");
	for (QChar ch : arg)
	{
		if (ch == QLatin1Char('"'))
			quoted += QStringLiteral("\"\"");
		quoted += ch;
	}
	quoted += QLatin1Char('"');
	return quoted;
}

QString buildCommandLine(const QString& exePath, const QStringList& args)
{
	QStringList parts;
	parts << quoteWinArg(exePath);
	for (const QString& arg : args)
		parts << quoteWinArg(arg);
	return parts.join(QLatin1Char(' '));
}

bool readPipeToByteArray(HANDLE pipe, QByteArray& out)
{
	char buffer[4096];
	DWORD bytesRead = 0;
	for (;;)
	{
		if (!ReadFile(pipe, buffer, sizeof(buffer), &bytesRead, nullptr))
		{
			if (GetLastError() == ERROR_BROKEN_PIPE)
				break;
			return false;
		}
		if (bytesRead == 0)
			break;
		out.append(buffer, static_cast<int>(bytesRead));
	}
	return true;
}

} // namespace

bool runFmtCliProcess(const QString& exePath, const QString& workDir, const QStringList& args,
	const QString& input, QString& output, int& exitCode, QString& stderrText)
{
	exitCode = 1;
	output.clear();
	stderrText.clear();

	SECURITY_ATTRIBUTES sa = {};
	sa.nLength = sizeof(sa);
	sa.bInheritHandle = TRUE;

	HANDLE stdinRead = nullptr;
	HANDLE stdinWrite = nullptr;
	HANDLE stdoutRead = nullptr;
	HANDLE stdoutWrite = nullptr;
	HANDLE stderrRead = nullptr;
	HANDLE stderrWrite = nullptr;

	if (!CreatePipe(&stdinRead, &stdinWrite, &sa, 0)
		|| !CreatePipe(&stdoutRead, &stdoutWrite, &sa, 0)
		|| !CreatePipe(&stderrRead, &stderrWrite, &sa, 0))
	{
		stderrText = QStringLiteral("CreatePipe failed.");
		return false;
	}

	SetHandleInformation(stdinWrite, HANDLE_FLAG_INHERIT, 0);
	SetHandleInformation(stdoutRead, HANDLE_FLAG_INHERIT, 0);
	SetHandleInformation(stderrRead, HANDLE_FLAG_INHERIT, 0);

	STARTUPINFOW si = {};
	si.cb = sizeof(si);
	si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
	si.wShowWindow = SW_HIDE;
	si.hStdInput = stdinRead;
	si.hStdOutput = stdoutWrite;
	si.hStdError = stderrWrite;

	PROCESS_INFORMATION pi = {};
	const QString cmdLine = buildCommandLine(exePath, args);
	std::wstring cmdLineW = cmdLine.toStdWString();
	std::vector<wchar_t> cmdLineBuffer(cmdLineW.begin(), cmdLineW.end());
	cmdLineBuffer.push_back(L'\0');

	const std::wstring workDirW = QDir::toNativeSeparators(workDir).toStdWString();
	BOOL created = CreateProcessW(
		nullptr,
		cmdLineBuffer.data(),
		nullptr,
		nullptr,
		TRUE,
		CREATE_NO_WINDOW,
		nullptr,
		workDirW.c_str(),
		&si,
		&pi);

	CloseHandle(stdinRead);
	CloseHandle(stdoutWrite);
	CloseHandle(stderrWrite);

	if (!created)
	{
		CloseHandle(stdinWrite);
		CloseHandle(stdoutRead);
		CloseHandle(stderrRead);
		stderrText = QStringLiteral("CreateProcess failed (error %1).").arg(GetLastError());
		return false;
	}

	const QByteArray inputBytes = input.toUtf8();
	DWORD bytesWritten = 0;
	if (!inputBytes.isEmpty())
	{
		if (!WriteFile(stdinWrite, inputBytes.constData(), static_cast<DWORD>(inputBytes.size()), &bytesWritten, nullptr))
		{
			CloseHandle(stdinWrite);
			CloseHandle(stdoutRead);
			CloseHandle(stderrRead);
			TerminateProcess(pi.hProcess, 1);
			CloseHandle(pi.hThread);
			CloseHandle(pi.hProcess);
			stderrText = QStringLiteral("WriteFile to formatter stdin failed.");
			return false;
		}
	}
	CloseHandle(stdinWrite);

	QByteArray stdoutBytes;
	QByteArray stderrBytes;
	if (!readPipeToByteArray(stdoutRead, stdoutBytes) || !readPipeToByteArray(stderrRead, stderrBytes))
	{
		CloseHandle(stdoutRead);
		CloseHandle(stderrRead);
		TerminateProcess(pi.hProcess, 1);
		WaitForSingleObject(pi.hProcess, 5000);
		CloseHandle(pi.hThread);
		CloseHandle(pi.hProcess);
		stderrText = QStringLiteral("Failed to read formatter output.");
		return false;
	}

	CloseHandle(stdoutRead);
	CloseHandle(stderrRead);

	WaitForSingleObject(pi.hProcess, INFINITE);

	DWORD winExit = 1;
	GetExitCodeProcess(pi.hProcess, &winExit);
	CloseHandle(pi.hThread);
	CloseHandle(pi.hProcess);

	exitCode = static_cast<int>(winExit);
	output = QString::fromUtf8(stdoutBytes);
	stderrText = QString::fromUtf8(stderrBytes);
	return true;
}

#else

#include <QProcess>

bool runFmtCliProcess(const QString& exePath, const QString& workDir, const QStringList& args,
	const QString& input, QString& output, int& exitCode, QString& stderrText)
{
	QProcess proc;
	proc.setProgram(exePath);
	proc.setWorkingDirectory(workDir);
	proc.setArguments(args);
	proc.setProcessChannelMode(QProcess::SeparateChannels);
	proc.start();
	if (!proc.waitForStarted(10000))
	{
		stderrText = QStringLiteral("Failed to start formatter process.");
		return false;
	}

	proc.write(input.toUtf8());
	proc.closeWriteChannel();
	proc.waitForFinished(-1);

	exitCode = proc.exitCode();
	stderrText = QString::fromUtf8(proc.readAllStandardError());
	output = QString::fromUtf8(proc.readAllStandardOutput());
	return proc.exitStatus() == QProcess::NormalExit;
}

#endif
