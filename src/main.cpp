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

// Temporarily disable the telepathy folks backend
// as it doesn’t play well with QtFolks.
int main(int argc, char** argv)
{
    QGuiApplication::setApplicationName("Messaging App");
    QGuiApplication::setOrganizationName("com.ubuntu.messaging-app");

    MessagingApplication application(argc, argv);

    if (!application.setup()) {
        return 0;
    }

    return application.exec();
}

