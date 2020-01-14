package com.voximplant.demos.messaging.ui.login

import androidx.lifecycle.MutableLiveData
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.utils.BaseViewModel
import com.voximplant.demos.messaging.utils.POSTFIX
import com.voximplant.sdk.client.LoginError

class LoginViewModel : BaseViewModel() {

    val loginSuccessfulEvent = MutableLiveData<String>()
    val showInvalidInputError = MutableLiveData<Pair<Boolean, Int>>()

    fun login(user: String, password: String) {
        showProgress.postValue(R.string.progress_logging_in)
        clientManager.login("$user$POSTFIX", password)
    }

    //region VoxClientManagerListener
    override fun onLoginSuccess(displayName: String) {
        super.onLoginSuccess(displayName)

        loginSuccessfulEvent.postValue(displayName)
        hideProgress.postValue(Unit)
    }

    override fun onLoginFailed(error: LoginError) {
        super.onLoginFailed(error)

        hideProgress.postValue(Unit)

        when (error) {
            LoginError.INVALID_USERNAME -> showInvalidInputError.postValue(Pair(true, R.string.error_invalid_username))
            LoginError.INVALID_PASSWORD -> showInvalidInputError.postValue(Pair(false,R.string.error_invalid_password))
            LoginError.ACCOUNT_FROZEN   -> postError(R.string.alert_login_failed_account_frozen)
            LoginError.TIMEOUT          -> postError(R.string.alert_login_failed_timeout)
            LoginError.NETWORK_ISSUES   -> postError(R.string.alert_login_failed_network_issues)
            LoginError.TOKEN_EXPIRED    -> postError(R.string.alert_login_failed_token_expired)
            LoginError.INTERNAL_ERROR   -> postError(R.string.alert_login_failed_internal_error)
            else                        -> postError(R.string.alert_login_failed_internal_error)
        }
    }

    override fun onConnectionFailed(error: String) {
        super.onConnectionFailed(error)

        showProgress.postValue(R.string.progress_connecting)
    }

    override fun onConnectionClosed() {
        super.onConnectionClosed()

        showProgress.postValue(R.string.progress_connecting)
    }
    //endregion
}