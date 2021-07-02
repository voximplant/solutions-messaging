package com.voximplant.demos.messaging.ui.conversationInfo

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.inputmethod.InputMethodManager
import androidx.core.view.isVisible
import androidx.recyclerview.widget.LinearLayoutManager
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType.DIRECT
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.ui.changeParticipants.ChangeParticipantListActivity
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.ui.editConversationInfo.EditConversationInfoActivity
import com.voximplant.demos.messaging.ui.userList.UserListAdapter
import com.voximplant.demos.messaging.ui.userList.UserListListener
import com.voximplant.demos.messaging.ui.userProfile.UserProfileActivity
import com.voximplant.demos.messaging.ui.userProfile.UserProfileActivity.Companion.USER_PROFILE_IMID
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_conversation_info.*

class ConversationInfoActivity :
    BaseActivity<ConversationInfoViewModel>(ConversationInfoViewModel::class.java),
    UserListListener {
    private val adapter = UserListAdapter(this)

    private var menuButton: Menu? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        title = "Info"

        setContentView(R.layout.activity_conversation_info)

        conversation_info_recycler_view.layoutManager = LinearLayoutManager(this)
        conversation_info_recycler_view.adapter = adapter

        profileInfoView.isEditingAllowed = false

        model.conversationType.observe(this, {
            profileInfoView.type = it
            leave_conversation_button.isEnabled = it != DIRECT
            leave_conversation_button.isVisible = it != DIRECT
            add_members_button.isEnabled = it != DIRECT
            add_members_button.isVisible = it != DIRECT
            conversation_info_recycler_view.isEnabled = it != DIRECT
            conversation_info_recycler_view.isVisible = it != DIRECT
        })

        model.conversationTitle.observe(this, {
            profileInfoView.titleText = it
        })

        model.conversationDescription.observe(this, {
            profileInfoView.descriptionText = it ?: " "
        })

        model.conversationImageName.observe(this, {
            profileInfoView.imageName = it
        })

        model.conversationParticipants.observe(this, {
            adapter.submitList(it)
        })

        model.exitScreen.observe(this, {
            val intent = Intent(this, ConversationsActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(intent)

            finish()
        })

        model.meIsAdmin.observe(this, { admin ->
            menuButton?.getItem(0)?.let {
                model.conversationType.value?.let { type ->
                    if (type != DIRECT) {
                        it.isVisible = admin
                    }
                }
            }
        })

        add_members_button.setOnClickListener {
            val intent = Intent(this, ChangeParticipantListActivity::class.java)
            intent.putExtra("ChangeParticipantListModuleType", 0)
            startActivity(intent)
        }

        leave_conversation_button.setOnClickListener {
            showProgressHUD("Leaving...")
            model.onLeaveButtonClicked()
        }

        val view = this.currentFocus
        view?.let { v ->
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            imm?.hideSoftInputFromWindow(v.windowToken, 0)
        }
    }

    override fun onSelect(user: User) {
        val intent = Intent(this, UserProfileActivity::class.java)
        intent.putExtra(USER_PROFILE_IMID, user.imId)
        startActivity(intent)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.edit_conversation_menu_button, menu)
        menuButton = menu
        menu.getItem(0)?.let {
            model.meIsAdmin.value?.let { admin ->
                model.conversationType.value?.let { type ->
                    it.isVisible = admin && type != DIRECT
                }
            }
        }
        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        if (item.itemId == R.id.edit_conversation_menu_button) {
            val intent = Intent(this, EditConversationInfoActivity::class.java)
            startActivity(intent)
        }
        return super.onOptionsItemSelected(item)
    }
}