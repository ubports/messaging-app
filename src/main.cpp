/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
 *
 * Authors:
 *  Olivier Tilloy <olivier.tilloy@canonical.com>
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
#include <QDebug>
#include <QString>
#include <QTemporaryFile>
#include <QTextStream>

// libc
#include <cerrno>
#include <cstdlib>
#include <cstring>

// local
#include "messagingapplication.h"
#include "config.h"

// WORKAROUND: to make easy to debug apps
#include <QtQml/QQmlDebuggingEnabler>
static QQmlDebuggingEnabler debuggingEnabler(false);

// Temporarily disable the telepathy folks backend
// as it doesn’t play well with QtFolks.
int main(int argc, char** argv)
{
    QCoreApplication::setOrganizationName("com.ubuntu.messaging-app");
    QCoreApplication::setApplicationName("MessagingApp");

    MessagingApplication application(argc, argv);

    qDebug() << "Starting application from src/main.cpp";

    if (!application.setup()) {
        qDebug() << "application setup failed";
        return 0;
    }

    return application.exec();
}

