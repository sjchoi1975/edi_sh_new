<template>
  <div class="board_640">
    <div class="form-title">공지사항 상세</div>
    <form class="form-grid-2x">
      <div class="form-group">
        <label>제목</label>
        <input :value="notice.title" type="text" readonly disabled />
      </div>
      <div class="form-group">
        <label>내용</label>
        <div class="input-readonly-detail">{{ notice.content }}</div>
      </div>
      <div class="form-group">
        <label>필수</label>
        <div>
          <input type="checkbox" :checked="notice.is_pinned" disabled style="width:16px; height:16px; vertical-align:middle;" />
          <span style="margin-left:8px;">상단 고정</span>
        </div>
      </div>
      <div class="form-group" v-if="notice.file_url && notice.file_url.length > 0">
        <label>첨부 파일</label>
        <div>
          <div v-for="(url, idx) in notice.file_url" :key="url" style="margin-bottom:0.5rem;">
            <a @click.prevent="downloadFile(url)" class="file-link" style="cursor: pointer;">{{ getFileName(url) }}</a>
          </div>
        </div>
      </div>
      <div style="justify-content: flex-end; margin-top: 2rem;">
        <button class="btn-delete" type="button" @click="handleDelete" style="margin-right: 1rem;">삭제</button>
        <button class="btn-edit" type="button" @click="goEdit" style="margin-right: 1rem;">수정</button>
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
    const fileName = url.split('/').pop();
    const decodedName = decodeURIComponent(fileName);
    return decodedName.replace(/^[0-9]+_/, '');
  } catch {
    return url;
  }
}

async function downloadFile(fileUrl) {
  try {
    const url = new URL(fileUrl);
    // URL 경로에서 버킷 이름(예: /object/public/notices/) 부분을 제외하고 실제 파일 경로만 추출
    const filePath = url.pathname.split('/').slice(6).join('/');
    const fileName = getFileName(fileUrl);

    const { data, error } = await supabase.storage
      .from('notices') // 공지사항 파일이 저장된 버킷 이름
      .download(filePath);
      
    if (error) throw error;

    const blobUrl = URL.createObjectURL(data);
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(blobUrl);

  } catch (err) {
    console.error('파일 다운로드 오류:', err);
    alert('파일을 다운로드하는 중 오류가 발생했습니다.');
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