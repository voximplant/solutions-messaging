package com.voximplant.demos.messaging.ui.userSearch

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.*
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.voximplant.demos.messaging.R
import com.voximplant.demos.messaging.entity.User
import com.voximplant.demos.messaging.ui.userList.UserListAdapter
import com.voximplant.demos.messaging.ui.userList.UserListListener
import kotlinx.android.synthetic.main.fragment_user_search.*

class UserSearchFragment : Fragment(), UserListListener {
    private val viewModel: UserSearchViewModel by activityViewModels()
    private val adapter = UserListAdapter(this)

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_user_search, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        user_list_recycler_view.layoutManager = LinearLayoutManager(context)
        user_list_recycler_view.adapter = adapter

        viewModel.useMultipleSelection.observe(viewLifecycleOwner, {
            adapter.multipleSelectionEnabled = it
        })

        viewModel.filteredUsers.observe(viewLifecycleOwner, {
            adapter.submitList(it)
        })

        viewModel.searchUser()

        viewModel.useGlobalSearch.value?.let {
            if (it) {
                globalSearchButton.visibility = View.VISIBLE
            } else {
                globalSearchButton.visibility = View.GONE
            }
        }

        textInputEditTextSearchUser.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}

            override fun onTextChanged(s: CharSequence, start: Int, before: Int, count: Int) {
                viewModel.searchUser(s.toString())
                viewModel.useGlobalSearch.value?.let {
                    globalSearchButton.isEnabled = s.isNotEmpty()
                }
            }

            override fun afterTextChanged(s: Editable?) {}
        })

        globalSearchButton.setOnClickListener {
            viewModel.globalSearchUser(textInputEditTextSearchUser.text.toString())
        }

        viewModel.stringToast.observe(viewLifecycleOwner, { text ->
            toast(message = text)
        })

        viewModel.intToast.observe(viewLifecycleOwner, { text ->
            toast(message = resources.getString(text))
        })
    }

    override fun onSelect(user: User) {
        viewModel.onSelect(user)
    }

    private fun toast(message: String) =
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
}