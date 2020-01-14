package com.voximplant.demos.messaging.ui.activeConversation

import android.view.View
import android.view.ViewGroup
import androidx.paging.PagedListAdapter
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.activeConversation.MessengerEventModel.EventCellModel
import com.voximplant.demos.messaging.ui.activeConversation.MessengerEventModel.MessageCellModel
import com.voximplant.demos.messaging.utils.getColorById
import com.voximplant.demos.messaging.utils.inflate

interface ActiveConversationAdapterListener {
    fun onMessageSelected(sequence: Long, selected: Boolean, my: Boolean)
}

class ActiveConversationAdapter(private val listener: ActiveConversationAdapterListener) :
    PagedListAdapter<MessengerEventModel, RecyclerView.ViewHolder>(DIFF_CALLBACK),
    ActiveConversationViewHolderListener {

    private var previouslySelectedView: View? = null
    var selectedRowIndex: Int? = null

    override fun onBindViewHolder(
        holder: RecyclerView.ViewHolder,
        position: Int
    ) {
        if (position == selectedRowIndex) {
            holder.itemView.setBackgroundColor(holder.itemView.context.getColorById(R.color.container) ?: return)
        } else {
            holder.itemView.setBackgroundColor(holder.itemView.context.getColorById(R.color.colorBackground) ?: return)
        }
        val messengerEventModel = getItem(position)
        when (holder) {
            is ActiveConversationMessageViewHolder ->
                holder.bind(messengerEventModel as? MessageCellModel ?: return)
            is ActiveConversationMyMessageViewHolder ->
                holder.bind(messengerEventModel as? MessageCellModel ?: return)
            is ActiveConversationEventViewHolder ->
                holder.bind(messengerEventModel as? EventCellModel ?: return)
        }
    }

    override fun onCreateViewHolder(
        parent: ViewGroup,
        viewType: Int
    ): RecyclerView.ViewHolder {
        return when (viewType) {
            MY_MESSAGE -> {
                val view = parent.inflate(R.layout.active_conversation_my_message_adapter_row, false)
                ActiveConversationMyMessageViewHolder(view, this)
            }
            MESSAGE -> {
                val view = parent.inflate(R.layout.active_conversation_message_adapter_row, false)
                ActiveConversationMessageViewHolder(view, this)
            }
            EVENT -> {
                val view = parent.inflate(R.layout.active_conversation_event_adapter_row, false)
                ActiveConversationEventViewHolder(view)
            }
            else -> throw IllegalArgumentException("$viewType viewType is Unknown")
        }
    }

    override fun getItemViewType(
        position: Int
    ): Int {
        return when (val item = getItem(position)) {
            is MessageCellModel ->
                if (item.isMy) {
                    MY_MESSAGE
                } else {
                    MESSAGE
                }
            is EventCellModel -> EVENT
            else -> super.getItemViewType(position)
        }
    }

    override fun onViewLongTap(view: View, viewPosition: Int) {

        if (previouslySelectedView != null) {
            previouslySelectedView?.setBackgroundColor(previouslySelectedView?.context?.getColorById(R.color.colorBackground) ?: return)
        }

        if (view.isSelected) {
            view.updateSelection(false)
            (getItem(viewPosition) as? MessageCellModel)?.let { cellModel ->
                listener.onMessageSelected(cellModel.sequence, false, cellModel.isMy)
            }
            selectedRowIndex = null
            previouslySelectedView = null
        } else {
            previouslySelectedView?.updateSelection(false)
            view.updateSelection(true)
            view.setBackgroundColor(view.context.getColorById(R.color.container) ?: return)
            (getItem(viewPosition) as? MessageCellModel)?.let { cellModel ->
                listener.onMessageSelected(cellModel.sequence, true, cellModel.isMy)
            }
            selectedRowIndex = viewPosition
            previouslySelectedView = view
        }
    }

    fun updateSelectedRowSelection(selected: Boolean) {
        previouslySelectedView?.updateSelection(selected)
    }

    private fun View.updateSelection(selected: Boolean) {
        this.isSelected = selected
        this.setBackgroundColor(
            if (selected) {
                this.context?.getColorById(R.color.container) ?: return
            } else {
                this.context?.getColorById(R.color.colorBackground) ?: return
            }
        )
    }

    companion object {
        private val DIFF_CALLBACK = object : DiffUtil.ItemCallback<MessengerEventModel>() {

            override fun areItemsTheSame(
                oldItem: MessengerEventModel,
                newItem: MessengerEventModel
            ) =
                oldItem.sequence == newItem.sequence

            override fun areContentsTheSame(
                oldItem: MessengerEventModel,
                newItem: MessengerEventModel
            ) =
                if (oldItem is MessageCellModel) {
                    if (newItem is MessageCellModel) {
                        oldItem.text == newItem.text
                    } else {
                        false
                    }
                } else if (oldItem is EventCellModel) {
                    if (newItem is EventCellModel) {
                        oldItem.text == newItem.text
                    } else {
                        false
                    }
                } else {
                    false
                }
        }

        private const val MY_MESSAGE = 0
        private const val MESSAGE = 1
        private const val EVENT = 2
    }
}