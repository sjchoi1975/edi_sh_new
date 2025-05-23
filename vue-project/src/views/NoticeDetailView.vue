<template>
    <div class="notice-detail-view" v-if="notice">
      <h2>{{ notice.title }}</h2>
      <div class="meta">
        <span>작성일: {{ formatDate(notice.created_at) }}</span>
        <span v-if="notice.is_pinned" class="pinned">[고정]</span>
        <span>조회수: {{ notice.view_count }}</span>
      </div>
      <div class="content" v-html="notice.content"></div>
      <div class="file-list" v-if="notice.file_url && notice.file_url.length">
        <div v-for="(file, idx) in notice.file_url" :key="idx">
          <button type="button" @click="downloadFile(file)">
            {{ getFileName(file) }}
          </button>
        </div>
      </div>
      <div v-else>
        첨부파일 없음
      </div>
      <div class="btn-row" v-if="userType === 'admin'">
        <button @click="goEdit">수정</button>
        <button @click="handleDelete">삭제</button>
      </div>
    </div>
    <div v-else>
      <p>공지사항을 불러오는 중입니다...</p>
    </div>
  </template>
  
  <script setup>
  import { ref, onMounted } from 'vue';
  import { useRoute, useRouter } from 'vue-router';
  import { supabase } from '@/supabase';
  
  const route = useRoute();
  const router = useRouter();
  const notice = ref(null);
  
  const formatDate = (date) => {
    if (!date) return '';
    return new Date(date).toLocaleDateString();
  };
  
  onMounted(async () => {
    const { data } = await supabase
      .from('notices')
      .select('*')
      .eq('id', route.params.id)
      .single();
    // file_url이 문자열이면 배열로 변환
    if (data && data.file_url) {
      if (typeof data.file_url === 'string') {
        try {
          // JSON 문자열(배열)로 저장된 경우 파싱
          const arr = JSON.parse(data.file_url);
          notice.value = { ...data, file_url: Array.isArray(arr) ? arr : [data.file_url] };
        } catch {
          // 그냥 문자열이면 배열로 감싸기
          notice.value = { ...data, file_url: [data.file_url] };
        }
      } else if (Array.isArray(data.file_url)) {
        notice.value = data;
      }
    } else {
      notice.value = data;
    }
  });
  
  function goEdit() {
    router.push(`/admin/notices/${notice.value.id}/edit`);
  }
  
  async function handleDelete() {
    if (!confirm('정말 삭제하시겠습니까?')) return;
    const { error } = await supabase.from('notices').delete().eq('id', notice.value.id);
    if (error) {
      alert('삭제 실패: ' + error.message);
    } else {
      alert('삭제되었습니다.');
      router.push('/admin/notices');
    }
  }
  
  function getFileName(url) {
    try {
      return decodeURIComponent(url.split('/').pop().split('?')[0]);
    } catch {
      return '첨부파일';
    }
  }
  
  async function downloadFile(url) {
    try {
      const response = await fetch(url);
      const blob = await response.blob();
      const link = document.createElement('a');
      link.href = window.URL.createObjectURL(blob);
      link.download = getFileName(url);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(link.href);
    } catch (e) {
      alert('다운로드에 실패했습니다.');
    }
  }
  </script>
  
  <style scoped>
  .notice-detail-view {
    max-width: 700px;
    margin: 0 auto;
    padding: 2rem 1rem;
  }
  .meta {
    color: #888;
    font-size: 0.95rem;
    margin-bottom: 1.2rem;
    display: flex;
    gap: 1.5rem;
  }
  .pinned {
    color: #5fa56b;
    font-weight: bold;
  }
  .content {
    margin-top: 1.5rem;
    white-space: pre-line;
    font-size: 1.1rem;
  }
  .file-list {
    margin-top: 1.5rem;
    margin-bottom: 1.5rem;
  }
  .btn-row {
    margin-top: 1.5rem;
    display: flex;
    gap: 1rem;
  }
  </style>