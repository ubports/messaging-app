/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * Authors:
 *  Arthur Mello <arthur.mello@canonical.com>
 *  Ugo Riboni <ugo.riboni@canonical.com>
 *
 * This file is part of messaging-app.
 *
 * messaging-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * messaging-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Qt
#include <QtQuickTest/QtQuickTest>
#include <QtQml/QtQml>

// local
#include "fileoperations.h"
#include "stickers-history-model.h"

class TestContext : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString testDir READ testDir CONSTANT)

public:
    explicit TestContext(QObject* parent=0)
        : QObject(parent)
    {
        QDir dir(m_temporary.path());
        dir.mkpath("stickers");
    }

    QString testDir() const
    {
        return m_temporary.path();
    }

    QTemporaryDir m_temporary;
};

static QObject* TestContext_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new TestContext();
}

static QObject* FileOperations_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new FileOperations();
}

static QObject* StickersHistoryModel_singleton_factory(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(engine);
    Q_UNUSED(scriptEngine);
    return new StickersHistoryModel();
}

int main(int argc, char** argv)
{
    const char* uri = "messagingapp.private";
    qmlRegisterSingletonType<FileOperations>(uri, 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterSingletonType<StickersHistoryModel>(uri, 0, 1, "StickersHistoryModel", StickersHistoryModel_singleton_factory);

    const char* testUri = "messagingapptest.private";
    qmlRegisterSingletonType<TestContext>(testUri, 0, 1, "TestContext", TestContext_singleton_factory);

    return quick_test_main(argc, argv, "QmlTests", 0);
}

#include "tst_QmlTests.moc"
