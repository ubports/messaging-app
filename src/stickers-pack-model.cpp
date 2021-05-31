/*
 * Copyright 2021 Ubports Foundation
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
#include "stickers-pack-model.h"
#include "stickers-history-model.h"
#include "fileoperations.h"
#include <QDir>
#include <QDirIterator>
#include <QDebug>
#include <QRegularExpression>
#include <QUuid>

StickerPack::StickerPack(const QString &name, const QString &path, int count, const QString &thumbnail)
    : m_name(name), m_path(path), m_count(count), m_thumbnail(thumbnail)
{
}

QString StickerPack::name() const
{
    return m_name;
}

QString StickerPack::path() const
{
    return m_path;
}

int StickerPack::count() const
{
    return m_count;
}

void StickerPack::setCount(int count)
{
    m_count = count;
}


QString StickerPack::thumbnail() const
{
    return m_thumbnail;
}

void StickerPack::setThumbnail(QString thumbnail)
{
    m_thumbnail = thumbnail;
}



StickersPackModel::StickersPackModel(QObject *parent) : QAbstractListModel(parent)
{
}

const QString StickersPackModel::stickerPath() const
{
    return m_stickerPath;
}

void StickersPackModel::setStickerPath(const QString &path)
{

    if (path != m_stickerPath) {
        m_stickerPath = path;
        populate();
        Q_EMIT stickerPathChanged();
    }
}

StickerPack StickersPackModel::generatePack() {

    QString randomString = QUuid::createUuid().toString();
    randomString.remove(QRegularExpression("{|}|-")); // we want only hex numbers

    QString dirPath = QDir(m_stickerPath).filePath(randomString);
    QDir newDir(dirPath);
    if (!newDir.exists()) {
        qDebug() << "created dir:" << dirPath;
        newDir.mkpath(dirPath);
    }

    qDebug() << "created pack:" << randomString <<  dirPath;
    return StickerPack(randomString, dirPath, 0, "");

}

void StickersPackModel::createPack()
{
    beginInsertRows(QModelIndex(), m_stickerPacks.count(), m_stickerPacks.count());
    StickerPack sp = generatePack();
    m_stickerPacks.append(sp);
    endInsertRows();
    Q_EMIT rowCountChanged();
    Q_EMIT packCreated(sp.name());
}


QVariantMap StickersPackModel::get(int i) const
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

void StickersPackModel::removePack(const QString& packName)
{
    int index = getEntryIndex(packName);
    if (index > -1) {
        const StickerPack& sp = m_stickerPacks.at(index);
        beginRemoveRows(QModelIndex(), index, index);

        QDir dir(sp.path());
        qDebug() << "removed dir:" << sp.path();
        if (dir.exists()) {
            dir.removeRecursively();
        }

        m_stickerPacks.removeAt(index);

        endRemoveRows();
        Q_EMIT rowCountChanged();
        Q_EMIT packRemoved(packName);

    }

}

void StickersPackModel::addSticker(const QString &packName, const QString &stickerPath)
{
    int idx = getEntryIndex(packName);
    if (idx > -1) {
        StickerPack& sp = m_stickerPacks[idx];

        QFileInfo sourceFile(stickerPath);
        QString destFile = QDir(sp.path()).filePath(sourceFile.fileName());
        if(QFile::exists(destFile)) QFile::remove(destFile);
        QFile::copy(stickerPath, destFile);

        QVector<int> roles;
        roles << StickerPackCountRole;

        if (sp.count() == 0) {
            sp.setThumbnail(destFile);
            roles << StickerPackThumbnailRole;
        }
        sp.setCount(sp.count() + 1);

        Q_EMIT dataChanged(this->index(idx), this->index(idx), roles);

    }
}

void StickersPackModel::removeSticker(const QString &packName, const QString &stickerPath)
{
    int idx = getEntryIndex(packName);
    if (idx > -1) {
        StickerPack& sp = m_stickerPacks[idx];

        if(QFile::exists(stickerPath)) {
            QFile::remove(stickerPath);
        }

        if (sp.count() == 1) {
            removePack(packName);
        } else {
            sp.setCount(sp.count() - 1);
            QVector<int> roles;
            roles << StickerPackCountRole;
            Q_EMIT dataChanged(this->index(idx), this->index(idx), roles);
        }

    }
}

int StickersPackModel::getEntryIndex(const QString& packName)
{
    for (int i = 0; i < m_stickerPacks.count(); ++i) {
        if (m_stickerPacks.at(i).name() == packName) {
            return i;
        }
    }
    return -1;
}

void StickersPackModel::populate()
{

    QStringList imagefilter = QStringList() << "*.png" <<  "*.gif" << "*.webp" << "*.jpg";

    beginResetModel();
    m_stickerPacks.clear();

    bool hasEmptyPack = false;
    QDirIterator dirIter(m_stickerPath, QDir::Dirs | QDir::NoDotAndDotDot);
    while (dirIter.hasNext()) {
        dirIter.next();

        QDirIterator it(dirIter.filePath(), imagefilter, QDir::Files | QDir::NoDotAndDotDot);
        int count = 0;
        QString thumbnail;
        while (it.hasNext()) {
            it.next();
            if (count == 0) {
                thumbnail = it.filePath();
            }
            count++;

        }
        if (count == 0) hasEmptyPack = true;
        m_stickerPacks.append(StickerPack(dirIter.fileName(), dirIter.filePath(), count, thumbnail));
    }

    if (!hasEmptyPack && !m_stickerPath.isEmpty()) {
        StickerPack newSp = generatePack();
        m_stickerPacks.append(newSp);
        Q_EMIT packCreated(newSp.name());
    }
    endResetModel();

    Q_EMIT rowCountChanged();
}



int StickersPackModel::rowCount(const QModelIndex & parent) const {
    Q_UNUSED(parent);
    return m_stickerPacks.count();
}

QVariant StickersPackModel::data(const QModelIndex & index, int role) const {
    if (index.row() < 0 || index.row() >= m_stickerPacks.count())
        return QVariant();


    const StickerPack &stickerPack = m_stickerPacks[index.row()];
    if (role == StickerPackNameRole)
        return QVariant::fromValue(stickerPack.name());
    else if (role == StickerPackPathRole)
        return QVariant::fromValue(stickerPack.path());
    else if (role == StickerPackCountRole)
        return QVariant::fromValue(stickerPack.count());
    else if (role == StickerPackThumbnailRole)
        return QVariant::fromValue(stickerPack.thumbnail());
    else
        return QVariant();
}



QHash<int, QByteArray> StickersPackModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[StickerPackNameRole] = "packName";
    roles[StickerPackPathRole] = "path";
    roles[StickerPackCountRole] = "stickersCount";
    roles[StickerPackThumbnailRole] = "thumbnail";

    return roles;
}



