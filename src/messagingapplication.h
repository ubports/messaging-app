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

class MessagingApplication : public QGuiApplication
{
    Q_OBJECT
    Q_PROPERTY(bool fullscreen READ fullscreen WRITE setFullscreen NOTIFY fullscreenChanged)

public:
    MessagingApplication(int &argc, char **argv);
    virtual ~MessagingApplication();

    bool fullscreen() const;
    bool setup();

Q_SIGNALS:
    void fullscreenChanged();

public Q_SLOTS:
    void activateWindow();
    void parseArgument(const QString &arg);
    QString readTextFile(const QString &fileName);
    QString fileMimeType(const QString &fileName);
    void showNotificationMessage(const QString &message, const QString &icon = QString());

private Q_SLOTS:
    void setFullscreen(bool fullscreen);
    void onViewStatusChanged(QQuickView::Status status);
    void onApplicationReady();

private:
    QQuickView *m_view;
    QString m_arg;
    bool m_applicationIsReady;
};

#endif // MESSAGINGAPPLICATION_H
