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
#include <QtCore/QMutexLocker>
#include <QtSql/QSqlQuery>

#define CONNECTION_NAME "messaging-app-stickers-history"

/*!
    \class StickersHistoryModel
    \brief List model that stores information about the most used stickers

    StickersHistoryModel is a list model that stores information about how many
    times a certain sticker was used, and when it was most recently used.
    Each sticker is simply identified by the sticker pack name and the name of
    the sticker file itself.
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
    QSqlQuery createQuery(m_database);
    QString query = QLatin1String("CREATE TABLE IF NOT EXISTS history "
                                  "(sticker VARCHAR, uses INTEGER, lastUse DATETIME);");
    createQuery.prepare(query);
    createQuery.exec();
}

void StickersHistoryModel::populateFromDatabase()
{
    QSqlQuery populateQuery(m_database);
    QString query = QLatin1String("SELECT sticker, uses, lastUse "
                                  "FROM history ORDER BY uses DESC;");
    populateQuery.prepare(query);
    populateQuery.exec();

    int count = 0;
    while (populateQuery.next()) {
        HistoryEntry entry;
        entry.sticker = populateQuery.value(0).toString();
        entry.visits = populateQuery.value(1).toInt();
        entry.lastVisit = QDateTime::fromTime_t(populateQuery.value(2).toInt());
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
        roles[Visits] = "visits";
        roles[LastVisitDate] = "lastVisitDate";
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
    case Visits:
        return entry.visits;
    case LastVisitDate:
        return entry.lastVisit.toLocalTime().date();
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
    QDateTime now = QDateTime::currentDateTimeUtc();
    int index = getEntryIndex(sticker);
    if (index == -1) {
        HistoryEntry entry;
        entry.sticker = sticker;
        entry.visits = 1;
        entry.lastVisit = now;
        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();
        insertNewEntryInDatabase(entry);
        Q_EMIT rowCountChanged();
    } else {
        QVector<int> roles;
        roles << Visits;
        if (index == 0) {
            HistoryEntry& entry = m_entries.first();
            count = ++entry.visits;
            if (now != entry.lastVisit) {
                entry.lastVisit = now;
                roles << LastVisitDate;
            }
        } else {
            beginMoveRows(QModelIndex(), index, index, QModelIndex(), 0);
            HistoryEntry entry = m_entries.takeAt(index);
            count = ++entry.visits;
            if (now != entry.lastVisit) {
                if (now.date() != entry.lastVisit.date()) {
                    roles << LastVisitDate;
                }
                entry.lastVisit = now;
                roles << LastVisitDate;
            }
            m_entries.prepend(entry);
            endMoveRows();
        }
        Q_EMIT dataChanged(this->index(0, 0), this->index(0, 0), roles);
        updateExistingEntryInDatabase(m_entries.first());
    }
    return count;
}

void StickersHistoryModel::insertNewEntryInDatabase(const HistoryEntry& entry)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString insertStatement = QLatin1String("INSERT INTO history (stickers, uses, lastUse) "
                                                   "VALUES (?, 1, ?);");
    query.prepare(insertStatement);
    query.addBindValue(entry.sticker);
    query.addBindValue(entry.lastVisit.toTime_t());
    query.exec();
}

void StickersHistoryModel::updateExistingEntryInDatabase(const HistoryEntry& entry)
{
    QMutexLocker ml(&m_dbMutex);
    QSqlQuery query(m_database);
    static QString updateStatement = QLatin1String("UPDATE history SET visits=?, lastVisit=? "
                                                   "WHERE sticker=?;");
    query.prepare(updateStatement);
    query.addBindValue(entry.visits);
    query.addBindValue(entry.lastVisit.toTime_t());
    query.addBindValue(entry.sticker);
    query.exec();
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
    QSqlQuery deleteQuery(m_database);
    QString deleteStatement = QLatin1String("DELETE FROM history;");
    deleteQuery.prepare(deleteStatement);
    deleteQuery.exec();
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
