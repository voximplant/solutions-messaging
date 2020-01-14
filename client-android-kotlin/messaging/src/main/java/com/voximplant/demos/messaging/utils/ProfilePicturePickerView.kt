package com.voximplant.demos.messaging.utils

import android.content.Context
import android.util.AttributeSet
import android.widget.LinearLayout
import com.voximplant.demos.messaging.R
import kotlinx.android.synthetic.main.profile_picture_picker_layout.view.*

interface ProfilePicturePickerViewListener {
    fun onCancelButtonPressed()
    fun onSaveButtonPressed(imageN: Int)
}

class ProfilePicturePickerView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0, var choosenImage: Int = 1
) : LinearLayout(context, attrs, defStyleAttr) {

    var listener: ProfilePicturePickerViewListener? = null

    init {
        inflate(R.layout.profile_picture_picker_layout, true)
        chooseImage(choosenImage)

        p1_image_view.setOnClickListener {
            chooseImage(1)
        }
        p2_image_view.setOnClickListener {
            chooseImage(2)
        }
        p3_image_view.setOnClickListener {
            chooseImage(3)
        }
        p4_image_view.setOnClickListener {
            chooseImage(4)
        }
        p5_image_view.setOnClickListener {
            chooseImage(5)
        }
        p6_image_view.setOnClickListener {
            chooseImage(6)
        }

        cancel_button.setOnClickListener {
            listener?.onCancelButtonPressed()
        }

        save_image_button.setOnClickListener {
            listener?.onSaveButtonPressed(choosenImage)
        }
    }

    private fun chooseImage(imageN: Int) {
        p1_image_view.alpha = 0.6F
        p2_image_view.alpha = 0.6F
        p3_image_view.alpha = 0.6F
        p4_image_view.alpha = 0.6F
        p5_image_view.alpha = 0.6F
        p6_image_view.alpha = 0.6F
        when (imageN) {
            1 -> { p1_image_view.alpha = 1.0F }
            2 -> { p2_image_view.alpha = 1.0F }
            3 -> { p3_image_view.alpha = 1.0F }
            4 -> { p4_image_view.alpha = 1.0F }
            5 -> { p5_image_view.alpha = 1.0F }
            6 -> { p6_image_view.alpha = 1.0F }
        }
        choosenImage = imageN
    }
}