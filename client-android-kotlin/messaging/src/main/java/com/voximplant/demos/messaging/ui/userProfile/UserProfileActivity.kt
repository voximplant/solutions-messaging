package com.voximplant.demos.messaging.ui.userProfile

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.core.view.isVisible
import androidx.lifecycle.Observer
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType.DIRECT
import com.voximplant.demos.messaging.repository.utils.image
import com.voximplant.demos.messaging.repository.utils.status
import com.voximplant.demos.messaging.utils.BaseActivity
import com.voximplant.demos.messaging.utils.ProfileInfoViewListener
import kotlinx.android.synthetic.main.activity_user_profile.*

class UserProfileActivity: BaseActivity<UserProfileViewModel>(UserProfileViewModel::class.java),
    ProfileInfoViewListener {

    private var menu: Menu? = null
    private val saveMenuItem: MenuItem?
        get() = menu?.getItem(0)

    private val userImId: Long
        get() = intent.getLongExtra(USER_PROFILE_IMID, 0)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_user_profile)

        model.displayingUserImId = userImId

        logout_button.isVisible = model.isMe
        logout_button.isEnabled = model.isMe

        profileInfoView_userProfile.isEditingAllowed = model.isMe
        profileInfoView_userProfile.rootView = rootViewGroup
        profileInfoView_userProfile.type = DIRECT
        profileInfoView_userProfile.listener = this

        model.user.observe(this, {
            it?.let { user ->
                title = "Profile"
                profileInfoView_userProfile.titleText = user.displayName
                profileInfoView_userProfile.imageName = user.customData.image
                profileInfoView_userProfile.descriptionText = user.customData.status
            }
        })

        logout_button.setOnClickListener {
            model.onLogoutPressed()
        }

        supportActionBar?.setDisplayHomeAsUpEnabled(true)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.save_menu_button, menu)

        this.menu = menu

        saveMenuItem?.isVisible = false

        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when (item.itemId) {
            R.id.save_menu_button -> {
                showProgressHUD("Saving..")

                model.onSavePressed(profileInfoView_userProfile.descriptionText,
                    profileInfoView_userProfile.imageName
                ) { saved ->
                    hideProgressHUD()
                    if (!saved) { showError("Couldn't save information") }
                }
            }

            android.R.id.home ->  finish()
        }

        return super.onOptionsItemSelected(item)
    }

    companion object {
        const val USER_PROFILE_IMID = "UserProfileUserImId"
    }

    override fun onInfoChanged(changed: Boolean) {
        saveMenuItem?.isVisible = changed
    }
}
