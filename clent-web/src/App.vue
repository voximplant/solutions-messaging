<template lang="pug">
  v-app(id="demo-chat")
    v-container(fill-height class="app__wrapper pa-0")
      ChatBar(v-if="this.$route.name !== 'login'")
      ChatSidebar(v-if="this.$route.name !== 'login'")
      v-content(class="app__content" )
        router-view
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator';
import ChatSidebar from '@/components/ui/ChatSidebar.vue';
import ChatBar from '@/components/ui/ChatBar.vue';

import { namespace } from 'vuex-class';
const authStore = namespace('auth');

@Component({
  components: { ChatBar, ChatSidebar },
})
export default class App extends Vue {
  @authStore.Getter readonly accessToken: string;
  @authStore.Getter readonly loginName: string;

  created () {
    if (!this.accessToken && this.$route.name !== 'login') {
      this.$router.push('/login');
    }
  }
}
</script>

<style>
  :root {
    --primary-color: #3949ab;
    --light-color: #d7daee;
    --lighter-color: #ebecf6;
    --accent-color: #ab3949;
  }
.app__wrapper {
  max-width: none;
  overflow: hidden;
}
.app__content {
  height: 100vh;
  overflow: hidden;
  width: 100%;
}
</style>
