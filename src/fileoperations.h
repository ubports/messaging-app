/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * Authors:
 *  Arthur Mello <arthur.mello@canonical.com>
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

#ifndef FILEOPERATIONS_H
#define FILEOPERATIONS_H

#include <QObject>

class FileOperations : public QObject
{
    Q_OBJECT

public:
    FileOperations(QObject *parent = 0);
    ~FileOperations();

    Q_INVOKABLE QString getTemporaryFile(const QString &fileExtension) const;
    Q_INVOKABLE bool link(const QString &from, const QString &to);
    Q_INVOKABLE bool remove(const QString &fileName);
};

#endif // FILEOPERATIONS_H
