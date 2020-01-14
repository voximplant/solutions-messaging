package com.voximplant.demos.messaging.ui.userList

import android.view.View
import android.view.View.INVISIBLE
import android.view.View.VISIBLE
import androidx.recyclerview.widget.RecyclerView
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.repository.utils.image
import com.voximplant.demos.messaging.utils.ProfilePictureGenerator
import com.voximplant.demos.messaging.utils.firstLetters
import kotlinx.android.synthetic.main.user_list_adapter_view.view.*

interface UserListHolderListener {
    fun onSelect(row: Int)
}

class UserListViewHolder(itemView: View): RecyclerView.ViewHolder(itemView) {
    private val displayNameTextView = itemView.user_list_display_name_text_view
    private val pictureImageView = itemView.user_list_user_picture_view
    private val checkImageView = itemView.user_list_selected_check

    fun bind(user: User, onClickListener: UserListHolderListener, selectable: Boolean, selected: Boolean) {
        displayNameTextView.text = user.displayName

        if (selectable) {
            if (selected) {
                checkImageView.visibility = VISIBLE
            } else {
                checkImageView.visibility = INVISIBLE
            }
        }

        if (user.customData.image != "" && user.customData.image != null) {
            val pictureID = itemView.context.resources.getIdentifier(
                "p${user.customData.image}",
                "drawable",
                itemView.context.packageName
            )
            pictureImageView.setImageResource(pictureID)
        } else {
            pictureImageView.setImageBitmap(
                ProfilePictureGenerator
                    .createTextImage("${user.displayName.firstLetters()?.take(2)}")
            )
        }

        itemView.setOnClickListener {
            if (selectable) {
                if (checkImageView.visibility == VISIBLE) {
                    checkImageView.visibility = INVISIBLE
                } else {
                    checkImageView.visibility = VISIBLE
                }
            }
            onClickListener.onSelect(adapterPosition)
        }
    }
}