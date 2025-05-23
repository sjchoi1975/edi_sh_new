<template>
  <div class="notice-detail-view">
    <div class="detail-header">
      <h2>공지사항 상세</h2>
      <div class="top-btns">
        <button class="btn-delete" type="button" @click="handleDelete">삭제</button>
        <button class="btn-edit" type="button" @click="goEdit">수정</button>
      </div>
    </div>
    <form class="notice-form">
      <div class="form-row">
        <label>제목</label>
        <div class="readonly-box">{{ notice.title }}</div>
      </div>
      <div class="form-row">
        <label>내용</label>
        <div class="readonly-box content">{{ notice.content }}</div>
      </div>
      <div class="form-row">
        <label>
          <input type="checkbox" :checked="notice.is_pinned" disabled />
          상단 고정(필수공지)
        </label>
      </div>
      <div class="form-row" v-if="notice.file_url && notice.file_url.length">
        <label>첨부 파일</label>
        <div class="readonly-box file-list">
          <div v-for="(url, idx) in notice.file_url" :key="url">
            <a
              :href="url"
              class="file-link"
              :download="getFileName(url)"
            >
              {{ getFileName(url) }}
            </a>
          </div>
        </div>
      </div>
      <div class="btn-row" style="justify-content: flex-end;">
        <button class="btn-list" type="button" @click="goList">목록</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const route = useRoute();
const router = useRouter();
const notice = ref({ title: '', content: '', is_pinned: false, file_url: [] });

onMounted(async () => {
  const { data, error } = await supabase
    .from('notices')
    .select('id, title, content, is_pinned, file_url')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    // file_url이 문자열이면 파싱
    if (typeof data.file_url === 'string') {
      try {
        data.file_url = JSON.parse(data.file_url);
      } catch {
        data.file_url = [];
      }
    }
    notice.value = data;
  }
});

function getFileName(url) {
  if (!url) return '';
  try {
    // URL에서 마지막 부분만 추출
    const fileName = url.split('/').pop();
    // URL 디코딩
    const decodedName = decodeURIComponent(fileName);
    // 타임스탬프_ 제거
    return decodedName.replace(/^\d+_/, '');
  } catch {
    return url;
  }
}

function goEdit() {
  router.push(`/admin/notices/${route.params.id}/edit`);
}
function goList() {
  router.push('/admin/notices');
}
async function handleDelete() {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const { error } = await supabase.from('notices').delete().eq('id', route.params.id);
  if (!error) {
    alert('삭제되었습니다.');
    router.push('/admin/notices');
  } else {
    alert('삭제 실패: ' + error.message);
  }
}
</script>

<style scoped>
.notice-detail-view {
  max-width: 960px;
  margin: 1rem auto;
  padding: 1.5rem 2rem 2rem 2rem;
  background: #fff;
  border: 1px solid #ddd;
  border-radius: 4px;
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
.notice-form {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.form-row {
  display: flex;
  flex-direction: column;
  margin-top: 1.0rem;
  gap: 0.5rem;
  font-size: 1rem;
  font-weight: 600;
}
.readonly-box {
  background: #f8f8f8;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 8px 12px;
  font-size: 1rem;
  font-weight: 400;
  color: #333;
}
.readonly-box.content {
  min-height: 120px;
  white-space: pre-line;
}
.file-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.file-link {
  color: #1976d2;
  text-decoration: underline;
  font-size: 0.98rem;
}
.btn-row {
  display: flex;
  flex-direction: row;
  gap: 1rem;
}
.top-btns {
  justify-content: flex-end;
  margin-bottom: 0.5rem;
}
.bottom-btns {
  justify-content: flex-end;
  margin-top: 1.5rem;
}
</style> 