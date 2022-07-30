/*
 * Copyright (C) 2012-2016 Canonical, Ltd.
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

#include "messagingapplication.h"
#include "audiorecorder.h"
#include "fileoperations.h"
#include "stickers-history-model.h"
#include "stickers-pack-model.h"

#include <libnotify/notify.h>

#include <QDir>
#include <QUrl>
#include <QUrlQuery>
#include <QDebug>
#include <QDir>
#include <QStringList>
#include <QQuickItem>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickView>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusConnectionInterface>
#include <QLibrary>
#include "config.h"
#include <QQmlEngine>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QVersitReader>

#define MESSAGING_FULLSCREEN_FLAG 0x00800000

using namespace QtVersit;
#define Pair QPair<QString,QString>

namespace C {
#include <libintl.h>
}

static void printUsage(const QStringList& arguments)
{
    qDebug() << "usage:"
             << arguments.at(0).toUtf8().constData()
             << "[message:///PHONE_NUMBER]"
             << "[sms:///PHONE_NUMBER?body=<body-text>]"
             << "[--fullscreen]"
             << "[--help]"
             << "[-testability]";
}

//this is necessary to work on desktop
//On desktop use: export MESSAGING_APP_ICON_THEME=ubuntu-mobile
static void installIconPath()
{
    QByteArray iconTheme = qgetenv("MESSAGING_APP_ICON_THEME");
    if (!iconTheme.isEmpty()) {
        QIcon::setThemeName(iconTheme);
    }
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

MessagingApplication::MessagingApplication(int &argc, char **argv)
    : QGuiApplication(argc, argv), m_view(0), m_applicationIsReady(false)
{
}

bool MessagingApplication::fullscreen() const
{
    // FIXME: Correct flag to be used will be defined in future releases
    return m_view->flags() & static_cast <Qt::WindowFlags> (MESSAGING_FULLSCREEN_FLAG);
}

bool MessagingApplication::setup()
{
    QDBusConnection::sessionBus().registerService("com.canonical.MessagingApp");
    installIconPath();
    static QList<QString> validSchemes;
    bool fullScreen = false;

    if (validSchemes.isEmpty()) {
        validSchemes << "message" << "sms";
    }

    QStringList arguments = this->arguments();

    if (arguments.contains("--help")) {
        printUsage(arguments);
        return false;
    }

    if (arguments.contains("--fullscreen")) {
        arguments.removeAll("--fullscreen");
        fullScreen = true;
    }

    // The testability driver is only loaded by QApplication but not by QGuiApplication.
    // However, QApplication depends on QWidget which would add some unneeded overhead => Let's load the testability driver on our own.
    if (arguments.contains("-testability") || qgetenv("QT_LOAD_TESTABILITY") == "1") {
        arguments.removeAll("-testability");
        QLibrary testLib(QLatin1String("qttestability"));
        if (testLib.load()) {
            typedef void (*TasInitialize)(void);
            TasInitialize initFunction = (TasInitialize)testLib.resolve("qt_testability_init");
            if (initFunction) {
                initFunction();
            } else {
                qCritical("Library qttestability resolve failed!");
            }
        } else {
            qCritical("Library qttestability load failed!");
        }
    }

    /* Ubuntu APP Manager gathers info on the list of running applications from the .desktop
       file specified on the command line with the desktop_file_hint switch, and will also pass a stage hint
       So app will be launched like this:

       /usr/bin/messaging-app --desktop_file_hint=/usr/share/applications/messaging-app.desktop
                          --stage_hint=main_stage

       So remove whatever --arg still there before continue parsing
    */
    for (int i = arguments.count() - 1; i >=0; --i) {
        if (arguments[i].startsWith("--")) {
            arguments.removeAt(i);
        }
    }

    if (arguments.size() == 2) {
        QUrl uri(arguments.at(1));
        if (validSchemes.contains(uri.scheme())) {
            m_arg = arguments.at(1);
        }
    }

    m_view = new QQuickView();
    QObject::connect(m_view, SIGNAL(statusChanged(QQuickView::Status)), this, SLOT(onViewStatusChanged(QQuickView::Status)));
    QObject::connect(m_view->engine(), SIGNAL(quit()), SLOT(quit()));
    m_view->setResizeMode(QQuickView::SizeRootObjectToView);
    m_view->setTitle("Messaging");
    m_view->rootContext()->setContextProperty("application", this);
    m_view->rootContext()->setContextProperty("i18nDirectory", I18N_DIRECTORY);
    m_view->rootContext()->setContextProperty("view", m_view);
    m_view->engine()->addImportPath(UNITY8_QML_PATH);

    // check if there is a contacts backend override
    QString contactsBackend = qgetenv("QTCONTACTS_MANAGER_OVERRIDE");
    if (!contactsBackend.isEmpty()) {
        qDebug() << "Overriding the contacts backend, using:" << contactsBackend;
        m_view->rootContext()->setContextProperty("QTCONTACTS_MANAGER_OVERRIDE", contactsBackend);
    }

    QDir dataLocation(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    m_view->rootContext()->setContextProperty("dataLocation", dataLocation.absolutePath());
    dataLocation.mkpath("stickers");
    const char* uri = "messagingapp.private";
    qmlRegisterType<AudioRecorder>(uri, 0, 1, "AudioRecorder");
    qmlRegisterType<StickersPackModel>(uri, 0, 1, "StickersPackModel");
    qmlRegisterSingletonType<FileOperations>(uri, 0, 1, "FileOperations", FileOperations_singleton_factory);
    qmlRegisterSingletonType<StickersHistoryModel>(uri, 0, 1, "StickersHistoryModel", StickersHistoryModel_singleton_factory);

    // used by autopilot tests to load vcards during tests
    QByteArray testData = qgetenv("QTCONTACTS_PRELOAD_VCARD");
    m_view->rootContext()->setContextProperty("QTCONTACTS_PRELOAD_VCARD", testData);

    QString pluginPath = ubuntuPhonePluginPath();
    if (!pluginPath.isNull()) {
        m_view->engine()->addImportPath(pluginPath);
    }

    m_view->engine()->setBaseUrl(QUrl::fromLocalFile(messagingAppDirectory()));
    m_view->setSource(QUrl::fromLocalFile(QString("%1/messaging-app.qml").arg(messagingAppDirectory())));
    if (fullScreen) {
        m_view->showFullScreen();
    } else {
        m_view->show();
    }
    notify_init(C::gettext("Messaging application"));

    return true;
}

