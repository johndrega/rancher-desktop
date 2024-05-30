<script>
import { RadioGroup } from '@rancher/components';
import { Theme } from '@pkg/config/settings';
export default {
  components: { RadioGroup },
  props: {
    theme: {
      type: Theme,
      default: 'system',
    },
    row: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    options() {
      return Object.values(Theme).map((x) => ({
        label: this.t(`applicationTheme.options.${x}.label`),
        value: x,
        description: this.t(`applicationTheme.options.${x}.description`),
      }));
    },
  },
  methods: {
    updateTheme(value) {
      this.$emit('change', value);
    },
  },
};
</script>

<template>
  <div class="theme-selector">
    <radio-group
      name="applicationTheme"
      class="application-theme"
      :value="theme"
      :options="options"
      :row="row"
      @input="updateTheme"
    >
      <template #label>
        <slot name="label" />
      </template>
    </radio-group>
  </div>
</template>

<style lang="scss" scoped>
.application-theme::v-deep label {
  color: var(--input-label);
}
</style>
