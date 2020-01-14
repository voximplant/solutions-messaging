package com.voximplant.demos.messaging.ui.createDirect

import android.content.Intent
import android.os.Bundle
import android.view.MenuItem
import androidx.core.app.NavUtils
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.ui.activeConversation.ActiveConversationActivity
import com.voximplant.demos.messaging.ui.createChat.CreateChatActivity
import com.voximplant.demos.messaging.ui.userList.UserListAdapter
import com.voximplant.demos.messaging.ui.userList.UserListListener
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_create_direct.*

class CreateDirectActivity: BaseActivity<CreateDirectViewModel>(CreateDirectViewModel::class.java), UserListListener {
    private val adapter = UserListAdapter(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_create_direct)

        title = "Create Direct Chat"

        user_list_recycler_view.layoutManager = LinearLayoutManager(this)
        user_list_recycler_view.adapter = adapter

        model.users.observe(this, Observer {
            adapter.submitList(it)
        })

        model.showActiveConversation.observe(this, Observer {
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
        showProgressHUD("Creating...")
        model.onSelect(user)
    }
}