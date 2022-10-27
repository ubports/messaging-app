/*
 * Copyright (C) 2012-2015 Canonical, Ltd.
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
#include <QStringList>

class MessagingApplication : public QGuiApplication
{
    Q_OBJECT
    Q_PROPERTY(bool fullscreen READ fullscreen WRITE setFullscreen NOTIFY fullscreenChanged)
    Q_PROPERTY(bool defaultStartupMode READ defaultStartupMode CONSTANT)

public:
    MessagingApplication(int &argc, char **argv);
    virtual ~MessagingApplication();

    bool fullscreen() const;
    bool setup();
    bool defaultStartupMode() const;

Q_SIGNALS:
    void fullscreenChanged();
    void startChatRequested(QVariantMap properties);
    void startNewMessageRequested();

public Q_SLOTS:
    void activateWindow();
    void parseArgument(const QString &arg);
    QString readTextFile(const QString &fileName);
    QString fileMimeType(const QString &fileName);
    void showNotificationMessage(const QString &message, const QString &icon = QString());
    QObject *findMessagingChild(const QString &objectName);
    QObject *findMessagingChild(const QString &objectName, const QString &property, const QVariant &value);
    QUrl delegateFromProtocol(const QUrl &delegate, const QString &protocol);

private Q_SLOTS:
    void setFullscreen(bool fullscreen);

    void onViewStatusChanged(QQuickView::Status status);
    void onApplicationReady();
private:
    QQuickView *m_view;
    QString m_arg;
    bool m_applicationIsReady;
    bool mDefaultStartupMode;
    QStringList mValidSchemes;
};

#endif // MESSAGINGAPPLICATION_H
