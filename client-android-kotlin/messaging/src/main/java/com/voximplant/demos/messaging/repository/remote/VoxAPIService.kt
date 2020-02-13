package com.voximplant.demos.messaging.repository.remote

import android.util.Log
import com.voximplant.demos.messaging.utils.ACC_NAME
import com.voximplant.demos.messaging.utils.APP_NAME
import com.voximplant.demos.messaging.utils.APP_TAG
import com.voximplant.demos.messaging.utils.ifNull
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import java.net.URL

class VoxAPIService {

    fun getVoxUsernames(): List<String> {

        val stringFromBackend = try {
            URL(requestLink).readText()
        } catch (error: IOException) {
            Log.e(APP_TAG, "Error requesting string from backend $error")
            return emptyList()
        }

        val json = parse(stringFromBackend)
            .ifNull {
                Log.e(APP_TAG, "Error parsing JSON")
                return emptyList()
            }

        val result = (json.get("result") as? JSONArray)
            .ifNull {
                Log.e(APP_TAG, "Error creating JSONArray from result")
                return emptyList()
            }

        val valuesArray: MutableList<JSONObject> = mutableListOf()

        for (i in 0 until result.length()) {
            val value = parse(result[i].toString())
                .ifNull {
                    Log.e(APP_TAG, "Error parsing results JSON")
                    return emptyList()
                }
            valuesArray.add(value)
        }

        return (valuesArray.map { "${it["user_name"]}@$APP_NAME.$ACC_NAME" } as? List<String>) ?: emptyList()
    }

    private companion object {
        // TODO: Enter backend URL
        private const val requestLink = ""

        private fun parse(json: String): JSONObject? {
            return try {
                JSONObject(json)
            } catch (e: JSONException) {
                e.printStackTrace()
                return null
            }
        }
    }
}