<template lang="pug">
  v-container(pa-0)
    v-dialog(
      v-model="dialog"
      @click="$emit('update:dialog', dialog)"
      persistent max-width="600px"
      class="create-chat__wrapper"
      height="400px"
      scrollable)
      v-form(ref="formCreateNewChat" v-model="validationForm")
        v-card(class="pa-0")
          v-card-title(class="create-chat__title")
            span(class="headline") Create new {{ type }}
          v-card-text
            v-container
              v-row(class="pa-0")
                v-col(cols="2")
                  v-avatar(color="indigo" @click="chooseAvatar = !chooseAvatar")
                    v-icon(v-if="!chatAvatar" dark) supervised_user_circle
                    img(v-else :src="require(`@/assets/avatars/${chatAvatar}.png`)")
                v-col(cols="7" class="create-chat__name pa-0")
                  v-text-field(
                    v-model="groupTitle"
                    label="Group name"
                    :rules="titleRules"
                    required
                    class="pr-6")
                v-col(cols="3" class="pa-0")
                  v-switch(v-model="isPublic" label="PUBLIC" small class="create-chat__switch")
                  v-switch(v-model="isUber" label="UBER" small class="create-chat__switch")
                v-col(cols="12" class="pa-0 create-chat__desc")
                  v-text-field(
                    label="Description"
                    v-model="desc"
                    :counter="67"
                    :rules="descRules"
                    hint="example of persistent helper text (max 67 symbols)"
                    persistent-hint)
                v-col(cols="12" class="pa-0")
                  ListUsers(:getListUsersId="getListUsersId" :add="false")
              small *indicates required field
          v-card-actions(class="create-chat__actions")
            div(class="flex-grow-1")
            v-btn(color="indigo darken-1" text @click="closeForm") Cancel
            v-btn(
              color="red darken-1"
              text
              @click="createNewConversation"
              :disabled="!validationForm || !selectedUsersId.length > 0") Create
    ChooseAvatar(:visibleChooseAvatar.sync="chooseAvatar" :setAvatar="setAvatar")
</template>

<script lang="ts">
import { Component, Vue, Prop } from 'vue-property-decorator';
import ListUsers from '@/components/ui/ListUsers.vue';
import ChooseAvatar from '@/components/ui/ChooseAvatar.vue';
import { namespace } from 'vuex-class';

const conversationStore = namespace('conversations');

@Component({
  components: { ChooseAvatar, ListUsers },
})
export default class CreateChat extends Vue {
  @Prop(Boolean) dialog: boolean;
  @Prop(String) type: string;

  @conversationStore.Action createConversation: any;

  public groupTitle: string = '';
  public desc: string = '';
  public chatAvatar: string = '';
  public isPublic: boolean = true;
  public isUber: boolean = true;
  public selectedUsersId: number[] = [];

  public validationForm: boolean = false;
  public chooseAvatar: boolean = false;
  public titleRules = [(v: string) => !!v || 'Name is required'];
  public descRules = [(v:string) => v.length <= 67 || 'Description must be not more than 67 characters'];

  setAvatar(newAvatar: any) {
    this.chatAvatar = newAvatar;
  }

  getListUsersId(usersId: number[]) {
    this.selectedUsersId = usersId;
  }

  createNewConversation() {
    this.createConversation({
      type: this.type,
      title: this.groupTitle,
      desc: this.desc,
      usersId: this.selectedUsersId,
      isPublic: this.isPublic,
      isUber: this.isUber,
      avatar: this.chatAvatar
    });
    this.closeForm();
  }

  closeForm() {
    this.$emit('update:dialog', false);
    this.resetForm();
  }

  private resetForm() {
    this.groupTitle = '';
    this.desc = '';
    this.chatAvatar = '';
    this.isPublic = true;
    this.isUber = true;
    this.selectedUsersId = [];
  }
}
</script>

<style scoped>
.create-chat__wrapper,
.create-chat__name,
.create-chat__desc,
.create-chat__actions{
  overflow: hidden;
}

.create-chat__switch {
  padding: 0;
  margin: 0;
  height: 35px;
  font-weight: normal;
}
</style>
