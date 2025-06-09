<template>
  <div class="manual-container">
    <iframe
      v-if="manualUrl"
      :src="manualUrl"
      frameborder="0"
      style="width:100%; min-height:80vh; background:#fff;"
    ></iframe>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

const route = useRoute();
const manualUrl = computed(() => {
  if (route.path === '/admin-manual') {
    return '/docs/admin_manual.html';
  }
  return '/docs/user_manual.html';
});
</script>

<style scoped>
.manual-container {
  padding: 2rem;
  background: #f4f6fa;
  min-height: 80vh;
}
</style> 