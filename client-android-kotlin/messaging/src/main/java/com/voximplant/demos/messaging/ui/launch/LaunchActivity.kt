package com.voximplant.demos.messaging.ui.launch

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.ui.conversations.ConversationsActivity
import com.voximplant.demos.messaging.ui.login.LoginActivity
import com.voximplant.demos.messaging.utils.Shared

class LaunchActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_launch)

        val intent =
            if (Shared.clientManager.tokensExist)
                { Intent(this, ConversationsActivity::class.java) }
            else
                { Intent(this, LoginActivity::class.java) }

        startActivity(intent)
        finish()
    }
}
