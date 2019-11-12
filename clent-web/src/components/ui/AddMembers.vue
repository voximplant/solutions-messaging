<template lang="pug">
  v-dialog(
    v-model="visibleAddMembers"
    persistent
    max-width="350"
    @click="$emit('update:visibleAddMembers', visibleAddMembers)"
  )
    v-card
      v-card-title(style="word-break: break-word") {{ addAdmins ? 'Add admins' : 'Add members'}}
      v-card-text
        ListUsers(:chips="true" :add="false" :getListUsersId="getListUsersId" :chatUsers="possibleUsers")
      v-card-actions
        div(class="flex-grow-1")
        v-btn(color="primary" text @click="$emit('update:visibleAddMembers', false)") Close
        v-btn(color="accent" text @click="handleAdd") Add
</template>

<script lang="ts">
  import { Component, Vue, Prop } from 'vue-property-decorator';

  import {namespace} from 'vuex-class';

  const conversationStore = namespace('conversations');

  @Component({
    components: { ListUsers: () => import('./ListUsers.vue') }
  })
  export default class AddMembers extends Vue {
    @Prop(Boolean) visibleAddMembers: boolean;
    @Prop(Function) callback: any;
    @Prop({ default: 'false' }) addAdmins!: boolean;

    @conversationStore.Getter readonly possibleChatUsers: any;
    @conversationStore.Getter readonly possibleChatAdmins: any;
    @conversationStore.Action addNewParticipants: any;
    @conversationStore.Action addNewAdmins: any;

    public selectedUsersId: number[] = [];

    get possibleUsers() {
      return this.addAdmins ? this.possibleChatAdmins : this.possibleChatUsers
    }

    getListUsersId(usersId: number[]) {
      this.selectedUsersId = usersId;
    }

    handleAdd(): void {
      if(this.addAdmins) {
        this.addNewAdmins(this.selectedUsersId);
      } else {
        this.addNewParticipants(this.selectedUsersId);
      }

      this.$emit('update:visibleAddMembers', false);
    }
  }
</script>

<style scoped>
</style>
