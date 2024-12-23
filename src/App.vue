<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  GlobalThemeOverrides,
  NConfigProvider,
  NLoadingBarProvider,
  NMessageProvider,
  darkTheme
} from 'naive-ui';

import { useStore } from '@/store';

import MainPage from '@/views/MainPage.vue';

const { locale } = useI18n();
const store = useStore();

const theme = computed(() => (store.state.darkMode ? darkTheme : null));
const override = computed(
  () =>
    ({
      common: {
        primaryColor: store.state.darkMode ? '#ffffff' : '#014099',
        primaryColorHover: store.state.darkMode ? '#fcfcfc' : '#014099',
        primaryColorPressed: store.state.darkMode ? 'd4d4d4' : '#560c56',
        primaryColorSuppl: '#014099'
      }
    } as GlobalThemeOverrides)
);

onMounted(
  () => (locale.value = navigator.language.startsWith('zh') ? 'zh' : 'en')
);
</script>

<template>
  <NConfigProvider :theme="theme" :theme-overrides="override">
    <NLoadingBarProvider>
      <NMessageProvider>
        <MainPage />
      </NMessageProvider>
    </NLoadingBarProvider>
  </NConfigProvider>
</template>

<style lang="less">
body {
  overflow: hidden;
  --header-height: 60px;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
</style>
