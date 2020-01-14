package com.voximplant.demos.messaging.ui.permissions

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.lifecycle.Observer
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.utils.BaseActivity
import com.voximplant.demos.messaging.utils.permissions.*
import kotlinx.android.synthetic.main.activity_permissions.*

class PermissionsActivity: BaseActivity<PermissionsViewModel>(PermissionsViewModel::class.java) {

    private var canWrite: Boolean
        get() = switch_can_write.isChecked
        set(value) { switch_can_write.isChecked = value }

    private var canEdit: Boolean
        get() = switch_can_edit.isChecked
        set(value) { switch_can_edit.isChecked = value }

    private var canEditAll: Boolean
        get() = switch_can_edit_all.isChecked
        set(value) { switch_can_edit_all.isChecked = value }

    private var canRemove: Boolean
        get() = switch_can_remove.isChecked
        set(value) { switch_can_remove.isChecked = value }

    private var canRemoveAll: Boolean
        get() = switch_can_remove_all.isChecked
        set(value) { switch_can_remove_all.isChecked = value }

    private var canManage: Boolean
        get() = switch_can_manage_participants.isChecked
        set(value) { switch_can_manage_participants.isChecked = value }

    private var menuButton: Menu? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        title = "Permissions"

        setContentView(R.layout.activity_permissions)

        model.conversationPermissions.observe(this, Observer { permissions ->
            canWrite = permissions.canWrite
            canEdit = permissions.canEditMessages
            canEditAll = permissions.canEditAllMessages
            canRemove = permissions.canRemoveMessages
            canRemoveAll = permissions.canRemoveAllMessages
            canManage = permissions.canManageParticipants
        })
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.save_menu_button, menu)
        menuButton = menu
        menu.getItem(0)?.isVisible = true
        return super.onCreateOptionsMenu(menu)
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        model.onSaveButtonPressed(
            canWrite,
            canEdit,
            canEditAll,
            canRemove,
            canRemoveAll,
            canManage)
        return super.onOptionsItemSelected(item)
    }

}