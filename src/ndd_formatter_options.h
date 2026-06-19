#pragma once

#include <QString>

struct NddFormatterOptions
{
	bool uppercaseKeywords = true;
	bool expandCommaLists = true;
	QString indentString = QStringLiteral("\t");
	int spacesPerTab = 4;

	explicit NddFormatterOptions(const QString& serialized = QString());
	QString toSerializedString() const;
};
