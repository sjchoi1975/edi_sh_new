<template>
  <div class="notice-detail-view">
    <div class="detail-header">
      <h2>공지사항</h2>
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
const notice = ref({ title: '', content: '', file_url: [] });

onMounted(async () => {
  const { data, error } = await supabase
    .from('notices')
    .select('*')
    .eq('id', route.params.id)
    .single();
  
  if (!error && data) {
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
    return decodedName.replace(/^\d+_/, '');
  } catch {
    return url;
  }
}

function goList() {
  router.push('/notices');
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

<style scoped>
.notice-detail-view {
  padding: 20px;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.form-row {
  margin-bottom: 20px;
}

.form-row label {
  display: block;
  margin-bottom: 8px;
  font-weight: bold;
}

.readonly-box {
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background-color: #f9f9f9;
}

.content {
  min-height: 200px;
  white-space: pre-wrap;
}

.file-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.file-link {
  color: #0066cc;
  text-decoration: none;
}

.file-link:hover {
  text-decoration: underline;
}

.btn-row {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.btn-list {
  padding: 8px 16px;
  background-color: #666;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-list:hover {
  background-color: #555;
}
</style>