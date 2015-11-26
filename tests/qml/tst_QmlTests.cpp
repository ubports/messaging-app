/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * Authors:
 *  Arthur Mello <arthur.mello@canonical.com>
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

class TestContext : public QObject
{
    Q_OBJECT

public:
    explicit TestContext(QObject* parent=0)
        : QObject(parent)
    {}
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

int main(int argc, char** argv)
{
    qmlRegisterSingletonType<FileOperations>("messagingapp.private", 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterSingletonType<TestContext>("messagingtest.private", 0, 1, "TestContext", TestContext_singleton_factory);

    return quick_test_main(argc, argv, "QmlTests", 0);
}

#include "tst_QmlTests.moc"
