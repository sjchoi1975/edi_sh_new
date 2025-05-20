<template>
  <div class="admin-notices-view">
    <h2>공지사항 목록</h2>
    <p>이 페이지는 관리자만 접근할 수 있는 공지사항 관리 페이지입니다.</p>
    <!-- 여기에 PrimeVue DataTable 등을 사용하여 공지사항 목록 표시 예정 -->
  </div>
</template>

<script setup>
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();

onMounted(() => {
  console.log('[AdminNoticesView.vue] Component Mounted. Current Path:', router.currentRoute.value.path);
});

// 필요한 로직 추가 예정
</script>

<style scoped>
.admin-notices-view {
  padding: 1rem;
}
</style> 