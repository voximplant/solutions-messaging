package com.voximplant.demos.messaging.ui.createDirect

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.activity.viewModels
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.ui.activeConversation.ActiveConversationActivity
import com.voximplant.demos.messaging.ui.createChat.CreateChatActivity
import com.voximplant.demos.messaging.ui.userSearch.UserSearchViewModel
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_create_direct.*

class CreateDirectActivity :
    BaseActivity<CreateDirectViewModel>(CreateDirectViewModel::class.java) {
    private val userSearchModel: UserSearchViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_create_direct)

        title = "Create Direct Chat"

        model.users.observe(this, { users ->
            userSearchModel.usersList.value = users
        })

        userSearchModel.selectedItem.observe(this, { user ->
            showProgressHUD(getString(R.string.progress_loading))
            model.onSelect(user)
        })

        userSearchModel.showProgress.observe(this, { textID ->
            showProgressHUD(resources.getString(textID))
        })

        userSearchModel.hideProgress.observe(this, {
            hideProgressHUD()
        })

        userSearchModel.filterString.observe(this, {
            if (it.isEmpty()) {
                constraintLayout.visibility = View.VISIBLE
            } else {
                constraintLayout.visibility = View.GONE
            }
        })

        model.showActiveConversation.observe(this, {
            val intent = Intent(this, ActiveConversationActivity::class.java)
            startActivity(intent)
            finish()
        })

        create_chat_action_button.setOnClickListener {
            val intent = Intent(this, CreateChatActivity::class.java)
            intent.putExtra("Type", ConversationType.CHAT.stringValue)
            startActivity(intent)
        }

        create_channel_action_button.setOnClickListener {
            val intent = Intent(this, CreateChatActivity::class.java)
            intent.putExtra("Type", ConversationType.CHANNEL.stringValue)
            startActivity(intent)
        }
    }
}