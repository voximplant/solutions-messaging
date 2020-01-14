package com.voximplant.demos.messaging.utils.preferences

import android.content.Context
import androidx.preference.PreferenceManager.getDefaultSharedPreferences

fun Long.saveToPrefs(context: Context, key: String) {
    val editor = getDefaultSharedPreferences(context).edit()
    editor.putLong(key, this)
    editor.apply()
}

fun String.saveToPrefs(context: Context, key: String) {
    val editor = getDefaultSharedPreferences(context).edit()
    editor.putString(key, this)
    editor.apply()
}

fun String.removeKeyFromPrefs(context: Context) {
    val editor = getDefaultSharedPreferences(context).edit()
    editor.remove(this)
    editor.apply()
}

fun String.getStringFromPrefs(context: Context): String? {
    return try {
        getDefaultSharedPreferences(context).getString(this, null)
    } catch (e: Exception) {
        return null
    }
}

fun String.getLongFromPrefs(context: Context): Long {
    return try {
        getDefaultSharedPreferences(context).getLong(this, 0)
    } catch (e: Exception) {
        return 0
    }
}