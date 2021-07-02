package com.voximplant.demos.messaging.ui.changeParticipants

enum class ChangeParticipantListModuleType {
    AddParticipants,
    RemoveParticipants,
    AddAdmins,
    RemoveAdmins;

    companion object {
        fun buildWithIntValue(intValue: Int): ChangeParticipantListModuleType {
            return when (intValue) {
                ADD_PARTICIPANTS -> AddParticipants
                REMOVE_PARTICIPANTS -> RemoveParticipants
                ADD_ADMINS -> AddAdmins
                REMOVE_ADMINS -> RemoveAdmins
                else -> AddParticipants
            }
        }
    }
}

const val CHANGE_PARTICIPANT_LIST_MODULE_TYPE = "ChangeParticipantListModuleType"
const val ADD_PARTICIPANTS = 0
const val REMOVE_PARTICIPANTS = 1
const val ADD_ADMINS = 2
const val REMOVE_ADMINS = 3