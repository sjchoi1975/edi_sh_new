<template>
    <div class="notice-create-view">
      <h2 style="margin-top:0;">공지사항 등록</h2>
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
            <textarea v-model="content" rows="20" required style="background:transparent; border:none; width:100%; font-size:1rem; resize:vertical;" />
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
          <button class="btn-primary" type="submit">등록</button>
        </div>
      </form>
    </div>
  </template>
  
  <script setup>
  import { ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { supabase } from '@/supabase';
  
  const title = ref('');
  const content = ref('');
  const isPinned = ref(false);
  const files = ref([]);
  const router = useRouter();
  const fileInput = ref(null);
  
  function sanitizeFileName(name) {
    return name.replace(/[^a-zA-Z0-9._-]/g, '_');
  }

  function onFileChange(e) {
    const selected = Array.from(e.target.files);
    files.value = files.value.concat(selected).slice(0, 10);
    e.target.value = '';
  }

  function removeFile(idx) {
    files.value.splice(idx, 1);
  }

  const handleSubmit = async () => {
    if (!title.value.trim() || !content.value.trim()) {
      alert('제목과 내용을 입력하세요.');
      return;
    }

    let fileUrls = [];
    for (const f of files.value) {
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

    const { error: insertError } = await supabase.from('notices').insert([
      {
        title: title.value,
        content: content.value,
        is_pinned: isPinned.value,
        view_count: 0,
        file_url: fileUrls
      }
    ]);
    if (insertError) {
      alert('등록 실패: ' + insertError.message);
    } else {
      alert('등록되었습니다.');
      router.push('/admin/notices');
    }
  };
  
  function goList() {
    router.push('/admin/notices');
  }

  function goCreate() {
    router.push('/admin/notices/create');
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
    font-size: 1.0rem;
    font-weight: 600;
  }
  input[type='text'],
  textarea {
    width: 100%;
    padding: 8px 12px;
    font-size: 1rem;
    border: 1px solid #ddd;
    border-radius: 4px;
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
  input[type='file'] {
    display: none;
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
    font-size: 0.85rem;
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