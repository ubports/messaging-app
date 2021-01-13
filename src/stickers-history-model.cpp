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
    \brief List model that stores information about most recently used stickers

    StickersHistoryModel is a list model that stores information about the most
    recently used stickers.
    Each sticker is simply identified by the sticker pack name plus the name of
    the sticker image file itself.
    Stickers are ordered by the time of last use, with the most recent first.
    By default the model stores a rolling list of the 10 most recently used
    stickers, though this number can be changed by setting the /a limit
*/
StickersHistoryModel::StickersHistoryModel(QObject* parent)
    : QAbstractListModel(parent),
      m_limit(10)
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
                                      "(sticker VARCHAR, mostRecentUse DATETIME);");
    query.prepare(statement);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

void StickersHistoryModel::populateFromDatabase()
{
    QSqlQuery query(m_database);
    QString statement = QLatin1String("SELECT sticker, mostRecentUse "
                                      "FROM history ORDER BY mostRecentUse DESC;");
    query.prepare(statement);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }

    int count = 0;
    while (query.next()) {
        HistoryEntry entry;
        entry.sticker = query.value(0).toString();
        entry.mostRecentUse = QDateTime::fromTime_t(query.value(1).toInt());
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
        roles[MostRecentUse] = "mostRecentUse";
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
    case MostRecentUse:
        return entry.mostRecentUse;
    default:
        return QVariant();
    }
}

const QString StickersHistoryModel::databasePath() const
{
    return m_database.databaseName();
}

int StickersHistoryModel::limit() const
{
    return m_limit;
}

void StickersHistoryModel::setLimit(int limit)
{
    if (limit != m_limit) {
        m_limit = limit;
        Q_EMIT limitChanged();
        removeExcessRows();
    }
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

    If an entry for the same sticker already exists, it is updated and placed
    first in the model. Otherwise a new entry is created and added at the
    begining of the model.
    If the new row count exceeds the limit, excess rows are purged.
*/
void StickersHistoryModel::add(const QString& sticker)
{
    if (sticker.isEmpty()) {
        return;
    }
    QDateTime now = QDateTime::currentDateTime();
    int index = getEntryIndex(sticker);

    if (index == -1) {
        HistoryEntry entry;
        entry.sticker = sticker;
        entry.mostRecentUse = now;
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
        insertNewEntryInDatabase(entry);
        Q_EMIT rowCountChanged();
        removeExcessRows();
    } else {
        HistoryEntry entry;
        if (index > 0) {
          beginMoveRows(QModelIndex(), index, index, QModelIndex(), 0);
        }
        entry = m_entries.takeAt(index);
        entry.mostRecentUse = now;
        m_entries.prepend(entry);
        if (index > 0) {
          endMoveRows();
        }
        QVector<int> roles;
        roles << MostRecentUse;
        Q_EMIT dataChanged(this->index(0), this->index(0), roles);
        updateExistingEntryInDatabase(m_entries.first());
    }
}

void StickersHistoryModel::removeExcessRows()
{
    if (m_limit < rowCount()) {
        beginRemoveRows(QModelIndex(), m_limit, rowCount() - 1);
        for (int i = rowCount() - 1; i >= m_limit; i--) {
            HistoryEntry item = m_entries.takeAt(i);
            removeEntryFromDatabase(item.sticker);
        }
        endRemoveRows();
        Q_EMIT rowCountChanged();
    }
}

void StickersHistoryModel::insertNewEntryInDatabase(const HistoryEntry& entry)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString statement = QLatin1String("INSERT INTO history (sticker, mostRecentUse) "
                                             "VALUES (?, ?);");
    query.prepare(statement);
    query.addBindValue(entry.sticker);
    query.addBindValue(entry.mostRecentUse.toTime_t());

    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

void StickersHistoryModel::updateExistingEntryInDatabase(const HistoryEntry& entry)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString statement = QLatin1String("UPDATE history SET mostRecentUse=?"
                                             " WHERE sticker=?;");
    query.prepare(statement);
    query.addBindValue(entry.mostRecentUse.toTime_t());
    query.addBindValue(entry.sticker);
    if (!query.exec()) {
      qWarning() << "Query failed" << query.lastError();
    }
}

void StickersHistoryModel::remove(const QString& sticker)
{

    int index = getEntryIndex(sticker);
    if (index > -1) {
        beginRemoveRows(QModelIndex(), index, index);
        removeEntryFromDatabase(sticker);
        endRemoveRows();
        Q_EMIT rowCountChanged();
    }
}

void StickersHistoryModel::removeEntryFromDatabase(const QString& sticker)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString statement = QLatin1String("DELETE FROM history WHERE sticker=?;");
    query.prepare(statement);
    query.addBindValue(sticker);
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
