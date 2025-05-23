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
            상단 고정 (필수 공지)
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
              <span class="file-link">{{ f.name }}</span>
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