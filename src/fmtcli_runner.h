#pragma once

#include <QString>
#include <QStringList>

bool runFmtCliProcess(const QString& exePath, const QString& workDir, const QStringList& args,
	const QString& input, QString& output, int& exitCode, QString& stderrText);
