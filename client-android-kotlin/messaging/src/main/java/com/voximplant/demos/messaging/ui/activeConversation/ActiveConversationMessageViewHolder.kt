package com.voximplant.demos.messaging.ui.activeConversation

import android.view.View
import androidx.core.view.isVisible
import androidx.recyclerview.widget.RecyclerView
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.activeConversation.MessengerEventModel.EventCellModel
import com.voximplant.demos.messaging.ui.activeConversation.MessengerEventModel.MessageCellModel
import com.voximplant.demos.messaging.utils.getDrawableById
import kotlinx.android.synthetic.main.active_conversation_event_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_message_adapter_row.view.*
import kotlinx.android.synthetic.main.active_conversation_my_message_adapter_row.view.*

interface ActiveConversationViewHolderListener {
    fun onViewLongTap(view: View, viewPosition: Int)
}

class ActiveConversationMessageViewHolder(
    itemView: View,
    private var listener: ActiveConversationViewHolderListener
) : RecyclerView.ViewHolder(itemView), View.OnLongClickListener {

    init {
        itemView.setOnLongClickListener(this)
    }

    fun bind(model: MessageCellModel) {
        itemView.message_text_view.text = model.text
        itemView.message_sender_text_view.text = model.senderName
        itemView.edited_text_view.isVisible = model.isEdited
        itemView.message_time_text_view.text = model.time
    }

    override fun onLongClick(view: View): Boolean {
        listener.onViewLongTap(itemView, adapterPosition)
        return true
    }
}

class ActiveConversationMyMessageViewHolder(
    itemView: View,
    private var listener: ActiveConversationViewHolderListener
) : RecyclerView.ViewHolder(itemView), View.OnLongClickListener {

    init {
        itemView.setOnLongClickListener(this)
    }

    fun bind(model: MessageCellModel) {
        itemView.my_message_text_view.text = model.text
        itemView.my_message_time_text_view.text = model.time
        itemView.my_edited_text_view.isVisible = model.isEdited
        itemView.is_read_image_view.setImageDrawable(
            if (model.isRead) {
                itemView.context.getDrawableById(R.drawable.ic_doublecheck)
            } else {
                itemView.context.getDrawableById(R.drawable.ic_checkmark)
            }
        )
    }

    override fun onLongClick(view: View): Boolean {
        listener.onViewLongTap(itemView, adapterPosition)
        return true
    }
}

class ActiveConversationEventViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {

    private val eventTextView = itemView.event_text_view

    private var eventText: String?
        get() = eventTextView.text.toString()
        set(value) {
            eventTextView.text = value
        }

    fun bind(model: EventCellModel) {
        eventText = model.text
    }
}