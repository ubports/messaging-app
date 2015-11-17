/*
 * Copyright (C) 2015 Canonical, Ltd.
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

#include "fileoperations.h"

#include <QDir>
#include <QFile>
#include <QTemporaryFile>

FileOperations::FileOperations(QObject *parent)
    : QObject(parent)
{
}

FileOperations::~FileOperations()
{
}

QString FileOperations::getTemporaryFile(const QString &fileExtension) const
{
    QTemporaryFile tmp(QDir::tempPath() + "/tmpXXXXXX" + fileExtension);
    tmp.open();
    return tmp.fileName();
}

bool FileOperations::link(const QString &from, const QString &to)
{
    return QFile::link(from, to);
}
