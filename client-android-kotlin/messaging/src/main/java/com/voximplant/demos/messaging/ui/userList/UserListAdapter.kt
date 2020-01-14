package com.voximplant.demos.messaging.ui.userList

import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.repository.utils.image
import com.voximplant.demos.messaging.utils.inflate

class UserListAdapter(private val onClickListener: UserListListener) :
    ListAdapter<User, UserListViewHolder>(DIFF_CALLBACK), UserListHolderListener {

    var multipleSelectionEnabled: Boolean = false

    private var selectedRows: MutableList<Boolean> = mutableListOf()

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): UserListViewHolder {
        val view = parent.inflate(R.layout.user_list_adapter_view, false)
        return UserListViewHolder(view)
    }

    override fun onBindViewHolder(holder: UserListViewHolder, position: Int) {
        val user = getItem(position)

        holder.bind(user, this, multipleSelectionEnabled,
            if (selectedRows.indices.contains(position)) {
                selectedRows[position]
            } else {
                selectedRows.add(position, false)
                false
            }
        )
    }

    override fun onSelect(row: Int) {
        if (selectedRows.indices.contains(row)) {
            selectedRows[row] = !selectedRows[row]
        } else {
            selectedRows.add(row, false)
        }
        onClickListener.onSelect(getItem(row))
    }

    companion object {
        private val DIFF_CALLBACK = object : DiffUtil.ItemCallback<User>() {
            override fun areItemsTheSame(oldItem: User, newItem: User)
                    = oldItem.imId == newItem.imId


            override fun areContentsTheSame(oldItem: User, newItem: User)
                    = oldItem.displayName == newItem.displayName && oldItem.customData.image == newItem.customData.image
        }
    }
}