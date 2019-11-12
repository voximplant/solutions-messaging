<template lang="pug">
  v-container(fluid fill-height class="chat__wrapper")
    div(class="chat__no-selected") Please, select a chat to start messaging
</template>

<script lang="ts">
import Vue from 'vue';
import { Component } from 'vue-property-decorator';

@Component({})
export default class Chat extends Vue {}
</script>

<style scoped>
.chat__wrapper {
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.chat__no-selected {
  font-weight: lighter;
}
</style>
