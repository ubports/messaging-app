/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
 *
 * Authors:
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

#include "messagingappdbus.h"
#include "messagingappadaptor.h"

// Qt
#include <QtDBus/QDBusConnection>

static const char* DBUS_SERVICE = "com.canonical.MessagingApp";
static const char* DBUS_OBJECT_PATH = "/com/canonical/MessagingApp";

MessagingAppDBus::MessagingAppDBus(QObject* parent) : QObject(parent)
{
}

MessagingAppDBus::~MessagingAppDBus()
{
}

bool
MessagingAppDBus::connectToBus()
{
    bool ok = QDBusConnection::sessionBus().registerService(DBUS_SERVICE);
    if (!ok) {
        return false;
    }
    new MessagingAppAdaptor(this);
    QDBusConnection::sessionBus().registerObject(DBUS_OBJECT_PATH, this);

    return true;
}

void
MessagingAppDBus::ShowMessages(const QString &number)
{
    Q_EMIT request(QString("messages://%1").arg(number));
}

void MessagingAppDBus::ShowMessage(const QString &messageId)
{
    Q_EMIT request(QString("messageId://%1").arg(messageId));
}

void MessagingAppDBus::NewMessage()
{
    Q_EMIT request(QString("messages://"));
}

void MessagingAppDBus::SendMessage(const QString &number, const QString &message)
{
    Q_EMIT messageSendRequested(number, message);
}

void MessagingAppDBus::SendAppMessage(const QString &message)
{
    Q_EMIT request(message);
}
