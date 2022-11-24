import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.History 0.1

Item {
    id: root

    property string accountId: ""
    property string threadId: ""
    property var threads: []
    property var participantIds: []


    property var chatRoomInfo: null
    property var participants: threads.length ? threads[0].participants : []
    property var localPendingParticipants: []
    property var remotePendingParticipants: []
    property QtObject firstParticipant: QtObject {
        property string identifier: ""
        property string contactId: ""
        property string alias: ""
        property string avatar: ""
        property var detailProperties : ({})
    }
    property string firstParticipantalias: firstParticipant.alias !== "" ? firstParticipant.alias : firstParticipant.identifier

    onParticipantsChanged: {
        if (participants && participants.length > 0) {
            var participant = participants[0]
            if (typeof participant === "string") {
                firstParticipant.identifier = participant
                firstParticipant.identifier = participant
            } else {
                firstParticipant.identifier = participant.identifier
                firstParticipant.contactId = participant.contactId
                firstParticipant.alias = participant.alias
                firstParticipant.avatar = participant.avatar
                firstParticipant.detailProperties = participant.detailProperties
            }
        }
    }

//    property variant firstParticipant: {
//        if (!participants || participants.length == 0) {
//            return null
//        }
//        var participant = participants[0]
//        if (typeof participant === "string") {
//            return {identifier: participant, alias: participant}
//        } else {
//            return participant
//        }
//    }

    function participantsHasChanged(newParticipants){
        var oldParticipantsIds = participantIds
        if (newParticipants.length !== oldParticipantsIds.length) return true

        for (var i in newParticipants) {
            if (oldParticipantsIds.indexOf(newParticipants[i].identifier) === -1) return true
        }
        return false
    }

    function requestThreadParticipants(threads) {
        messagesModelthreadInformation.requestThreadParticipants(threads)
    }

    HistoryUnionFilter {
        id: filters
        HistoryIntersectionFilter {
            HistoryFilter { filterProperty: "accountId"; filterValue: accountId }
            HistoryFilter { filterProperty: "threadId"; filterValue: threadId }
        }
    }

    HistoryGroupedThreadsModel {
        id: messagesModelthreadInformation
        type: HistoryThreadModel.EventTypeText
        sort: HistorySort {}
        groupingProperty: "participants"
        filter: accountId != "" && threadId != "" ? filters : null
        matchContacts: true

        onCountChanged: {
            root.populate()

        }
        onDataChanged: {
            root.populate()
        }
    }

    function populate() {
        var index = messagesModelthreadInformation.index(0,0)
        var participants = messagesModelthreadInformation.data(index, HistoryGroupedThreadsModel.ParticipantsRole)

        if (participantsHasChanged(participants)){
            root.participants = participants
        }
        root.chatRoomInfo = messagesModelthreadInformation.data(index, HistoryGroupedThreadsModel.ChatRoomInfo)
        root.localPendingParticipants = messagesModelthreadInformation.data(index, HistoryGroupedThreadsModel.ParticipantsLocalPendingRole)
        root.remotePendingParticipants = messagesModelthreadInformation.data(index, HistoryGroupedThreadsModel.ParticipantsRemotePendingRole)

        //root.threads = threads
    }
}
