<script lang="ts">
import Vue from 'vue';

import { ipcRenderer } from '@pkg/utils/ipcRenderer';
import { Theme } from '@pkg/config/settings';
import electron from 'electron';

export default Vue.extend({
  name: 'preferences-layout',
  head() {
    const preferences = this.$store.getters['preferences/getPreferences'];
    const theme =
      preferences.application.theme !== Theme.SYSTEM
        ? preferences.application.theme
        : electron?.nativeTheme?.shouldUseDarkColors
        ? Theme.DARK
        : Theme.LIGHT;
    return { bodyAttrs: { class: `theme-${theme}` } };
  },
  mounted() {
    ipcRenderer.send('preferences/load');
  },
});
</script>

<template>
  <div class="wrapper">
    <Nuxt />
  </div>
</template>

<style lang="scss">
  @import "@pkg/assets/styles/app.scss";

  .wrapper {
    background-color: var(--body-bg);
  }
</style>
