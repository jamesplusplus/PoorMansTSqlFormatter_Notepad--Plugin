#pragma once

#include <QWidget>
#include <QSettings>

class Setting : public QWidget
{
	Q_OBJECT

public:
	explicit Setting(QWidget* parent, const QString& configPath);
	~Setting();

	static QString configPathForPlugin(const QString& pluginDllPath);
	static QString readOptionsSerialized(const QString& configPath);
	static void writeOptionsSerialized(const QString& configPath, const QString& serialized);

private slots:
	void onSave();

private:
	QString m_configPath;
	class QCheckBox* m_uppercaseKeywords;
	class QSpinBox* m_spacesPerTab;
	class QCheckBox* m_useSpaces;
	class QCheckBox* m_expandCommaLists;
};
