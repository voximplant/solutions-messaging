<template lang="pug">
  v-container(class="pa-0 pt-4")
    v-container(class="pa-0")
      v-row(align="center" justify="start")
        v-row(v-if="isChips" class="pl-5")
          v-col(v-for="(selection, i) in selections" :key="'selection-' + selection.userId" class="shrink pa-1")
            v-chip(:disabled="loading" close @click:close="selected.splice(i, 1)")
              v-avatar(v-if="selection.customData.image" size="24" class="chip-user__avatar")
                img(left :src="require(`@/assets/avatars/${selection.customData.image}.png`)" :disabled="loading")
              v-icon(left v-else :disabled="loading" dark) account_circle
              div {{ selection.displayName }}
        v-col(:cols="isAdd ? '11' : '12'" class="pa-0")
          v-text-field(
            prepend-inner-icon="search"
            class="pa-0"
            ref="search"
            v-model="search"
            full-width
            hide-details
            @keypress.enter="searchUser"
            @blur="searchUser"
            label="Search"
            single-line)
        v-col(v-if="!allSelected && isAdd" cols="1" class="pa-0")
          v-btn(icon small color="indigo" @click="showAddMembers = !showAddMembers")
            v-icon person_add

    v-divider(v-if="!allSelected")

    v-list(class="list-users__wrapper")
      template(v-for="(user) in categories")
        v-list-item(v-if="!selected.find((s) => s.userId === user.userId)" :key="'categories-' + user.userId" :disabled="loading" @click="chooseUser(user)")
          v-list-item-avatar(color="indigo")
            img(v-if="user.customData.image" :src="require(`@/assets/avatars/${user.customData.image}.png`)" :disabled="loading")
            v-icon(v-else :disabled="loading" dark) account_circle
          v-list-item-title(v-text="user.displayName")
    AddMembers(:visibleAddMembers.sync="showAddMembers" :addAdmins="isAdmins")
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator';
import { namespace } from 'vuex-class';
import { log, logHelp } from '@/utils';
import AddMembers from '@/components/ui/AddMembers.vue';
import { User } from '@/types/src/conversations';
import MessengerService from '@/services/messenger.service';
import { MY_APP } from '@/config';

const conversationStore = namespace('conversations');

@Component({
  components: { AddMembers },
})
export default class ListUsers extends Vue {
  // TODO 3 types of list: all users, current conversation users, possible users for adding
  @Prop({ default: 'true' }) chips: boolean;
  @Prop({ default: 'true' }) add!: boolean;
  @Prop() addAdmins: boolean;
  @Prop() getListUsersId: any;
  @Prop() showUserInfo: any;
  @Prop() chatUsers: any;

  @conversationStore.State readonly users: any;
  @conversationStore.Action addUser: any;

  public loading = false;
  public search: string = '';
  public selected: any[] = [];
  public showAddMembers: boolean = false;
  private inputDebounced = false;

  @Watch('selected')
  onSelectedChanged() {
    this.search = ''
  }

  @Watch('search')
  searchUserThrottled() {
    if (this.inputDebounced) return;
    this.searchUser();
    this.inputDebounced = true;
    setTimeout(() => {
      this.inputDebounced = false;
      this.searchUser();
    }, 1500);
  }

  searchUser() {
    if (!this.search) return;
    const fullUserName = `${this.search.toLowerCase()}@${MY_APP}.voximplant.com`;
    MessengerService.messenger.getUser(fullUserName).then((user: any) => {
      this.addUser(user);
    }).catch((e: any) => {
    });
  }

  get isChips() {
    return this.chips;
  }

  get isAdd() {
    return this.add;
  }

  get isAdmins() {
    return this.addAdmins;
  }

  get allSelected() {
    return this.selected.length === this.users.length;
  }

  get categories() {
    const search = this.search.toLowerCase();

    const users = this.chatUsers || this.users;

    if (!search) return users;

    return users.filter((item: User) => {
      const text = item.displayName.toLowerCase();

      return text.indexOf(search) > -1;
    })
  }

  get selections() {
    const selections = this.selected;

    this.getListUsersId(selections.map((u) => u.userId));

    return selections;
  }

  chooseUser(user: object) {
    if(this.isChips) {
      this.selected.push(user)
    } else {
      this.showUserInfo(user);
    }
  }
}
</script>

<style scoped>
.list-users__wrapper{
  overflow: auto;
  max-height: 250px;
 }

  .chip-user__avatar {
    margin-left: -6px;
    margin-right: 8px;
  }
</style>
