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

#ifndef __STICKERS_HISTORY_MODEL_H__
#define __STICKERS_HISTORY_MODEL_H__

// Qt
#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QList>
#include <QtCore/QMutex>
#include <QtCore/QString>
#include <QtSql/QSqlDatabase>

class StickersHistoryModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString databasePath READ databasePath WRITE setDatabasePath NOTIFY databasePathChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY rowCountChanged)

    Q_ENUMS(Roles)

public:
    StickersHistoryModel(QObject* parent=0);
    ~StickersHistoryModel();

    enum Roles {
        Sticker = Qt::UserRole + 1,
        MostRecentUse
    };

    // reimplemented from QAbstractListModel
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex& parent=QModelIndex()) const;
    QVariant data(const QModelIndex& index, int role) const;

    const QString databasePath() const;
    void setDatabasePath(const QString& path);

    Q_INVOKABLE void add(const QString& sticker);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE QVariantMap get(int index) const;

Q_SIGNALS:
    void databasePathChanged() const;
    void rowCountChanged();

protected:
    struct HistoryEntry {
        QString sticker;
        QDateTime mostRecentUse;
    };
    QList<HistoryEntry> m_entries;
    int getEntryIndex(const QString& sticker) const;
    void updateExistingEntryInDatabase(const HistoryEntry& entry);

private:
    QMutex m_dbMutex;
    QSqlDatabase m_database;

    void resetDatabase(const QString& databaseName);
    void createOrAlterDatabaseSchema();
    void populateFromDatabase();
    void insertNewEntryInDatabase(const HistoryEntry& entry);
    void removeEntryFromDatabaseByUrl(const QUrl& url);
    void clearDatabase();
};

#endif // __STICKERS_HISTORY_MODEL_H__
