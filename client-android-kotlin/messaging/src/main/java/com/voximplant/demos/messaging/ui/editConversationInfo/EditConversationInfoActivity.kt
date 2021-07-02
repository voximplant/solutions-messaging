package com.voximplant.demos.messaging.ui.editConversationInfo

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.EditText
import androidx.core.view.isVisible
import androidx.lifecycle.Observer
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType.CHAT
import com.voximplant.demos.messaging.entity.ConversationType.DIRECT
import com.voximplant.demos.messaging.ui.changeParticipants.CHANGE_PARTICIPANT_LIST_MODULE_TYPE
import com.voximplant.demos.messaging.ui.changeParticipants.ChangeParticipantListActivity
import com.voximplant.demos.messaging.ui.changeParticipants.REMOVE_ADMINS
import com.voximplant.demos.messaging.ui.changeParticipants.REMOVE_PARTICIPANTS
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.ui.permissions.PermissionsActivity
import com.voximplant.demos.messaging.utils.BaseActivity
import com.voximplant.demos.messaging.utils.ProfileInfoViewListener
import kotlinx.android.synthetic.main.activity_edit_conversation_info.*
import kotlinx.android.synthetic.main.profile_info_view.*

class EditConversationInfoActivity :
    BaseActivity<EditConversationInfoViewModel>(EditConversationInfoViewModel::class.java),
    ProfileInfoViewListener {

    private var menu: Menu? = null
    private val saveMenuItem: MenuItem?
        get() = menu?.getItem(0)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        title = "Edit"

        setContentView(R.layout.activity_edit_conversation_info)

        editProfileInfoView.isEditingAllowed = true
        editProfileInfoView.rootView = rootViewGroup
        editProfileInfoView.isUberVisible = false
        editProfileInfoView.listener = this

        model.conversationType.observe(this, {
            editProfileInfoView.type = it
            leave_conversation_button.isEnabled = it != DIRECT
            leave_conversation_button.isVisible = it != DIRECT
            permissions_button.isEnabled = it == CHAT
            permissions_button.isVisible = it == CHAT
        })

        model.conversationTitle.observe(this, {
            editProfileInfoView.titleText = it
        })

        model.conversationDescription.observe(this, {
            editProfileInfoView.descriptionText = it
        })

        model.conversationImageName.observe(this, {
            editProfileInfoView.imageName = it
        })

        model.conversationIsPublic.observe(this, {
            editProfileInfoView.isPublic = it ?: false
        })

        model.exitScreen.observe(this, {
            val intent = Intent(this, ConversationsActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)

            finish()
        })

        participants_button.setOnClickListener {
            val intent = Intent(this, ChangeParticipantListActivity::class.java)
            intent.putExtra(CHANGE_PARTICIPANT_LIST_MODULE_TYPE, REMOVE_PARTICIPANTS)
            startActivity(intent)
        }

        admins_button.setOnClickListener {
            val intent = Intent(this, ChangeParticipantListActivity::class.java)
            intent.putExtra(CHANGE_PARTICIPANT_LIST_MODULE_TYPE, REMOVE_ADMINS)
            startActivity(intent)
        }

        permissions_button.setOnClickListener {
            val intent = Intent(this, PermissionsActivity::class.java)
            startActivity(intent)
        }

        leave_conversation_button.setOnClickListener {
            showProgressHUD("Leaving...")
            model.onLeaveButtonClicked()
        }
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.save_menu_button, menu)

        this.menu = menu

        saveMenuItem?.isVisible = false

        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == R.id.save_menu_button) {

            editProfileInfoView.titleText?.let { title ->
                model.onSaveButtonClicked(
                    title,
                    editProfileInfoView.descriptionText,
                    editProfileInfoView.imageName,
                    editProfileInfoView.isPublic
                )
                showProgressHUD("Updating...")
            }
                ?: showError(profile_info_title_edit_text, "Title cannot be empty")
        }
        return super.onOptionsItemSelected(item)
    }

    private fun showError(textView: EditText, text: String) {
        runOnUiThread {
            textView.error = text
            textView.requestFocus()
        }
    }

    override fun onInfoChanged(changed: Boolean) {
        saveMenuItem?.isVisible = changed
    }
}