package com.voximplant.demos.messaging.ui.login

import android.animation.Animator
import android.animation.AnimatorInflater
import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.view.MotionEvent.ACTION_DOWN
import android.view.MotionEvent.ACTION_UP
import android.view.View
import android.widget.EditText
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.utils.BaseActivity
import kotlinx.android.synthetic.main.activity_login.*

class LoginActivity : BaseActivity<LoginViewModel>(LoginViewModel::class.java) {

    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_login)

        loginButton.setOnClickListener {
            model.login(usernameView.text.toString(), passwordView.text.toString())
        }

        val reducer = AnimatorInflater.loadAnimator(this.applicationContext, R.animator.reduce_size)
        val increaser =
            AnimatorInflater.loadAnimator(this.applicationContext, R.animator.regain_size)

        loginButton.setOnTouchListener { view, motionEvent ->
            if (motionEvent.action == ACTION_DOWN) animate(view, reducer)
            if (motionEvent.action == ACTION_UP) animate(view, increaser)
            false
        }

        model.loginSuccessfulEvent.observe(this, {
            showConversationsScreen()
        })

        model.showInvalidInputError.observe(this, {
            showError(
                when (it.first) {
                    true -> usernameView
                    false -> passwordView
                }, resources.getString(it.second)
            )
        })
    }

    override fun onResume() {
        super.onResume()

        model.onResume()
    }

    override fun showConnectionError(text: String?) {}

    private fun showConversationsScreen() {
        runOnUiThread {
            val intent = Intent(this, ConversationsActivity::class.java)
            startActivity(intent)
            finish()
        }
    }

    private fun showError(textView: EditText, text: String) {
        runOnUiThread {
            textView.error = text
            textView.requestFocus()
        }
    }

    private fun animate(view: View, animator: Animator) {
        animator.setTarget(view)
        animator.start()
    }
}