<template lang="pug">
  v-container(pa-0)
    v-card-title(class="manage-members__title") Manage members
    v-card-text(class="py-0")
      v-col(cols="12" class="pa-0 px-2")
        ListUsers(:addAdmins="false" :getListUsersId="getListUsersId" :chatUsers="currentConversationUsers")
      v-card-actions
        div(class="flex-grow-1")
        v-btn(color="indigo darken-2" text @click="close") Close
        v-btn(color="red darken-1" text @click="handleDelete") Delete
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import ListUsers from '@/components/ui/ListUsers.vue';
import {namespace} from 'vuex-class';

const conversationStore = namespace('conversations');

@Component({
  components: { ListUsers },
})
export default class ManageMembers extends Vue {
  @Prop(Function) close!: any;
  @conversationStore.Getter readonly currentConversationUsers: any;
  @conversationStore.Action deleteParticipants: any;

  public selectedUsersId: number[] = [];

  getListUsersId(usersId: number[]) {
    this.selectedUsersId = usersId;
  }

  handleDelete() {
    this.deleteParticipants(this.selectedUsersId);
    this.close();
  }
}
</script>

<style scoped>
  .manage-members__title {
    padding-left: 84px;
    padding-top: 26px;
  }
</style>
