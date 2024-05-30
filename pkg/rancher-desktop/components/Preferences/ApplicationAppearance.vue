<script lang="ts">
import Vue from 'vue';

import ThemeSelector from '@pkg/components/ThemeSelector.vue';
import RdFieldset from '@pkg/components/form/RdFieldset.vue';
import { Settings } from '@pkg/config/settings';
import { RecursiveTypes } from '@pkg/utils/typeUtils';

import type { PropType } from 'vue';

export default Vue.extend({
  name: 'preferences-application-appearance',
  components: { RdFieldset, ThemeSelector },
  props: {
    preferences: {
      type: Object as PropType<Settings>,
      required: true,
    },
  },
  methods: {
    onChange<P extends keyof RecursiveTypes<Settings>>(
      property: P,
      value: RecursiveTypes<Settings>[P]
    ) {
      this.$store.dispatch('preferences/updatePreferencesData', {
        property,
        value,
      });
    },
  },
});
</script>

<template>
  <div class="application-appearance">
    <rd-fieldset data-test="applicationTheme" legend-text="Application Theme">
      <template>
        <theme-selector
          :theme="preferences.application.theme"
          @change="onChange('application.theme', $event)"
        />
      </template>
    </rd-fieldset>
  </div>
</template>

<style lang="scss" scoped>
.application-appearance {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
</style>
