package com.voximplant.demos.messaging.ui.createChat

import android.content.Intent
import android.os.Bundle
import android.view.MenuItem
import android.view.View
import android.widget.EditText
import androidx.activity.viewModels
import androidx.core.app.NavUtils
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.ConversationType.CHANNEL
import com.voximplant.demos.messaging.entity.ConversationType.CHAT
import com.voximplant.demos.messaging.ui.activeConversation.ActiveConversationActivity
import com.voximplant.demos.messaging.ui.userSearch.UserSearchViewModel
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_create_chat.*
import kotlinx.android.synthetic.main.activity_create_direct.*
import kotlinx.android.synthetic.main.activity_user_profile.*
import kotlinx.android.synthetic.main.profile_info_view.*

class CreateChatActivity : BaseActivity<CreateChatViewModel>(CreateChatViewModel::class.java) {
    private val userSearchModel: UserSearchViewModel by viewModels()

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

        userSearchModel.useMultipleSelection.value = true

        model.users.observe(this, { users ->
            userSearchModel.usersList.value = users
        })

        userSearchModel.filterString.observe(this, {
            if (it.isEmpty()) {
                profileInfoView.visibility = View.VISIBLE
            } else {
                profileInfoView.visibility = View.GONE
            }
        })

        userSearchModel.selectedItem.observe(this, { user ->
            model.onSelectUser(user)
        })

        userSearchModel.showProgress.observe(this, { textID ->
            showProgressHUD(resources.getString(textID))
        })

        userSearchModel.hideProgress.observe(this, {
            hideProgressHUD()
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

            model.createConversation(
                type, profile_info_title_edit_text.text.toString(),
                profile_info_description_edit_text.text.toString(),
                profileInfoView.imageName,
                isPublic,
                isUber,
            )
        }

        model.showActiveConversation.observe(this, {
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

    private fun showError(textView: EditText, text: String) {
        runOnUiThread {
            textView.error = text
            textView.requestFocus()
        }
    }
}