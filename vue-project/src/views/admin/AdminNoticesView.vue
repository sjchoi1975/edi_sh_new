<template>
  <div class="admin-notices-view page-container">
    <div class="page-header-title-area">
      <div class="header-title">공지사항 목록</div>
    </div>
    <div class="filter-card">
      <div class="filter-row" style="display:flex; align-items:center; justify-content:flex-start;">
        <div style="display:flex; align-items:center;">
          <span class="filter-item p-input-icon-left" style="position:relative; width:320px;">
            <InputText
              v-model="searchInput"
              placeholder="제목, 내용 검색"
              class="search-input"
              @keyup.enter="doSearch"
            />
            <button
              v-if="searchInput.length > 0"
              class="clear-btn"
              @click="clearSearch"
              title="검색어 초기화">
              ×
            </button>
          </span>
          <button
            class="search-btn"
            :disabled="searchInput.length < 2"
            @click="doSearch">
            검색
          </button>
        </div>
      </div>
    </div>

    <div class="data-card">
      <div class="data-card-header">
        <div class="total-count-display">
          전체 {{ filteredNotices.length }} 건
        </div>
        <div class="action-buttons-group">
          <button class="btn-save" @click="goCreate">신규 등록</button>
        </div>
      </div>

      <DataTable
        :value="filteredNotices"
        :loading="loading"
        paginator
        :rows="50"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="calc(100vh - 250px)"
        class="admin-notices-table"
        v-model:first="currentPageFirstIndex"
      >
        <template #empty>
          <div v-if="!loading">등록된 공지사항이 없습니다.</div>
        </template>
        <template #loading>공지사항 목록을 불러오는 중입니다...</template>
        
        <Column header="No" :headerStyle="{ width: columnWidths.no }">
          <template #body="slotProps">{{ slotProps.index + currentPageFirstIndex + 1 }}</template>
        </Column>
        <Column field="is_pinned" header="필수" :headerStyle="{ width: columnWidths.is_pinned }">
          <template #body="slotProps">
            <span v-if="slotProps.data.is_pinned === true" class="required-badge">필수</span>
          </template>
        </Column>
        <Column field="title" header="제목" :headerStyle="{ width: columnWidths.title }">
          <template #body="slotProps">
            <a href="#" class="text-link" @click.prevent="goToDetail(slotProps.data.id)">{{ slotProps.data.title }}</a>
          </template>
        </Column>
        <Column field="content" header="내용" :headerStyle="{ width: columnWidths.content }">
          <template #body="slotProps">
            <span class="content-preview">{{ slotProps.data.content }}</span>
          </template>
        </Column>
        <Column field="file_count" header="첨부파일" :headerStyle="{ width: columnWidths.file_count }">
          <template #body="slotProps">
            <span>{{ slotProps.data.file_count > 0 ? slotProps.data.file_count : '-' }}</span>
          </template>
        </Column>
        <Column field="view_count" header="조회수" :headerStyle="{ width: columnWidths.view_count }" />
        <Column field="created_at" header="작성일시" :headerStyle="{ width: columnWidths.created_at }">
          <template #body="slotProps">{{ formatKST(slotProps.data.created_at) }}</template>
        </Column>
      </DataTable>
    </div>

    <!-- 전체 화면 로딩 오버레이 -->
    <div v-if="loading" class="loading-overlay">
      <div class="loading-content">
        <div class="loading-spinner"></div>
        <div class="loading-text">목록을 불러오는 중입니다...</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { supabase } from '@/supabase';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import { useRouter } from 'vue-router';
import InputText from 'primevue/inputtext';

const notices = ref([]);
const loading = ref(false);
const router = useRouter();
const userType = ref('');
const searchInput = ref('');
const searchKeyword = ref('');
const filteredNotices = ref([]);
const currentPageFirstIndex = ref(0);

// 컬럼 너비 한 곳에서 관리
const columnWidths = {
  no: '4%',
  is_pinned: '6%',
  title: '32%',
  content: '40%',
  file_count: '6%',
  view_count: '6%',
  created_at: '10%'
};

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

function doSearch() {
  if (searchInput.value.length >= 2) {
    searchKeyword.value = searchInput.value;
    const keyword = searchKeyword.value.toLowerCase();
    filteredNotices.value = notices.value.filter(n =>
      n.title && n.title.toLowerCase().includes(keyword)
    );
  }
}
function clearSearch() {
  searchInput.value = '';
  searchKeyword.value = '';
  filteredNotices.value = notices.value;
}

// notices가 바뀌면 전체로 복원
watch(notices, (newVal) => {
  filteredNotices.value = newVal;
}, { immediate: true });

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
    .select('id, title, content, created_at, is_pinned, view_count, file_url')
    .order('is_pinned', { ascending: false })
    .order('created_at', { ascending: false });
  console.log('공지사항 데이터:', data);
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

