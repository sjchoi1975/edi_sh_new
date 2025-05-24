<template>
  <div class="admin-notices-view">
    <div class="header-title">공지사항 목록</div>
    <div class="table-container">


      <DataTable
        :value="filteredNotices"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['title']"
        class="custom-table"
      >
        <template #header>
          <div class="table-header">
            <span class="p-input-icon-left">
              <InputText v-model="search" placeholder="제목 검색" style="width: 280px" />
            </span>
            <button class="btn-primary" @click="goCreate">등록</button>
          </div>
        </template>
        <Column field="is_pinned" header="필수" :headerStyle="{ width: '11%' }" :sortable="false">
          <template #body="slotProps">
            <span v-if="slotProps.data.is_pinned === true" class="required-badge">필수</span>
          </template>
        </Column>
        <Column field="title" header="제목" :headerStyle="{ width: '40%' }" :sortable="false">
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
        <Column field="file_count" header="첨부파일" :headerStyle="{ width: '11%' }">
          <template #body="slotProps">
            <span>
              {{ slotProps.data.file_count > 0 ? slotProps.data.file_count : '-' }}
            </span>
          </template>
        </Column>
        <Column field="view_count" header="조회수" :headerStyle="{ width: '11%' }" :sortable="false" />
        <Column field="created_at" header="작성일시" :headerStyle="{ width: '16%' }" :sortable="false">
          <template #body="slotProps">
            {{ formatKST(slotProps.data.created_at) }}
          </template>
        </Column>
        <Column field="btn-row" header="수정" :headerStyle="{ width: '11%' }">
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

const filters = ref({
  'global': { value: null, matchMode: 'contains' }
});

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
  console.log('공지사항 데이터:', data); // ← 이 줄만 추가!  
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
import { watch } from 'vue';

watch(filteredNotices, (val) => {
  console.log('filteredNotices:', val);
});
</script>