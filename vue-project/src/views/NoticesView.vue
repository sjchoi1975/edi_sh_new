<template>
  <div class="notices-view">
    <h1>공지사항</h1>
    <p>사용자를 위한 공지사항 목록입니다.</p>
    <DataTable :value="notices" :loading="loading" responsiveLayout="scroll">
      <Column field="title" header="제목">
        <template #body="slotProps">
          <a
            href="#"
            style="color:#1976d2;text-decoration:underline;cursor:pointer;"
            @click.prevent="goToDetail(slotProps.data.id)"
          >
            {{ slotProps.data.title }}
          </a>
        </template>
      </Column>
      <Column field="created_at" header="작성일" :body="formatDate" />
      <Column field="is_pinned" header="고정" :body="pinTemplate" />
      <Column field="view_count" header="조회수" />
    </DataTable>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { useRouter } from 'vue-router';

const notices = ref([]);
const loading = ref(false);
const router = useRouter();

const formatDate = (row) => {
  if (!row.created_at) return '';
  return new Date(row.created_at).toLocaleDateString();
};

const pinTemplate = (row) => row.is_pinned ? '고정' : '';

function goToDetail(id) {
  router.push(`/notices/${id}`);
}

onMounted(async () => {
  loading.value = true;
  const { data, error } = await supabase
    .from('notices')
    .select('id, title, created_at, is_pinned, view_count')
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false });
  if (!error) notices.value = data;
  loading.value = false;
});
</script>

<style scoped>
.notices-view {
  padding: 1.5rem;
  max-width: 900px;
  margin: 0 auto;
}
.custom-table :deep(.p-datatable-thead > tr > th),
.custom-table :deep(.p-datatable-tbody > tr > td) {
  font-size: 14px;
  padding: 10px 8px;
}
</style>