MessagingApplication::~MessagingApplication()
{
    if (m_view) {
        delete m_view;
    }
}

void MessagingApplication::setFullscreen(bool fullscreen)
{
    // FIXME: Correct flag to be used will be defined in future releases
    if (fullscreen) {
        m_view->setFlags(m_view->flags() | static_cast <Qt::WindowFlags> (MESSAGING_FULLSCREEN_FLAG));
    } else {
        m_view->setFlags(m_view->flags() & !static_cast <Qt::WindowFlags> (MESSAGING_FULLSCREEN_FLAG));
    }

    Q_EMIT fullscreenChanged();
}

void MessagingApplication::onViewStatusChanged(QQuickView::Status status)
{
    if (status != QQuickView::Ready) {
        return;
    }
    onApplicationReady();
}

void MessagingApplication::onApplicationReady()
{
    m_applicationIsReady = true;
    parseArgument(m_arg);
    m_arg.clear();
}

void MessagingApplication::parseArgument(const QString &arg)
{
    if (arg.isEmpty()) {
        return;
    }

    // QUrl does not recognize "sms://" url, so lets convert it to "sms:"
    QRegExp rx(":/{1,}");
    QString normalizedArg = QString(arg).replace(rx,":");

    QVariantMap properties;
    QUrl url(normalizedArg);
    QString scheme = url.scheme();
    QString value = url.path();
    // Remove the first "/" if needed. We have possible scenarios:
    // message:///phonenumber and message:phonenumber, sms:///phonenumber and sms:phonenumber
    if (value.startsWith("/")) {
        value = value.right(value.length()-1);
        if (!value.isEmpty()) {
            QStringList participantIds = value.split(";");
            properties["participantIds"] = participantIds;
        }
    } else {
        properties["participantIds"] = QStringList() << value;
    }
    QUrlQuery query(url);
    Q_FOREACH(const Pair &item, query.queryItems(QUrl::FullyDecoded)) {
        if (item.first == "text") {
            properties["text"] = item.second;
        }
        if (item.first == "accountId") {
            properties["accountId"] = item.second;
        }
        if (item.first == "chatType") {
            properties["chatType"] = item.second.toInt();
        }
        if (item.first == "threadId") {
            properties["threadId"] = item.second;
        }
    }

    QQuickItem *mainView = m_view->rootObject();
    if (!mainView) {
        return;
    }

    if (scheme == "message" || scheme == "sms") {
        if (value.isEmpty() && properties.isEmpty()) {
            QMetaObject::invokeMethod(mainView, "startNewMessage");
        } else {
            QMetaObject::invokeMethod(mainView, "startChat", Q_ARG(QVariant, properties));
        }
    }
}

