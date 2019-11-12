<template lang="pug">
  v-container(pa-0)
    v-card-title(class="manage-admins__title") Manage admins
    v-card-text(class="py-0")
      v-col(cols="12" class="pa-0")
        ListUsers(
          :chips="true"
          :addAdmins="true"
          :getListUsersId="getListUsersId"
          :chatUsers="currentConversationAdmins")
        v-card-actions
          div(class="flex-grow-1")
          v-btn(color="indigo darken-2" text @click="close") Close
          v-btn(color="red darken-1" text @click="() => {}") Delete
</template>

<script lang="ts">
import { Component, Vue, Prop } from 'vue-property-decorator';
import ListUsers from '@/components/ui/ListUsers.vue';
import {namespace} from 'vuex-class';

const conversationStore = namespace('conversations');

@Component({
  components: { ListUsers },
})

export default class ManageAdmins extends Vue {
  @Prop(Function) close!: any;
  @conversationStore.Getter readonly currentConversationAdmins: any;

  public selectedUsersId: number[] = [];

  getListUsersId(usersId: number[]) {
    this.selectedUsersId = usersId;
  }
}
</script>

<style scoped>
  .manage-admins__title {
    padding-left: 84px;
    padding-top: 26px;
  }
</style>
