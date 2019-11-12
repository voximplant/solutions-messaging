import Vue from 'vue';
import Router from 'vue-router';
import Login from '@/views/Login.vue';
import Chat from '@/views/Chat.vue';
import ChatRoom from '@/views/ChatRoom.vue';

Vue.use(Router);

const router =  new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/',
      name: 'chat',
      component: Chat,
    },
    {
      path: '/chat/:chatUuid',
      name: 'currentChat',
      component: ChatRoom,
    },
    { path: '/login',
      name: 'login',
      component: Login,
    },
  ],
});

export default router;
