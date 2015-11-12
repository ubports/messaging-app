/*
 * Copyright 2015 Canonical Ltd.
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

#include "stickers-history-model.h"

// Qt
#include <QtCore/QDebug>
#include <QtCore/QMutexLocker>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>

#define CONNECTION_NAME "messaging-app-stickers-history"

/*!
    \class StickersHistoryModel
    \brief List model that stores information about the most used stickers

    StickersHistoryModel is a list model that stores information about how many
    times a certain sticker was used.
    Each sticker is simply identified by the sticker pack name plus the name of
    the sticker image file itself.
*/
StickersHistoryModel::StickersHistoryModel(QObject* parent)
    : QAbstractListModel(parent)
{
    m_database = QSqlDatabase::addDatabase(QLatin1String("QSQLITE"), CONNECTION_NAME);
}

StickersHistoryModel::~StickersHistoryModel()
{
    m_database.close();
    m_database = QSqlDatabase();
    QSqlDatabase::removeDatabase(CONNECTION_NAME);
}

void StickersHistoryModel::resetDatabase(const QString& databaseName)
{
    beginResetModel();
    m_entries.clear();
    m_database.close();
    m_database.setDatabaseName(databaseName);
    m_database.open();
    createOrAlterDatabaseSchema();
    endResetModel();
    populateFromDatabase();
}

void StickersHistoryModel::createOrAlterDatabaseSchema()
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    QString statement = QLatin1String("CREATE TABLE IF NOT EXISTS history "
                                      "(sticker VARCHAR, uses INTEGER);");
    query.prepare(statement);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

void StickersHistoryModel::populateFromDatabase()
{
    QSqlQuery query(m_database);
    QString statement = QLatin1String("SELECT sticker, uses FROM history;");
    query.prepare(statement);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }

    int count = 0;
    while (query.next()) {
        HistoryEntry entry;
        entry.sticker = query.value(0).toString();
        entry.uses = query.value(1).toInt();
        beginInsertRows(QModelIndex(), count, count);
        m_entries.append(entry);
        endInsertRows();
        ++count;
    }
}

QHash<int, QByteArray> StickersHistoryModel::roleNames() const
{
    static QHash<int, QByteArray> roles;
    if (roles.isEmpty()) {
        roles[Sticker] = "sticker";
        roles[Uses] = "uses";
    }
    return roles;
}

int StickersHistoryModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent);
    return m_entries.count();
}

QVariant StickersHistoryModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return QVariant();
    }
    const HistoryEntry& entry = m_entries.at(index.row());
    switch (role) {
    case Sticker:
        return entry.sticker;
    case Uses:
        return entry.uses;
    default:
        return QVariant();
    }
}

const QString StickersHistoryModel::databasePath() const
{
    return m_database.databaseName();
}

void StickersHistoryModel::setDatabasePath(const QString& path)
{
    if (path != databasePath()) {
        if (path.isEmpty()) {
            resetDatabase(":memory:");
        } else {
            resetDatabase(path);
        }
        Q_EMIT databasePathChanged();
    }
}

int StickersHistoryModel::getEntryIndex(const QString& sticker) const
{
    for (int i = 0; i < m_entries.count(); ++i) {
        if (m_entries.at(i).sticker == sticker) {
            return i;
        }
    }
    return -1;
}

/*!
    Add an entry to the model.

    If an entry for the same sticker already exists, it is updated.
    Otherwise a new entry is created and added to the model.

    Return the total number of uses for the sticker.
*/
int StickersHistoryModel::add(const QString& sticker)
{
    if (sticker.isEmpty()) {
        return 0;
    }
    int count = 1;
    int index = getEntryIndex(sticker);

    if (index == -1) {
        HistoryEntry entry;
        entry.sticker = sticker;
        entry.uses = 1;
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
        insertNewEntryInDatabase(entry);
        Q_EMIT rowCountChanged();
    } else {
        QVector<int> roles;
        roles << Uses;
        HistoryEntry entry = m_entries.at(index);
        count = ++entry.uses;
        m_entries.replace(index, entry);
        Q_EMIT dataChanged(this->index(index, 0), this->index(index, 0), roles);
        updateExistingEntryInDatabase(m_entries.first());
    }
    return count;
}

void StickersHistoryModel::insertNewEntryInDatabase(const HistoryEntry& entry)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString statement = QLatin1String("INSERT INTO history (sticker, uses) "
                                             "VALUES (?, 1);");
    query.prepare(statement);
    query.addBindValue(entry.sticker);

    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

void StickersHistoryModel::updateExistingEntryInDatabase(const HistoryEntry& entry)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString statement = QLatin1String("UPDATE history SET uses=? WHERE sticker=?;");
    query.prepare(statement);
    query.addBindValue(entry.uses);
    query.addBindValue(entry.sticker);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

void StickersHistoryModel::clearAll()
{
    if (!m_entries.isEmpty()) {
        beginResetModel();
        m_entries.clear();
        endResetModel();
        clearDatabase();
        Q_EMIT rowCountChanged();
    }
}

void StickersHistoryModel::clearDatabase()
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    QString statement = QLatin1String("DELETE FROM history;");
    query.prepare(statement);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

QVariantMap StickersHistoryModel::get(int i) const
{
    QVariantMap item;
    QHash<int, QByteArray> roles = roleNames();

    QModelIndex modelIndex = index(i, 0);
    if (modelIndex.isValid()) {
        Q_FOREACH(int role, roles.keys()) {
            QString roleName = QString::fromUtf8(roles.value(role));
            item.insert(roleName, data(modelIndex, role));
        }
    }
    return item;
}
