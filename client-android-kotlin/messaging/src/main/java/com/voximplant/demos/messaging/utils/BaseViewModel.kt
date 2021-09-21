package com.voximplant.demos.messaging.utils

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.voximplant.demos.messaging.manager.VoxClientManagerListener
import com.voximplant.demos.messaging.repository.Repository
import com.voximplant.demos.messaging.repository.RepositoryListener
import kotlinx.coroutines.launch

abstract class BaseViewModel : ViewModel(), VoxClientManagerListener, RepositoryListener {

    protected val clientManager = Shared.clientManager
    protected val repository = Shared.repository

    val showProgress = MutableLiveData<Int>()

    val hideProgress = MutableLiveData<Unit>()

    val subtitle = MutableLiveData<String?>()

    val finish = MutableLiveData<Unit>()

    val showLogin = MutableLiveData<Unit>()

    val intError = MutableLiveData<Int>()

    val stringError = MutableLiveData<String>()

    val intToast = MutableLiveData<Int>()

    val stringToast = MutableLiveData<String>()

    val showConnectionError = MutableLiveData<String?>()

    val refreshState: LiveData<Repository.RefreshState> = repository.refreshState

    protected fun <T : Comparable<T>> postError(error: T) {
        when (error) {
            is Int -> intError.postValue(error)
            is String -> stringError.postValue(error)
        }
    }

    protected fun <T : Comparable<T>> postToast(text: T) {
        when (text) {
            is Int -> intToast.postValue(text)
            is String -> stringToast.postValue(text)
        }
    }

    fun reconnect() {
        viewModelScope.launch {
            repository.refreshData()
        }
    }

    override fun failedToConnectToBackend() {
        super.failedToConnectToBackend()

        showConnectionError.postValue("Failed to reach backend server")
    }

    open fun onCreate() {
        clientManager.addListener(this)
    }

    open fun onResume() {
        repository.setListener(this)
    }

    open fun onDestroy() {
        clientManager.removeListener(this)
    }

    override fun onConnectionClosed() {
        super.onConnectionClosed()

        subtitle.postValue("Connecting..")
    }

    override fun onConnectionFailed(error: String) {
        super.onConnectionFailed(error)

        subtitle.postValue("Connecting..")
    }

    override fun onAlreadyLoggedIn(displayName: String) {
        super.onAlreadyLoggedIn(displayName)

        subtitle.postValue(null)
    }

    override fun onLoginSuccess(displayName: String) {
        super.onLoginSuccess(displayName)

        subtitle.postValue(null)
    }
}