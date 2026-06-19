#include "ndd_formatter_options.h"

#include <QStringList>

NddFormatterOptions::NddFormatterOptions(const QString& serialized)
{
	if (serialized.isEmpty())
		return;

	const QStringList pairs = serialized.split(QLatin1Char(','), QString::SkipEmptyParts);
	for (const QString& kvp : pairs)
	{
		const int eq = kvp.indexOf(QLatin1Char('='));
		if (eq <= 0)
			continue;
		const QString key = kvp.left(eq);
		const QString value = kvp.mid(eq + 1);

		if (key == QLatin1String("UppercaseKeywords"))
			uppercaseKeywords = (value.compare(QLatin1String("True"), Qt::CaseInsensitive) == 0);
		else if (key == QLatin1String("ExpandCommaLists"))
			expandCommaLists = (value.compare(QLatin1String("True"), Qt::CaseInsensitive) == 0);
		else if (key == QLatin1String("IndentString"))
			indentString = value;
		else if (key == QLatin1String("SpacesPerTab"))
			spacesPerTab = value.toInt();
	}
}

QString NddFormatterOptions::toSerializedString() const
{
	QStringList parts;
	if (!uppercaseKeywords)
		parts << QStringLiteral("UppercaseKeywords=False");
	if (!expandCommaLists)
		parts << QStringLiteral("ExpandCommaLists=False");
	if (indentString != QLatin1String("\t"))
		parts << QStringLiteral("IndentString=%1").arg(indentString);
	if (spacesPerTab != 4)
		parts << QStringLiteral("SpacesPerTab=%1").arg(spacesPerTab);
	return parts.join(QLatin1Char(','));
}
