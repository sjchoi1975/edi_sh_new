<template>
  <div class="notice-create-view">
    <h2 style="margin-top:0;">공지사항 수정</h2>
    <form @submit.prevent="handleSubmit" class="notice-form">
      <div class="form-row">
        <label>제목</label>
        <div class="readonly-box">
          <input v-model="title" type="text" required style="background:transparent; border:none; width:100%; font-size:1rem;" />
        </div>
      </div>
      <div class="form-row">
        <label>내용</label>
        <div class="readonly-box content">
          <textarea v-model="content" rows="12" required style="background:transparent; border:none; width:100%; font-size:1rem; resize:vertical;" />
        </div>
      </div>
      <div class="form-row">
        <label>
          <input type="checkbox" v-model="isPinned" />
          상단 고정(필수공지)
        </label>
      </div>
      <div class="form-row file-row">
        <label class="file-label" for="fileInput">파일 첨부</label>
        <input
          id="fileInput"
          type="file"
          multiple
          @change="onFileChange"
          ref="fileInput"
          style="display:none"
        />
        <div v-if="files.length" class="readonly-box file-list">
          <div v-for="(f, idx) in files" :key="f.name + idx" class="file-item">
            <a
              :href="f.url"
              class="file-link"
              :download="f.name"
            >
              {{ f.name }}
            </a>
            <span class="file-remove" @click="removeFile(idx)">삭제</span>
          </div>
        </div>
      </div>
      <div class="btn-row" style="justify-content: flex-end;">
        <button class="btn-cancel" type="button" @click="goList">취소</button>
        <button class="btn-primary" type="submit">저장</button>
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
const title = ref('');
const content = ref('');
const isPinned = ref(false);
const files = ref([]);
const fileInput = ref(null);

onMounted(async () => {
  const { data, error } = await supabase
    .from('notices')
    .select('*')
    .eq('id', route.params.id)
    .single();
  
  if (error) {
    alert('데이터 로드 실패: ' + error.message);
    router.push('/admin/notices');
    return;
  }

  title.value = data.title;
  content.value = data.content;
  isPinned.value = data.is_pinned;
  
  // 기존 파일 URL들을 files 배열에 추가
  if (data.file_url) {
    let fileUrls = [];
    // 문자열이면 파싱
    if (typeof data.file_url === 'string') {
      try {
        fileUrls = JSON.parse(data.file_url);
      } catch {
        fileUrls = [data.file_url];
      }
    } else if (Array.isArray(data.file_url)) {
      fileUrls = data.file_url;
    }
    
    // URL 배열을 files 배열로 변환
    files.value = fileUrls.map(url => ({
      name: getFileName(url),
      url: url
    }));
  }
});

function sanitizeFileName(name) {
  return name.replace(/[^a-zA-Z0-9._-]/g, '_');
}

function onFileChange(e) {
  const selected = Array.from(e.target.files);
  files.value = files.value.concat(selected).slice(0, 5);
  e.target.value = '';
}

function removeFile(idx) {
  files.value.splice(idx, 1);
}

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

const handleSubmit = async () => {
  if (!title.value.trim() || !content.value.trim()) {
    alert('제목과 내용을 입력하세요.');
    return;
  }

  let fileUrls = [];
  for (const f of files.value) {
    if (f.url) {
      // 기존 파일은 URL 그대로 사용
      fileUrls.push(f.url);
    } else {
      // 새로 추가된 파일은 업로드
      const safeName = sanitizeFileName(f.name);
      const filePath = `attachments/${Date.now()}_${safeName}`;
      const { data, error } = await supabase.storage
        .from('notices')
        .upload(filePath, f);
      if (error) {
        alert('파일 업로드 실패: ' + error.message);
        return;
      }
      const url = data?.path
        ? supabase.storage.from('notices').getPublicUrl(data.path).data.publicUrl
        : null;
      fileUrls.push(url);
    }
  }

  const { error: updateError } = await supabase
    .from('notices')
    .update({
      title: title.value,
      content: content.value,
      is_pinned: isPinned.value,
      file_url: fileUrls
    })
    .eq('id', route.params.id);

  if (updateError) {
    alert('수정 실패: ' + updateError.message);
  } else {
    alert('수정되었습니다.');
    router.push('/admin/notices');
  }
};

function goList() {
  router.push('/admin/notices');
}
</script>

<style scoped>
.notice-create-view {
  max-width: 960px;
  margin: 1rem auto;
  padding: 2rem 2rem 2rem 2rem;
  background: #fff;
  border: 1px solid #ddd;
  border-radius: 4px;
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
.btn-row {
  display: flex;
  flex-direction: row;
  gap: 1rem;
  justify-content: flex-end;
}
.file-label {
  display: inline-block;
  background: #f8f8f8;
  color: #333;
  border-radius: 2px;
  cursor: pointer;
  font-size: 0.85rem;
  margin-bottom: 0;
  margin-right: 0;
  white-space: nowrap;
  border: 1px solid #ccc;
  padding: 4px 12px;
}
.file-row {
  display: flex;
  align-items: flex-start;
  justify-content: flex-start;
  gap: 16px;
  margin-top: 1rem;
  width: auto;
  margin-left: 0;
}
.file-list {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  margin-top: 0;
}
.file-item {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
  font-size: 1.0rem;
}
.file-remove {
  color: #e74c3c;
  cursor: pointer;
  font-size: 0.85em;
  margin-left: 4px;
}
.file-remove:hover {
  text-decoration: underline;
}
.file-link {
  color: #3498db;
  font-size: 1.0rem;
  text-decoration: none;
}
.file-link:hover {
  font-size: 1.0rem;
  text-decoration: underline;
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
</style>