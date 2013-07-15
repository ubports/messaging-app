/*
 * Copyright (C) 2012-2013 Canonical, Ltd.
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

#ifndef MESSAGINGAPPLICATION_H
#define MESSAGINGAPPLICATION_H

#include <QObject>
#include <QQuickView>
#include <QGuiApplication>

class MessagingAppDBus;

class MessagingApplication : public QGuiApplication
{
    Q_OBJECT

public:
    MessagingApplication(int &argc, char **argv);
    virtual ~MessagingApplication();

    bool setup();

public Q_SLOTS:
    void activateWindow();

private:
    void parseArgument(const QString &arg);

private Q_SLOTS:
    void onMessageReceived(const QString &message);
    void onViewStatusChanged(QQuickView::Status status);
    void onApplicationReady();
    void onMessageSendRequested(const QString &phoneNumber, const QString &message);

private:
    QQuickView *m_view;
    MessagingAppDBus *m_dbus;
    QString m_arg;
    bool m_applicationIsReady;
};

#endif // MESSAGINGAPPLICATION_H
