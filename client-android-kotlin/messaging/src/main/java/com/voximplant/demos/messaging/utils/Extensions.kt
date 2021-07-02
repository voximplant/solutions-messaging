package com.voximplant.demos.messaging.utils

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Resources
import android.graphics.drawable.Drawable
import android.os.Build
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.annotation.LayoutRes

fun ViewGroup.inflate(@LayoutRes layoutRes: Int, attachToRoot: Boolean = false): View {
    return LayoutInflater.from(context).inflate(layoutRes, this, attachToRoot)
}

fun Resources.getImageId(context: Context, imageName: String): Int {
    return this.getIdentifier(
        imageName,
        "drawable",
        context.packageName,
    )
}

fun LongRange.contains(range: LongRange): Boolean {
    return range.first >= this.first && range.last <= this.last && range.count() <= this.count()
}

@SuppressLint("UseCompatLoadingForDrawables")
fun Context.getDrawableById(id: Int): Drawable? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        getDrawable(id)
    } else {
        @Suppress("DEPRECATION")
        resources.getDrawable(id)
    }
}

fun Context.getColorById(id: Int): Int {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        getColor(id)
    } else {
        @Suppress("DEPRECATION")
        resources.getColor(id)
    }
}

inline fun <T> List<T>.safeIndexOfFirst(predicate: (T) -> Boolean): Int? {
    for ((index, item) in this.withIndex()) {
        if (predicate(item))
            return index
    }
    return null
}

inline fun<T> T?.ifNull(nullHandler: () -> Nothing): T {
    return this ?: nullHandler()
}

fun String.firstLetters(): String? {
    val text = this
        .takeIf { it.isNotEmpty() }
        .ifNull { return null }

    var firstLetters = ""

    for (s in text.split(" ").toTypedArray()) {
        firstLetters += s[0]
    }

    return firstLetters.uppercase()
}