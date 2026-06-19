#include "setting.h"

#include <QCheckBox>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QSpinBox>
#include <QStandardPaths>
#include <QTextStream>

#include "ndd_formatter_options.h"

QString Setting::configPathForPlugin(const QString& pluginDllPath)
{
	Q_UNUSED(pluginDllPath);
	const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
		+ QDir::separator() + QStringLiteral("ndd-tsqlformatter");
	QDir().mkpath(dir);
	return dir + QDir::separator() + QStringLiteral("formatter.ini");
}

QString Setting::readOptionsSerialized(const QString& configPath)
{
	QFile file(configPath);
	if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
		return QString();

	QTextStream in(&file);
	in.setCodec("UTF-8");
	while (!in.atEnd())
	{
		QString line = in.readLine().trimmed();
		if (line.startsWith(QStringLiteral("OptionsSerialized="), Qt::CaseInsensitive))
			return line.mid(QStringLiteral("OptionsSerialized=").size());
	}
	return QString();
}

void Setting::writeOptionsSerialized(const QString& configPath, const QString& serialized)
{
	QFileInfo info(configPath);
	QDir().mkpath(info.absolutePath());

	QFile file(configPath);
	if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate))
		return;

	QTextStream out(&file);
	out.setCodec("UTF-8");
	out << "OptionsSerialized=" << serialized << "\n";
}

Setting::Setting(QWidget* parent, const QString& configPath)
	: QWidget(parent), m_configPath(configPath)
{
	auto* layout = new QVBoxLayout(this);

	m_uppercaseKeywords = new QCheckBox(tr("Uppercase keywords"), this);
	m_expandCommaLists = new QCheckBox(tr("Expand comma lists"), this);
	m_useSpaces = new QCheckBox(tr("Indent with spaces (not tabs)"), this);

	auto* spacesRow = new QHBoxLayout();
	spacesRow->addWidget(new QLabel(tr("Spaces per tab:"), this));
	m_spacesPerTab = new QSpinBox(this);
	m_spacesPerTab->setRange(1, 16);
	m_spacesPerTab->setValue(4);
	spacesRow->addWidget(m_spacesPerTab);
	spacesRow->addStretch();

	layout->addWidget(m_uppercaseKeywords);
	layout->addWidget(m_expandCommaLists);
	layout->addWidget(m_useSpaces);
	layout->addLayout(spacesRow);

	auto* saveBtn = new QPushButton(tr("Save"), this);
	layout->addWidget(saveBtn);
	layout->addStretch();

	connect(saveBtn, &QPushButton::clicked, this, &Setting::onSave);

	// Defaults match TSqlStandardFormatterOptions C# defaults
	m_uppercaseKeywords->setChecked(true);
	m_expandCommaLists->setChecked(true);
	m_useSpaces->setChecked(false);

	const QString serialized = readOptionsSerialized(m_configPath);
	if (!serialized.isEmpty())
	{
		NddFormatterOptions opts(serialized);
		m_uppercaseKeywords->setChecked(opts.uppercaseKeywords);
		m_expandCommaLists->setChecked(opts.expandCommaLists);
		m_useSpaces->setChecked(opts.indentString == QStringLiteral(" "));
		m_spacesPerTab->setValue(opts.spacesPerTab);
	}
}

Setting::~Setting() = default;

void Setting::onSave()
{
	NddFormatterOptions opts;
	opts.uppercaseKeywords = m_uppercaseKeywords->isChecked();
	opts.expandCommaLists = m_expandCommaLists->isChecked();
	opts.indentString = m_useSpaces->isChecked() ? QStringLiteral(" ") : QStringLiteral("\t");
	opts.spacesPerTab = m_spacesPerTab->value();

	writeOptionsSerialized(m_configPath, opts.toSerializedString());
	close();
}
