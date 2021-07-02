package com.voximplant.demos.messaging.utils

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.widget.LinearLayout
import androidx.core.view.isVisible
import androidx.core.widget.addTextChangedListener
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.ConversationType
import com.voximplant.demos.messaging.entity.ConversationType.*
import kotlinx.android.synthetic.main.profile_info_view.view.*

interface ProfileInfoViewListener {
    fun onInfoChanged(changed: Boolean)
}

class ProfileInfoView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr), ProfilePicturePickerViewListener {

    var listener: ProfileInfoViewListener? = null

    var rootView: ViewGroup? = null

    private var imagePickerView: ProfilePicturePickerView? = null

    var isEditingAllowed: Boolean = false
        set(allowed) {
            if (!allowed) {
                profile_info_description_edit_text.setBackgroundResource(android.R.color.transparent)
                profile_info_title_edit_text.setBackgroundResource(android.R.color.transparent)
            }
            profile_info_title_edit_text.isEnabled = allowed
            profile_info_description_edit_text.isEnabled = allowed
            set_profile_image_button.isEnabled = allowed
            set_profile_image_button.isVisible = allowed
            showSwitches = if (type == CHAT) {
                allowed
            } else {
                false
            }
            field = allowed
        }

    var type: ConversationType? = null
        set(type) {
            when (type) {
                DIRECT -> {
                    showSwitches = false
                    titleHintText = "Enter Full Name"
                    descriptionHintText = "Enter Bio"
                    profile_info_title_edit_text.isEnabled = false
                    profile_info_title_edit_text.setBackgroundResource(android.R.color.transparent)
                }
                CHAT -> {
                    showSwitches = isEditingAllowed
                    titleHintText = "Enter Group Name"
                    descriptionHintText = "Enter Description"
                }
                CHANNEL -> {
                    showSwitches = false
                    titleHintText = "Enter Channel Name"
                    descriptionHintText = "Enter Description"
                }
            }
            field = type
        }

    var titleText: String?
        get() = profile_info_title_edit_text.text.toString()
        set(value) {
            savedTitleText = value
            profile_info_title_edit_text.setText(value)
            if (imageName == null) {
                imageName = null
            } // to update profile picture
        }

    private var titleHintText: String? = null
        set(value) {
            profile_info_title_edit_text.hint = value
            field = value
        }

    var descriptionText: String?
        get() = profile_info_description_edit_text.text.toString()
        set(value) {
            savedDescription = value
            profile_info_description_edit_text.setText(value)
        }

    private var descriptionHintText: String? = null
        set(value) {
            profile_info_description_edit_text.hint = value
            field = value
        }

    var imageName: String?
        get() = fieldImageName
        set(value) {
            savedImageName = value
            fieldImageName = value
        }

    private var fieldImageName: String? = null
        set(value) {
            value?.let {
                profile_image_view.setImageResource(resources.getImageId(this.context, "p${it}"))
            } ?: run {
                profile_image_view.setImageBitmap(
                    ProfilePictureGenerator
                        .createTextImage(titleText?.firstLetters()?.take(2) ?: "")
                )
            }
            field = value
        }

    var isUber: Boolean
        get() = profile_info_uber_switch.isChecked
        set(value) {
            profile_info_uber_switch.isChecked = value
        }

    var isUberVisible: Boolean
        get() = profile_info_uber_switch.isVisible
        set(value) {
            if (!value) {
                guidline_between_switches.setGuidelinePercent(0.0F)
            } else {
                guidline_between_switches.setGuidelinePercent(0.5F)
            }
            profile_info_uber_switch.isVisible = value
            profile_info_uber_switch.isEnabled = value
        }

    var isPublic: Boolean
        get() = profile_info_public_switch.isChecked
        set(value) {
            savedPublic = value
            profile_info_public_switch.isChecked = value
        }

    private var showSwitches: Boolean = true
        set(show) {
            profile_info_switches_layout.minHeight = if (show) {
                52
            } else {
                0
            }

            profile_info_switches_layout.maxHeight = if (show) {
                300
            } else {
                0
            }
            field = show
        }

    private var savedTitleText: String? = null
    private var savedImageName: String? = null
    private var savedDescription: String? = null
    private var savedPublic: Boolean = false

    private val isInfoChanged: Boolean
        get() = !(savedTitleText == titleText
                && savedImageName == fieldImageName
                && savedDescription == descriptionText
                && savedPublic == isPublic)

    init {
        LayoutInflater.from(context).inflate(R.layout.profile_info_view, this, true)

        set_profile_image_button.setOnClickListener {
            hideKeyboard()
            imagePickerView =
                ProfilePicturePickerView(this.context, choosenImage = imageName?.toInt() ?: 1)
            imagePickerView?.listener = this
            rootView?.addView(imagePickerView)
        }

        profile_info_description_edit_text.addTextChangedListener {
            listener?.onInfoChanged(isInfoChanged)
        }

        profile_info_title_edit_text.addTextChangedListener {
            listener?.onInfoChanged(isInfoChanged)
        }

        profile_info_public_switch.setOnCheckedChangeListener { _, _ ->
            listener?.onInfoChanged(isInfoChanged)
        }
    }

    private fun hideKeyboard() {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(this.windowToken, 0)
    }

    override fun onCancelButtonPressed() {
        rootView?.removeView(imagePickerView)
    }

    override fun onSaveButtonPressed(imageN: Int) {
        fieldImageName = imageN.toString()
        rootView?.removeView(imagePickerView)
        listener?.onInfoChanged(isInfoChanged)
    }
}
