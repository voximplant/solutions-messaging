<template lang="pug">
  v-navigation-drawer(app permanent fixed class="pt-12")
    v-text-field(
      prepend-inner-icon="search"
      class="pa-0"
      ref="search"
      v-model="search"
      full-width
      hide-details
      label="Search"
      single-line)
    v-divider

    v-list(v-if="conversations && conversations.length > 0")
      v-list-item(
        v-for="chat in allConversations"
        :key="chat.uuid"
        @click="gotoCurrentConversation(chat.uuid || chat.userId)"
        :class="{'chat-sidebar__item--active': chat.uuid === currentConversationId }"
        )
        v-list-item-avatar(color="indigo")
          v-img(v-if="getAvatar(chat)" :src="require(`@/assets/avatars/${getAvatar(chat)}.png`)")
          v-icon(v-else dark) {{ isIcon(chat) }}
        v-list-item-content
          v-list-item-title {{ getTitle(chat) }}
</template>

<script lang="ts">
import Vue from 'vue';
import { Component } from 'vue-property-decorator';
import { namespace } from 'vuex-class';
import { logHelp } from '@/utils';
import { User } from '@/types/src/conversations';

const conversationStore = namespace('conversations');

@Component({})
export default class ChatSidebar extends Vue {
  @conversationStore.State readonly conversations: any;
  @conversationStore.State readonly users: any;
  @conversationStore.Getter readonly possibleDirectUsers: any;
  @conversationStore.State readonly currentConversationId: any;
  @conversationStore.Action getCurrentConversation: any;
  @conversationStore.Action createConversation: any;

  public search: string = '';

  getTitle(chat:any) {
    if (chat.userId) {
      return chat.displayName
    } else {
      return chat.direct ? this.users.find((u:User) => u.userId === chat.directUserId).displayName : chat.title;
    }
  }

  getAvatar(chat:any) {
    if (chat.userId) {
      return chat.customData.image
    } else {
      return chat.direct ? this.users.find((u:User) => u.userId === chat.directUserId).customData.image : chat.customData.image;
    }
  }

  isIcon(chat:any) {
    if (!chat.customData.image && chat.direct || chat.userId) {
      return 'account_circle'
    } else {
      return 'supervised_user_circle'
    }
  }

  get allConversations() {
    const search = this.search.toLowerCase();
    //@ts-ignore
    if (!search) return this.conversations.sort((a:any, b:any) => {return new Date(b.lastUpdate) - new Date(a.lastUpdate)});

    return [...this.possibleDirectUsers, ...this.conversations].filter(item => {
      const text = (item.displayName || item.title).toLowerCase();
      return text.indexOf(search) > -1;
    })
  }

  gotoCurrentConversation (uuid: string| number) {
    this.getCurrentConversation(uuid);
    this.search = '';
  }
}
</script>

<style scoped>
  .chat-sidebar__item--active {
    background-color: var(--light-color);
  }
</style>
