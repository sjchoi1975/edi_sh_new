<template>
  <div class="board_960">
    <div class="form-title">공지사항 상세</div>
    <div class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col col-3">
          <label>제목</label>
          <span class="input-readonly">{{ notice.title }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>내용</label>
          <span class="input-readonly" style="white-space: pre-line; min-height: 200px; display: block;">{{ notice.content }}</span>
        </div>
      </div>
      <div class="form-row" style="justify-content: flex-start;">
        <div class="form-col" style="display: flex; align-items: center; width: auto; flex: none;">
          <span style="margin:0;">필수 공지 (상단 고정)</span>
          <input type="checkbox" :checked="notice.is_pinned" disabled style="width:16px; height:16px; margin-left:8px;" />
        </div>
      </div>
      <div v-if="notice.file_url && notice.file_url.length > 0" class="form-row file-row">
        <div class="form-col col-3">
          <label>첨부 파일</label>
          <div class="file-list">
            <div v-for="(url, idx) in notice.file_url" :key="url" class="file-item">
              <a :href="url" class="file-link" :download="getFileName(url)">{{ getFileName(url) }}</a>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="btn-row" style="justify-content: flex-end; margin-top: 1.2rem; gap: 0.5rem;">
      <button class="btn-list" type="button" @click="goList">목록</button>
    </div>
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
    const fileName = url.split('/').pop();
    const decodedName = decodeURIComponent(fileName);
    return decodedName.replace(/^[0-9]+_/, '');
  } catch {
    return url;
  }
}

function goEdit() {
  router.push(`/admin/notices/${route.params.id}/edit`);
}
function goList() {
  router.push('/notices');
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