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
              href="#"
              class="file-link"
              @click.prevent="downloadFile(url, getFileName(url))"
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

async function downloadFile(url, name) {
  const res = await fetch(url);
  const blob = await res.blob();
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = name;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
</script> 