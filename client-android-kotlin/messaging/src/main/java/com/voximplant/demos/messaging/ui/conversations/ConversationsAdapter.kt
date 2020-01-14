package com.voximplant.demos.messaging.ui.conversations

import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.utils.inflate

interface ConversationViewHolderListener {
    fun onItemClicked(item: ConversationModel)
}

class ConversationAdapter(private val onClickListener: ConversationViewHolderListener) :
    ListAdapter<ConversationModel, ConversationsViewHolder>(DIFF_CALLBACK) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ConversationsViewHolder {
        val view = parent.inflate(R.layout.conversations_adapter_row, false)
        return ConversationsViewHolder(view)
    }

    override fun onBindViewHolder(holder: ConversationsViewHolder, position: Int) {
        val conversation = getItem(position)
        holder.bind(conversation, onClickListener)
    }

    companion object {
        private val DIFF_CALLBACK = object : DiffUtil.ItemCallback<ConversationModel>() {
            override fun areItemsTheSame(oldItem: ConversationModel, newItem: ConversationModel) =
                oldItem.uuid == newItem.uuid


            override fun areContentsTheSame(oldItem: ConversationModel, newItem: ConversationModel) =
                oldItem.title == newItem.title && oldItem.pictureName == newItem.pictureName
        }
    }
}