package com.voximplant.demos.messaging.ui.changeParticipants

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.core.view.isVisible
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.ui.changeParticipants.ChangeParticipantListModuleType.*
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.ui.userList.UserListAdapter
import com.voximplant.demos.messaging.ui.userList.UserListListener
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_change_members.*

class ChangeParticipantListActivity : BaseActivity<ChangeParticipantListViewModel>(ChangeParticipantListViewModel::class.java), UserListListener {
    private val adapter = UserListAdapter(this)

    private var menuButton: Menu? = null

    private val type: ChangeParticipantListModuleType
        get() = ChangeParticipantListModuleType.buildWithIntValue(intent.getIntExtra(CHANGE_PARTICIPANT_LIST_MODULE_TYPE, ADD_PARTICIPANTS))

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_change_members)

        change_members_recycler_view.layoutManager = LinearLayoutManager(this)
        adapter.multipleSelectionEnabled = true
        change_members_recycler_view.adapter = adapter

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
                model.possibleToAddParticipants.observe(this, Observer { users ->
                    if (users.isEmpty()) {
                        empty_list_text_view.text = getString(R.string.add_participants_empty_list_description)
                    } else {
                        adapter.submitList(users)
                    }
                })
            }

            RemoveParticipants -> {
                title = "Remove participants"
                model.possibleToRemoveParticipants.observe(this, Observer { users ->
                    if (users.isEmpty()) {
                        empty_list_text_view.text = getString(R.string.remove_participants_empty_list_description)
                    } else {
                        adapter.submitList(users)
                    }
                })
            }
            AddAdmins -> {
                add_members_button.isVisible = false
                title = "Add administrators"
                model.possibleToAddAdmins.observe(this, Observer { admins ->
                    if (admins.isEmpty()) {
                        empty_list_text_view.text = getString(R.string.add_admins_empty_list_description)
                    } else {
                        adapter.submitList(admins)
                    }
                })
            }
            RemoveAdmins -> {
                title = "Remove administrators"
                model.possibleToRemoveAdmins.observe(this, Observer { admins ->
                    if (admins.isEmpty()) {
                        empty_list_text_view.text = getString(R.string.remove_admins_empty_list_description)
                    } else {
                        adapter.submitList(admins)
                    }
                })
            }
        }

        model.chosenUsers.observe(this, Observer {
            it?.let { users ->
                menuButton?.getItem(0)?.setVisible(users.size > 0)
            }
        })

        model.exitScreen.observe(this, Observer {
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


    override fun onSelect(user: User) {
        model.onSelectUser(user)
    }
}