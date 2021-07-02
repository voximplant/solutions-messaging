package com.voximplant.demos.messaging.ui.activeConversation

import android.content.Intent
import android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.gms.maps.model.LatLng
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.conversationInfo.ConversationInfoActivity
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.ui.location.LocationActivity
import com.voximplant.demos.messaging.ui.location.LocationActivity.Companion.LATITUDE
import com.voximplant.demos.messaging.ui.location.LocationActivity.Companion.LONGITUDE
import com.voximplant.demos.messaging.ui.userProfile.UserProfileActivity
import com.voximplant.demos.messaging.utils.BaseActivity
import com.voximplant.demos.messaging.utils.ifNull
import com.voximplant.demos.messaging.utils.permissions.*
import kotlinx.android.synthetic.main.activity_active_conversation.*

class ActiveConversationActivity :
    BaseActivity<ActiveConversationViewModel>(ActiveConversationViewModel::class.java),
    ActiveConversationAdapterListener {

    private val adapter = ActiveConversationAdapter(this)

    private var menu: Menu? = null
    private val editMenuItem: MenuItem?
        get() = menu?.getItem(0)
    private val removeMenuItem: MenuItem?
        get() = menu?.getItem(1)
    private val infoMenuItem: MenuItem?
        get() = menu?.getItem(2)

    private var selectedMessageSequence: Long? = null
    private var isInEditingMode: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_active_conversation)

        val layoutManager = LinearLayoutManager(this)
        layoutManager.stackFromEnd = true
        layoutManager.reverseLayout = false

        messages_recycler_view.layoutManager = layoutManager
        messages_recycler_view.adapter = adapter

        send_button.setOnClickListener {
            if (isInEditingMode) {
                val editSequence = selectedMessageSequence
                    .ifNull { return@setOnClickListener }

                adapter.updateSelectedRowSelection(false)
                adapter.selectedRowIndex = null
                setMenuItemsVisibility(false)
                showEditMode(false)

                showProgressHUD(getString(R.string.progress_editing))
                model.editMessage(
                    editSequence,
                    create_message_text_view.text.toString()
                ) { edited ->
                    hideProgressHUD()
                    create_message_text_view.setText("")
                    if (!edited) {
                        showError(getString(R.string.could_not_edit_message))
                    }
                }
            } else {
                adapter.selectedRowIndex = null
                setMenuItemsVisibility(false)

                showProgressHUD(getString(R.string.progress_sending))

                model.sendButtonClick(create_message_text_view.text.toString()) { sent ->
                    hideProgressHUD()
                    create_message_text_view.setText("")
                    if (!sent) {
                        showError(getString(R.string.could_not_send_message))
                    }
                }
            }
        }

        model.title.observe(this, {
            it?.let { title = it }
        })

        model.imageName.observe(this, {
            it?.let { setMenuItemImage(it) }
        })

        model.messages.observe(this, {
            adapter.submitList(it)
        })

        model.myPermissions.observe(this, Observer { permissions ->
            if (permissions == null) {
                return@Observer
            }

            if (permissions.canWrite) {
                message_container_layout.minHeight = 52
                message_container_layout.maxHeight = 300
            } else {
                message_container_layout.minHeight = 0
                message_container_layout.maxHeight = 0
            }
        })

        create_message_text_view.setOnClickListener {
            model.sendTyping()
        }

        edit_message_icon_close.setOnClickListener {
            adapter.selectedRowIndex = null
            adapter.updateSelectedRowSelection(false)
            selectedMessageSequence = null
            setMenuItemsVisibility(false)
            showEditMode(false)
        }

        share_location_image_button.setOnClickListener {
            showLocationActivity(null)
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)

        val lat = intent?.getDoubleExtra(LATITUDE, 0.0)
            .takeIf { it != 0.0 }
            .ifNull { return }
        val lon = intent?.getDoubleExtra(LONGITUDE, 0.0)
            .takeIf { it != 0.0 }
            .ifNull { return }

        showProgressHUD(getString(R.string.progress_sending))

        model.sendLocation(LatLng(lat,lon)) {
            hideProgressHUD()

            create_message_text_view.setText("")
            if (!it) { showError(getString(R.string.could_not_share_location)) }
        }
    }

    override fun finish() {
        val intent = Intent(this, ConversationsActivity::class.java)
        intent.addFlags(FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(intent)

        super.finish()
    }

    override fun onBackPressed() {
        super.onBackPressed()

        model.finish()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.active_conversation_menu, menu)

        this.menu = menu

        model.imageName.value?.let {
            setMenuItemImage(it)
        }

        setMenuItemsVisibility(false)
        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {

            android.R.id.home -> {
                model.finish()
            }

            R.id.conversation_info_menu_button -> model.menuButtonPressed { userImId ->
                if (userImId == null) {
                    val intent = Intent(this, ConversationInfoActivity::class.java)
                    startActivity(intent)
                } else {
                    val intent = Intent(this, UserProfileActivity::class.java)
                    intent.putExtra(UserProfileActivity.USER_PROFILE_IMID, userImId)
                    startActivity(intent)
                }
            }

            R.id.edit_message_menu_button -> {
                selectedMessageSequence?.let {
                    model.requestMessageInfo(it) { messageText ->
                        runOnUiThread {
                            if (messageText != null) {
                                edit_message_message_text.text = messageText
                                create_message_text_view.setText(messageText)
                            }
                            showEditMode(messageText != null)
                        }
                    }
                    setMenuItemsVisibility(false)
                }
            }

            R.id.remove_message_menu_button -> {
                val removeSequence = selectedMessageSequence
                    .ifNull { return super.onOptionsItemSelected(item) }

                adapter.selectedRowIndex = null
                setMenuItemsVisibility(false)
                showProgressHUD(getString(R.string.progress_removing))

                model.removeMessage(removeSequence) { removed ->
                    hideProgressHUD()
                    if (!removed) {
                        showError(getString(R.string.could_not_remove_message))
                    }
                }
            }
        }
        return super.onOptionsItemSelected(item)
    }

    override fun onMessageSelected(sequence: Long, selected: Boolean, my: Boolean) {
        if (selected) {
            selectedMessageSequence = sequence
            if (my) {
                editMenuItem?.isVisible = model.myPermissions.value?.canEditMessages ?: false
                removeMenuItem?.isVisible = model.myPermissions.value?.canRemoveMessages ?: false
            } else {
                editMenuItem?.isVisible = model.myPermissions.value?.canEditAllMessages ?: false
                removeMenuItem?.isVisible = model.myPermissions.value?.canRemoveAllMessages ?: false
            }
        } else {
            selectedMessageSequence = null
            setMenuItemsVisibility(false)
            showEditMode(false)
        }
    }

    override fun onLocationSelected(location: LatLng) {
        showLocationActivity(location)
    }

    private fun setMenuItemImage(imageName: String) {
//        val imageId = resources.getImageId(this, "p${imageName}")
//        infoMenuItem?.icon = getDrawableById(imageId)
    }

    private fun setMenuItemsVisibility(visible: Boolean) {
        editMenuItem?.isVisible = visible
        removeMenuItem?.isVisible = visible
    }

    private fun showEditMode(show: Boolean) {
        edit_message_container_layout.minHeight = if (show) 52 else 0
        edit_message_container_layout.maxHeight = if (show) 300 else 0
        isInEditingMode = show
    }

    private fun showLocationActivity(location: LatLng?) {
        val intent = Intent(this, LocationActivity::class.java)
        location?.let {
            intent.putExtra(LATITUDE, location.latitude)
            intent.putExtra(LONGITUDE, location.longitude)
        }
        startActivity(intent)
    }
}