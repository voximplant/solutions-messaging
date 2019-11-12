<template lang="pug">
  v-flex(class="chatroom__card-wrapper")
    div(:class="['chatroom__card', {'chatroom__card--me': isMyMessage, 'chatroom__card--user': !isMyMessage}]")
      v-avatar(class="chatroom__card-ava" @click="popupAboutUser = !popupAboutUser" color="indigo")
        v-img(v-if="message.user.customData.image" :src="require(`@/assets/avatars/${message.user.customData.image}.png`)")
        v-icon(v-else dark) account_circle
      div
        div(class="chatroom__card-title") {{ message.user.displayName }}
        v-menu(v-model="showMenu" absolute offset-y min-width="100px")
          template(v-slot:activator="{ on }")
            div(class="chatroom__card-text" v-on="on") {{ message.text }}
              div(class="chatroom__card-time")
                div(class="pr-2") {{ new Date(message.timestamp).toLocaleString() }}
                v-icon(small v-if="message.markAsRead && isMyMessage") done_all
                v-icon(small v-else-if="isMyMessage") done
          v-list(v-if="isCanDelete || isCanEdit")
            v-list-item(v-if="isCanDelete" key="delete" @click="deleteConfirmation = true")
              v-list-item-title Delete
            v-list-item(v-if="isCanEdit" key="edit" @click="editCurrentMessage")
              v-list-item-title Edit
    Confirmation(:visibleConfirmation.sync="deleteConfirmation" :callback="deleteCurrentMessage" nameAction="delete")
    AboutUser(:visibleAboutUser.sync="popupAboutUser" :user="message.user")
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { namespace } from 'vuex-class';
import Confirmation from '@/components/ui/Confirmation.vue';
import AboutUser from '@/components/ui/AboutUser.vue';

const conversationStore = namespace('conversations');

@Component({
  components: { Confirmation, AboutUser },
})
export default class CardMessage extends Vue {
  @Prop(Object) message: any;
  @Prop(Function) editMessage: any;
  @conversationStore.State readonly currentUser: any;
  @conversationStore.Getter readonly currentConversationMyPermissions: any;
  @conversationStore.Mutation deleteMessageToConversation: any;
  @conversationStore.Action deleteMessage: any;

  public showMenu: boolean = false;
  public deleteConfirmation: boolean = false;
  public popupAboutUser: boolean = false;

  get isMyMessage(): boolean {
    return this.message.user.userId === this.currentUser.userId
  }

  get isCanDelete(): boolean {
    return this.isMyMessage ? this.currentConversationMyPermissions.canRemove : this.currentConversationMyPermissions.canRemoveAll
  }

  get isCanEdit(): boolean {
    return this.isMyMessage ? this.currentConversationMyPermissions.canEdit : this.currentConversationMyPermissions.canEditAll
  }

  deleteCurrentMessage() {
    this.deleteMessage(this.message);
  }

  editCurrentMessage() {
    this.editMessage(this.message);
  }
}
</script>

<style scoped>
.chatroom__card-wrapper {
  display: flex;
  padding: 12px 0;
}

.chatroom__card {
  display: flex;
  position: relative;
  width: 70%;
  align-items: flex-end;
}

.chatroom__card--me {
  flex-direction: row-reverse;
  margin-left: auto;
}

.chatroom__card--me .chatroom__card-title {
  text-align: end;
}

.chatroom__card--me .chatroom__card-text {
  background-color: var(--light-color);
}

.chatroom__card--user {
  flex-direction: row;
  margin-right: auto;
}

.chatroom__card--user .chatroom__card-text {
  background-color: var(--lighter-color);
}

.chatroom__card-ava {
  margin: 0 12px;
}

.chatroom__card-title {
  font-size: medium;
  font-weight: bold;
}

.chatroom__card-text {
  padding: 12px;
  border-radius: 10px;
  white-space: pre-line
}

.chatroom__card-time {
  font-size: small;
  font-weight: lighter;
  text-align: end;
  padding-left: 40px;
}

.chatroom__card--me .chatroom__card-time {
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
}
</style>