void MessagingApplication::activateWindow()
{
    if (m_view) {
        m_view->raise();
        m_view->requestActivate();
    }
}

QString MessagingApplication::readTextFile(const QString &fileName) {
    QString text;
    QFile file(fileName);
    if (!file.open(QIODevice::ReadOnly)) {
        return QString();
    }
    text = QString(file.readAll());
    file.close();
    return text;
}

QString MessagingApplication::fileMimeType(const QString &fileName) {
    QMimeDatabase db;
    QMimeType type = db.mimeTypeForFile(fileName);
    return type.name();
}

void MessagingApplication::showNotificationMessage(const QString &message, const QString &icon)
{
    NotifyNotification *notification = notify_notification_new(message.toStdString().c_str(),
                                                               NULL,
                                                               icon.toStdString().c_str());
    notify_notification_set_urgency(notification, NOTIFY_URGENCY_LOW);

    GError *error = NULL;
    if (!notify_notification_show(notification, &error)) {
        qWarning() << "Failed to show notification:" << error->message;
        g_error_free (error);
    }
    g_object_unref(G_OBJECT(notification));
}

// find QQuickItem childs
inline QObject *findRecursiveChild(QQuickItem *object, const QString &objectName, const QString &property = QString::null, const QVariant &value = QVariant())
{
    // check the object
    if (!object) {
        return NULL;
    }

    // check the direct children first
    Q_FOREACH(QQuickItem *child, object->childItems()) {
        if (child->objectName() == objectName) {
            if (property.isEmpty()) {
                return child;
            } else if (child->property(property.toLatin1().data()) == value) {
                return child;
            }
        }
    }

    // now check the grand-children
    Q_FOREACH(QQuickItem *child, object->childItems()) {
        QObject *result = findRecursiveChild(child, objectName, property, value);
        if (result) {
            return result;
        }
    }

    return NULL;
}

QObject *MessagingApplication::findMessagingChild(const QString &objectName)
{
    return findRecursiveChild(m_view->rootObject(), objectName);
}

QObject *MessagingApplication::findMessagingChild(const QString &objectName, const QString &property, const QVariant &value)
{
    return findRecursiveChild(m_view->rootObject(), objectName, property, value);
}

// Check if a delegate file exists with protocol name as suffix
// If true use the specialized delegate
// If false use the default delegate
QUrl MessagingApplication::delegateFromProtocol(const QUrl &delegate, const QString &protocol)
{
    if (protocol.isEmpty())
        return delegate;

    QString localFile = delegate.toLocalFile();
    QString fileNameWithProtocol = QString("%1_%2.qml")
            .arg(localFile.mid(0, localFile.lastIndexOf(".")))
            .arg(protocol.toLower());

    if (QFile::exists(fileNameWithProtocol))
        return fileNameWithProtocol;
    return delegate;
}
