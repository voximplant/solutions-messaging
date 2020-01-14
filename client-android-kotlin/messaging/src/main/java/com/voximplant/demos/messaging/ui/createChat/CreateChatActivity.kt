package com.voximplant.demos.messaging.ui.createChat

import android.content.Intent
import android.os.Bundle
import android.view.MenuItem
import android.widget.EditText
import androidx.core.app.NavUtils
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.ConversationType.CHANNEL
import com.voximplant.demos.messaging.entity.ConversationType.CHAT
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.ui.activeConversation.ActiveConversationActivity
import com.voximplant.demos.messaging.ui.userList.UserListAdapter
import com.voximplant.demos.messaging.ui.userList.UserListListener
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_create_chat.*
import kotlinx.android.synthetic.main.profile_info_view.*

class CreateChatActivity : BaseActivity<CreateChatViewModel>(CreateChatViewModel::class.java), UserListListener {
    private val adapter = UserListAdapter(this)

    private val type: ConversationType
        get() = ConversationType.from(intent.getStringExtra("Type") ?: CHAT.stringValue)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_create_chat)

        profileInfoView.rootView = rootViewGroup
        profileInfoView.isEditingAllowed = true
        profileInfoView.titleText = ""
        profileInfoView.descriptionText = ""

        if (type == CHAT) {
            title = "New Group"
            profileInfoView.type = CHAT
            profileInfoView.isUber = true
            profileInfoView.isPublic = false
        } else if (type == CHANNEL) {
            title = "New Channel"
            profileInfoView.type = CHANNEL
        }

        create_chat_recycler_view.layoutManager = LinearLayoutManager(this)
        adapter.multipleSelectionEnabled = true
        create_chat_recycler_view.adapter = adapter

        model.users.observe(this, Observer {
            adapter.submitList(it)
        })

        create_chat_create_fob.setOnClickListener {

            if (profile_info_title_edit_text.text == null || profile_info_title_edit_text.text!!.isEmpty()) {
                showError(profile_info_title_edit_text, "Title cannot be empty")
                return@setOnClickListener
            }

            val isUber = if (profile_info_uber_switch != null) {
                profile_info_uber_switch.isChecked
            } else {
                false
            }

            val isPublic = if (profile_info_public_switch != null) {
                profile_info_public_switch.isChecked
            } else {
                false
            }

            showProgressHUD("Creating...")

            model.createConversation(
                type, profile_info_title_edit_text.text.toString(),
                profile_info_description_edit_text.text.toString(),
                profileInfoView.imageName,
                isPublic,
                isUber
            )
        }

        model.showActiveConversation.observe(this, Observer {
            val intent = Intent(this, ActiveConversationActivity::class.java)
            startActivity(intent)
            finish()
        })
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            android.R.id.home -> {
                NavUtils.navigateUpFromSameTask(this)
                return true
            }
        }
        return super.onOptionsItemSelected(item)
    }

    override fun onSelect(user: User) {
        model.onSelectUser(user)
    }

    private fun showError(textView: EditText, text: String) {
        runOnUiThread {
            textView.error = text
            textView.requestFocus()
        }
    }
}