package com.voximplant.demos.messaging.manager

import android.content.Context
import android.util.Log
import com.voximplant.demos.messaging.utils.*
import com.voximplant.demos.messaging.utils.Shared.accName
import com.voximplant.demos.messaging.utils.Shared.appName
import com.voximplant.demos.messaging.utils.preferences.getLongFromPrefs
import com.voximplant.demos.messaging.utils.preferences.getStringFromPrefs
import com.voximplant.demos.messaging.utils.preferences.removeKeyFromPrefs
import com.voximplant.demos.messaging.utils.preferences.saveToPrefs
import com.voximplant.sdk.client.*

private const val REFRESH_TIME = "refreshTime"
private const val LOGIN_ACCESS_TOKEN = "accessToken"
private const val LOGIN_ACCESS_EXPIRE = "accessExpire"
private const val LOGIN_REFRESH_TOKEN = "refreshToken"
private const val LOGIN_REFRESH_EXPIRE = "refreshExpire"

private const val MILLISECONDS_IN_SECOND = 1000
private const val USERNAME = "username"

class VoxClientManager(private val client: IClient, private val context: Context) :
    IClientSessionListener, IClientLoginListener {

    private val listeners: MutableList<VoxClientManagerListener> = mutableListOf()

    private var username: String? = null
    private var password: String? = null
    private var displayName: String? = null

    init {
        client.setClientLoginListener(this)
        client.setClientSessionListener(this)
    }

    fun addListener(listener: VoxClientManagerListener) {
        this.listeners.add(listener)
    }

    fun removeListener(listener: VoxClientManagerListener) {
        this.listeners.remove(listener)
    }

    //region Login
    fun login(username: String, password: String) {
        this.username = username
        this.password = password

        when (client.clientState) {
            ClientState.DISCONNECTED ->
                try {
                    client.connect()
                } catch (e: IllegalStateException) {
                    Log.e(APP_TAG, "exception on connect $e")
                }

            ClientState.CONNECTED -> {
                client.login(username, password)
            }

            else -> return
        }
    }

    fun loginWithToken() {
        when (client.clientState) {
            ClientState.LOGGED_IN -> {
                listeners.forEach { it.onAlreadyLoggedIn(displayName ?: return) }
            }

            ClientState.DISCONNECTED ->
                try {
                    client.connect()
                } catch (e: IllegalStateException) {
                    Log.e(APP_TAG, "exception on connect $e")
                }

            ClientState.CONNECTED ->
                if (tokensExist) {
                    username = USERNAME.getStringFromPrefs(context)

                    if (tokenValid(LOGIN_ACCESS_EXPIRE.getLongFromPrefs(context))) {
                        client.loginWithAccessToken(
                            username,
                            LOGIN_ACCESS_TOKEN.getStringFromPrefs(context)
                        )

                    } else if (tokenValid(LOGIN_REFRESH_EXPIRE.getLongFromPrefs(context))) {
                        client.refreshToken(
                            username,
                            LOGIN_REFRESH_TOKEN.getStringFromPrefs(context)
                        )
                    }
                }

            else -> return
        }
    }
    //endregion

    //region Logout
    fun logout(completion: (Boolean) -> Unit) {
        if (client.clientState == ClientState.LOGGED_IN) {
            displayName = null
            removeTokens()
            client.disconnect()
            listeners.forEach { it.onLogout() }
            completion(true)
        } else {
            completion(false)
        }
    }
    //endregion

    //region Tokens
    private fun saveAuthDetailsToSharedPreferences(authParams: AuthParams) {
        System.currentTimeMillis().saveToPrefs(context, key = REFRESH_TIME)
        authParams.accessToken.saveToPrefs(context, key = LOGIN_ACCESS_TOKEN)
        authParams.refreshToken.saveToPrefs(context, key = LOGIN_REFRESH_TOKEN)
        authParams.accessTokenTimeExpired.toLong().saveToPrefs(context, key = LOGIN_ACCESS_EXPIRE)
        authParams.refreshTokenTimeExpired.toLong().saveToPrefs(context, key = LOGIN_REFRESH_EXPIRE)
    }

    private fun removeTokens() {
        REFRESH_TIME.removeKeyFromPrefs(context)
        LOGIN_ACCESS_TOKEN.removeKeyFromPrefs(context)
        LOGIN_ACCESS_EXPIRE.removeKeyFromPrefs(context)
        LOGIN_REFRESH_TOKEN.removeKeyFromPrefs(context)
        LOGIN_REFRESH_EXPIRE.removeKeyFromPrefs(context)
    }

    val tokensExist: Boolean
        get() = LOGIN_ACCESS_TOKEN.getStringFromPrefs(context) != null
                && LOGIN_REFRESH_TOKEN.getStringFromPrefs(context) != null

    private fun tokenValid(lifeTime: Long): Boolean {
        return System.currentTimeMillis() - REFRESH_TIME.getLongFromPrefs(context) <= lifeTime * MILLISECONDS_IN_SECOND
    }
    //endregion

    //region IClientSessionListener
    override fun onConnectionEstablished() {
        if (username != null && password != null) {
            client.login(username, password)
        } else {
            loginWithToken()
        }
    }

    override fun onConnectionFailed(error: String?) {
        listeners.forEach { it.onConnectionFailed(error ?: "onConnectionFailed") }
        reconnect()
    }

    override fun onConnectionClosed() {
        listeners.forEach { it.onConnectionClosed() }
        reconnect()
    }

    private fun reconnect() {
        if (tokensExist) {
            loginWithToken()
        }
    }
    //endregion

    //region IClientLoginListener
    override fun onLoginSuccessful(displayName: String?, authParams: AuthParams?) {
        this.displayName = displayName
        username?.saveToPrefs(context, key = USERNAME)
        appName = username?.substringAfter("@")?.substringBefore(".")
        accName = username?.substringAfter("@")?.substringAfter(".")?.substringBefore(".")

        listeners.forEach { it.onLoginSuccess(displayName ?: return) }
        saveAuthDetailsToSharedPreferences(authParams ?: return)
    }

    override fun onLoginFailed(error: LoginError?) {
        listeners.forEach { it.onLoginFailed(error ?: return) }
    }

    override fun onOneTimeKeyGenerated(p0: String?) {}

    override fun onRefreshTokenSuccess(authParams: AuthParams?) {
        saveAuthDetailsToSharedPreferences(authParams ?: return)
        loginWithToken()
    }

    override fun onRefreshTokenFailed(reason: LoginError?) {
        listeners.forEach { it.onLoginFailed(reason ?: return) }
    }
    //endregion
}