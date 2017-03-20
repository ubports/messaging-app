/*
 * Copyright 2012-2016 Canonical Ltd.
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

import QtQuick 2.2
import Qt.labs.settings 1.0


Item {
    property var _favoritesByAccount: []


    function getFavoriteChannels(account)
    {
        var settings = settingsFromAccount(account)
        return favoriteChannels(settings)
    }

    function favoriteIndex(account, fav)
    {
        return getFavoriteChannels(account).indexOf(fav)
    }

    function isFavorite(account, fav)
    {
        return (favoriteIndex(account, fav) !== -1)
    }

    function addFavorite(account, fav) {
        var settings = settingsFromAccount(account)
        if (favoriteIndexFromSettings(settings, fav) === -1) {
            settings.favoriteChannels += ";" + fav
        }
    }

    function removeFavorite(account, fav) {
        var settings = settingsFromAccount(account)
        var index = favoriteIndexFromSettings(settings, fav)
        if (index !== -1) {
            var list = settings.favoriteChannels.split(";")
            list.splice(index, 1)
            settings.favoriteChannels = list.join(";")
        }
    }

    // private
    function settingsFromAccount(account) {
        var account_ = account.replace(/\//g,"#")
        if (account_ in _favoritesByAccount) {
            return _favoritesByAccount[account_]
        } else {
            var settings = favoriteByAccountComponent.createObject(this, {'category': account_})
            _favoritesByAccount[account_] = settings
            return settings
        }
    }

    function favoriteIndexFromSettings(settings, fav)
    {
        return settings.favoriteChannels.split(";").indexOf(fav)
    }

    function favoriteChannels(settings)
    {
        if (settings.favoriteChannels.length > 0) {
            return settings.favoriteChannels.split(";")
        } else  {
            return []
        }
    }

    Component {
        id: favoriteByAccountComponent
        Settings {
            objectName: "settings_" + category
            property string favoriteChannels: ""
        }
    }
}
