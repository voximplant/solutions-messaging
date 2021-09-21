package com.voximplant.demos.messaging.ui.conversations

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.core.app.NavUtils
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.repository.Repository.RefreshState.READY
import com.voximplant.demos.messaging.repository.Repository.RefreshState.REFRESHING
import com.voximplant.demos.messaging.ui.activeConversation.ActiveConversationActivity
import com.voximplant.demos.messaging.ui.createDirect.CreateDirectActivity
import com.voximplant.demos.messaging.ui.userProfile.UserProfileActivity
import com.voximplant.demos.messaging.ui.userProfile.UserProfileActivity.Companion.USER_PROFILE_IMID
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_conversations.*

class ConversationsActivity :
    BaseActivity<ConversationsViewModel>(ConversationsViewModel::class.java),
    ConversationViewHolderListener {
    private val adapter = ConversationAdapter(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_conversations)

        adapter.registerAdapterDataObserver(object : RecyclerView.AdapterDataObserver() {
            override fun onChanged() {
                conversationsRecyclerView.scrollToPosition(0)
            }

            override fun onItemRangeRemoved(positionStart: Int, itemCount: Int) {
                conversationsRecyclerView.scrollToPosition(0)
            }

            override fun onItemRangeMoved(fromPosition: Int, toPosition: Int, itemCount: Int) {
                conversationsRecyclerView.scrollToPosition(0)
            }

            override fun onItemRangeInserted(positionStart: Int, itemCount: Int) {
                conversationsRecyclerView.scrollToPosition(0)
            }

            override fun onItemRangeChanged(positionStart: Int, itemCount: Int) {
                conversationsRecyclerView.scrollToPosition(0)
            }

            override fun onItemRangeChanged(positionStart: Int, itemCount: Int, payload: Any?) {
                conversationsRecyclerView.scrollToPosition(0)
            }
        })

        val layoutManager = LinearLayoutManager(this)
        val dividerItemDecoration = DividerItemDecoration(
            conversationsRecyclerView.context,
            layoutManager.orientation
        )
        conversationsRecyclerView.addItemDecoration(dividerItemDecoration)

        conversationsRecyclerView.layoutManager = layoutManager
        conversationsRecyclerView.adapter = adapter

        model.refreshState.observe(this, {
            if (model.refreshState.value == READY) {
                if (model.conversationModels.value.isNullOrEmpty()) {
                    info_text_view.visibility = View.VISIBLE
                } else {
                    info_text_view.visibility = View.GONE
                }
            } else if (model.refreshState.value == REFRESHING) {
                info_text_view.visibility = View.GONE
            }
        })

        model.conversationModels.observe(this, {
            if (model.refreshState.value == READY) {
                if (it.isNullOrEmpty()) {
                    info_text_view.visibility = View.VISIBLE
                } else {
                    info_text_view.visibility = View.GONE
                }
            }

            adapter.submitList(it)
        })

        conversations_activity_fab.setOnClickListener {
            val intent = Intent(this, CreateDirectActivity::class.java)
            startActivity(intent)
        }

        supportActionBar?.setDisplayHomeAsUpEnabled(false)
    }

    //region ConversationViewHolderListener
    override fun onItemClicked(item: ConversationModel) {
        model.onSelectConversation(item)

        val intent = Intent(this, ActiveConversationActivity::class.java)
        startActivity(intent)
    }
    //endregion

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.conversations_menu, menu)
        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            android.R.id.home -> {
                NavUtils.navigateUpFromSameTask(this)
                return true
            }
            R.id.conversations_menu -> {
                model.onSettingsButtonPressed { userImId ->
                    val intent = Intent(this, UserProfileActivity::class.java)
                    intent.putExtra(USER_PROFILE_IMID, userImId)
                    startActivity(intent)
                }
            }
        }
        return super.onOptionsItemSelected(item)
    }

}