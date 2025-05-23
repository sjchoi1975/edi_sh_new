<template>
  <div class="admin-notices-view">
    <div class="notices-header">공지사항 목록</div>
    <div class="table-container">
      <DataTable :value="filteredNotices" :loading="loading" :paginator="true" :rows="20" :rowsPerPageOptions="[10, 20, 50, 100]" scrollable scrollHeight="600px" responsiveLayout="scroll" class="custom-table">
        <template #header>
          <div class="table-header">
            <span class="p-input-icon-left">
              <!--<i class="pi pi-search"></i> -->
              <InputText v-model="search" placeholder="제목 검색" />
            </span>
            <button class="btn-primary" @click="goCreate">등록</button>
              <!--<i class="pi pi-plus"></i> -->
          </div>
        </template>
        <Column field="is_pinned" header="필수" :sortable="true">
          <template #body="slotProps">
            <span v-if="slotProps.data.is_pinned === true" class="required-badge">필수</span>
          </template>
        </Column>
        <Column field="title" header="제목" :sortable="true">
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
        <Column field="file_count" header="첨부파일">
          <template #body="slotProps">
            <span>
              {{ slotProps.data.file_count > 0 ? slotProps.data.file_count : '-' }}
            </span>
          </template>
        </Column>
        <Column field="view_count" header="조회수" :sortable="true" />
        <Column field="created_at" header="작성일시" :sortable="true">
          <template #body="slotProps">
            {{ formatKST(slotProps.data.created_at) }}
          </template>
        </Column>
        <Column field="btn-row" header="">
          <template #body="slotProps">
            <div class="btn-row" v-if="userType === 'admin'">
              <button class="btn-edit" @click="goEdit(slotProps.data.id)">수정</button>
            </div>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { useRouter } from 'vue-router';
import InputText from 'primevue/inputtext';
import Button from 'primevue/button';

const notices = ref([]);
const loading = ref(false);
const router = useRouter();
const userType = ref('');
const search = ref('');

function goCreate() {
  router.push('/admin/notices/create');
}

function goToDetail(id) {
  router.push(`/admin/notices/${id}`);
}

function goEdit(id) {
  router.push(`/admin/notices/${id}/edit`);
}

function formatKST(dateStr) {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  // UTC → KST 변환
  date.setHours(date.getHours() + 9);
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  const hh = String(date.getHours()).padStart(2, '0');
  const min = String(date.getMinutes()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd} ${hh}:${min}`;
}

const filteredNotices = computed(() => {
  if (!search.value) return notices.value;
  return notices.value.filter(n =>
    n.title?.includes(search.value) ||
    formatKST(n.created_at)?.includes(search.value)
  );
});

async function handleDelete(id) {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const { error } = await supabase.from('notices').delete().eq('id', id);
  if (error) {
    alert('삭제 실패: ' + error.message);
  } else {
    alert('삭제되었습니다.');
    router.push('/admin/notices'); // 삭제 후 목록으로 이동
  }
}

onMounted(async () => {
  loading.value = true;
  const { data, error } = await supabase
    .from('notices')
    .select('id, title, created_at, is_pinned, view_count, file_url')
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false });
  if (!error && data) {
    notices.value = data.map(n => {
      let count = 0;
      try {
        const arr = JSON.parse(n.file_url || '[]');
        count = Array.isArray(arr) ? arr.length : 0;
      } catch {
        count = 0;
      }
      return { ...n, file_count: count };
    });
  }
  loading.value = false;
  const { data: { session } } = await supabase.auth.getSession();
  userType.value = session?.user?.user_metadata?.user_type || '';
});
</script>

<style scoped>
.admin-notices-view {
  padding: 0;
  margin: 0;
}

.notices-header {
  font-size: 1.35rem;
  font-weight: 700;
  color: #222;
  margin-bottom: 16px;
  margin-left: 0;
  margin-top: 0;
  padding-left: 0;
  padding-top: 0;
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 0.5rem;
  padding-left: 0;
  padding-right: 0;
}

.required-badge {
  background: #66f;
  color: #fff;
  border-radius: 2px;
  padding: 2px 8px;
  font-size: 0.85rem;
  display: inline-block;
}

/* 테이블 전체 테두리 및 배경 */
.custom-table :deep(.p-datatable) {
  border-radius: 4px;
  border: 1px solid #e0e0e0;
  background: #fff;
}

/* 헤더 셀 */
.custom-table :deep(.p-datatable-thead > tr > th) {
  background: #f8fafb;
  color: #222;
  font-weight: 600;
  font-size: 14px;
  border-bottom: 1px solid #e0e0e0;
  padding: 10px 8px;
}

/* 바디 셀 */
.custom-table :deep(.p-datatable-tbody > tr > td) {
  font-size: 14px;
  padding: 10px 8px;
}

/* 첫 번째 컬럼 왼쪽 선 */
.custom-table :deep(.p-datatable-thead > tr > th:first-child),
.custom-table :deep(.p-datatable-tbody > tr > td:first-child),
.custom-table :deep(.p-datatable-tfoot > tr > td:first-child) {
  border-left: 1px solid #e0e0e0;
}

/* 마지막 컬럼 오른쪽 선 */
.custom-table :deep(.p-datatable-thead > tr > th:last-child),
.custom-table :deep(.p-datatable-tbody > tr > td:last-child),
.custom-table :deep(.p-datatable-tfoot > tr > td:last-child) {
  border-right: 1px solid #e0e0e0;
}

.btn-row {
  display: flex;
  gap: 0.5rem;
}

.table-container {
  background: #fff;
  border: 1.5px solid #e0e0e0;
  border-radius: 4px;
  box-shadow: 0 1px 4px 0 rgba(0,0,0,0.03);
  padding: 16px;
  margin: 0;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.top-btns {
  display: flex;
  gap: 0.5rem;
}
</style> 