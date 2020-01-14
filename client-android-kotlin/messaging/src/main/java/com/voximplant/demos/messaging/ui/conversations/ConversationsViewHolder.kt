package com.voximplant.demos.messaging.ui.conversations

import android.view.View
import android.widget.ImageView
import androidx.core.view.isVisible
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.textview.MaterialTextView
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType.*
import com.voximplant.demos.messaging.utils.ProfilePictureGenerator
import com.voximplant.demos.messaging.utils.firstLetters
import com.voximplant.demos.messaging.utils.getDrawableById
import com.voximplant.demos.messaging.utils.getImageId
import kotlinx.android.synthetic.main.conversations_adapter_row.view.*

class ConversationsViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
    private val titleTextView: MaterialTextView = itemView.title
    private val pictureImageView: ImageView = itemView.conversationPicture

    fun bind(model: ConversationModel, onClickListener: ConversationViewHolderListener) {
        titleTextView.text = model.title

        if (model.pictureName != null) {
            val pictureID = itemView.context.resources
                .getImageId(itemView.context, "p${model.pictureName}")
            pictureImageView.setImageResource(pictureID)
        } else {
            pictureImageView.setImageBitmap(
                ProfilePictureGenerator
                    .createTextImage("${model.title.firstLetters()?.take(2)}")
            )
        }

        with(itemView) {
            this.conversation_type_card_view.isVisible = model.type != DIRECT

            conversation_type_image_view.setImageDrawable(
                when (model.type) {
                    CHAT -> context.getDrawableById(R.drawable.ic_group_48px)
                    CHANNEL -> context.getDrawableById(R.drawable.ic_channel_48px)
                    else -> return@with
                }
            )
        }

        itemView.setOnClickListener {
            onClickListener.onItemClicked(model)
        }
    }
}