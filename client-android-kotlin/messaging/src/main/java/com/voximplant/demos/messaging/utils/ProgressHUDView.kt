package com.voximplant.demos.messaging.utils

import android.content.Context
import android.util.AttributeSet
import android.widget.LinearLayout
import com.voximplant.demos.messaging.R
import kotlinx.android.synthetic.main.progress_hud_layout.view.*

class ProgressHUDView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    init {
        inflate(R.layout.progress_hud_layout, true)
    }

    fun setText(text: String) {
        loading_text_label.text = text
    }
}
