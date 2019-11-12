<template lang="pug">
  v-container(pa-0)
    v-card-title(class="edit-permissions__title") Edit permissions
    v-card-text(class="py-0")
      v-row(class="pa-0 ma-0 mb-8")
        v-col(cols="6" class="pa-0")
          v-switch(v-model="permissions.canWrite" label="Can write" small class="edit-permissions__switch")
          v-switch(v-model="permissions.canEdit" label="Can edit" small class="edit-permissions__switch")
          v-switch(v-model="permissions.canEditAll" label="Can edit all" small class="edit-permissions__switch")
        v-col(cols="6" class="pa-0")
          v-switch(v-model="permissions.canRemove" label="Can delete" small class="edit-permissions__switch")
          v-switch(v-model="permissions.canRemoveAll" label="Can delete all" small class="edit-permissions__switch")
          v-switch(v-model="permissions.canManageParticipants" label="Can manage members" small class="edit-permissions__switch")
      v-card-actions
        div(class="flex-grow-1")
        v-btn(color="indigo darken-2" text @click="close") Close
        v-btn(color="red darken-1" text @click="handleEdit") Edit
</template>

<script lang="ts">
import { Component, Vue, Prop } from 'vue-property-decorator';
import ListUsers from '@/components/ui/ListUsers.vue';
import {namespace} from 'vuex-class';

const conversationStore = namespace('conversations');

@Component({
  components: { ListUsers },
})
export default class EditPermissions extends Vue {
  @Prop(Function) close!: any;
  @conversationStore.Getter readonly currentConversationUsers: any;
  @conversationStore.Getter readonly currentConversationPermissions: any;
  @conversationStore.Action editChatPermissions: any;

  public permissions: {
    canWrite: boolean,
    canManageParticipants: boolean,
    canEdit: boolean,
    canEditAll: boolean,
    canRemove: boolean,
    canRemoveAll: boolean,
  } = {
    canWrite: false,
    canManageParticipants: false,
    canEdit: false,
    canEditAll: false,
    canRemove: false,
    canRemoveAll: false,
  };

  mounted() {
    this.permissions = {
      canWrite: this.currentConversationPermissions.canWrite,
      canManageParticipants: this.currentConversationPermissions.canManageParticipants,
      canEdit: this.currentConversationPermissions.canEdit,
      canEditAll: this.currentConversationPermissions.canEditAll,
      canRemove: this.currentConversationPermissions.canRemove,
      canRemoveAll: this.currentConversationPermissions.canRemoveAll,
    };
  }

  handleEdit() {
    this.editChatPermissions(this.permissions);
    this.close();
  }
}
</script>

<style scoped>
.edit-permissions__title {
  padding-left: 84px;
  padding-top: 26px;
  padding-bottom: 24px;
}

.edit-permissions__switch {
  height: 30px;
}
</style>
