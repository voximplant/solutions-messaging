package com.voximplant.demos.messaging.ui.changeParticipants

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.activity.viewModels
import androidx.core.view.isVisible
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.changeParticipants.ChangeParticipantListModuleType.*
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.ui.userSearch.UserSearchViewModel
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_change_members.*
import kotlinx.android.synthetic.main.activity_create_direct.*

class ChangeParticipantListActivity :
    BaseActivity<ChangeParticipantListViewModel>(ChangeParticipantListViewModel::class.java) {
    private val userSearchModel: UserSearchViewModel by viewModels()

    private var menuButton: Menu? = null

    private val type: ChangeParticipantListModuleType
        get() = ChangeParticipantListModuleType.buildWithIntValue(
            intent.getIntExtra(
                CHANGE_PARTICIPANT_LIST_MODULE_TYPE,
                ADD_PARTICIPANTS
            )
        )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_change_members)

        userSearchModel.useMultipleSelection.value = true
        userSearchModel.useGlobalSearch.value = false

        userSearchModel.selectedItem.observe(this, { user ->
            model.onSelectUser(user)
        })

        userSearchModel.showProgress.observe(this, { textID ->
            showProgressHUD(resources.getString(textID))
        })

        userSearchModel.hideProgress.observe(this, {
            hideProgressHUD()
        })

        add_members_button.setOnClickListener {
            when (type) {
                RemoveParticipants -> {
                    val intent = Intent(this, ChangeParticipantListActivity::class.java)
                    intent.putExtra(CHANGE_PARTICIPANT_LIST_MODULE_TYPE, ADD_PARTICIPANTS)
                    startActivity(intent)
                }

                RemoveAdmins -> {
                    val intent = Intent(this, ChangeParticipantListActivity::class.java)
                    intent.putExtra(CHANGE_PARTICIPANT_LIST_MODULE_TYPE, ADD_ADMINS)
                    startActivity(intent)
                }
                else -> return@setOnClickListener
            }
        }

        when (type) {
            AddParticipants -> {
                add_members_button.isVisible = false
                title = "Add participants"
                userSearchModel.useGlobalSearch.value = true
                model.possibleToAddParticipants.observe(this, { users ->
                    userSearchModel.usersList.value = users
                    if (users.isEmpty()) {
                        empty_list_text_view.text =
                            getString(R.string.add_participants_empty_list_description)
                    } else {
                        empty_list_text_view.text = ""
                    }
                })
            }
            RemoveParticipants -> {
                title = "Remove participants"
                model.possibleToRemoveParticipants.observe(this, { users ->
                    userSearchModel.usersList.value = users
                    if (users.isEmpty()) {
                        empty_list_text_view.text =
                            getString(R.string.remove_participants_empty_list_description)
                    } else {
                        empty_list_text_view.text = ""
                    }
                })
            }
            AddAdmins -> {
                add_members_button.isVisible = false
                title = "Add administrators"
                model.possibleToAddAdmins.observe(this, { admins ->
                    userSearchModel.usersList.value = admins
                    if (admins.isEmpty()) {
                        empty_list_text_view.text =
                            getString(R.string.add_admins_empty_list_description)
                    } else {
                        empty_list_text_view.text = ""
                    }
                })
            }
            RemoveAdmins -> {
                title = "Remove administrators"
                model.possibleToRemoveAdmins.observe(this, { admins ->
                    userSearchModel.usersList.value = admins
                    if (admins.isEmpty()) {
                        empty_list_text_view.text =
                            getString(R.string.remove_admins_empty_list_description)
                    } else {
                        empty_list_text_view.text = ""
                    }
                })
            }
        }

        model.chosenUsers.observe(this, {
            it?.let { users ->
                menuButton?.getItem(0)?.isVisible = users.size > 0
            }
        })

        model.exitScreen.observe(this, {
            val intent = Intent(this, ConversationsActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)

            finish()
        })

        supportActionBar?.setDisplayHomeAsUpEnabled(true)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.save_menu_button, menu)
        menuButton = menu
        menu.getItem(0)?.isVisible = false
        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.save_menu_button -> {
                showProgressHUD("Saving..")

                model.onSaveButtonPressed(type) { saved ->
                    hideProgressHUD()
                    if (saved) {
                        finish()
                    } else {
                        showError(
                            when (type) {
                                AddParticipants -> "Could'nt add participants"
                                RemoveParticipants -> "Could'nt remove participants"
                                AddAdmins -> "Could'nt add admins"
                                RemoveAdmins -> "Could'nt remove admins"
                            }
                        )
                    }
                }
            }
            android.R.id.home -> {
                finish()
            }
        }
        return super.onOptionsItemSelected(item)
    }
}