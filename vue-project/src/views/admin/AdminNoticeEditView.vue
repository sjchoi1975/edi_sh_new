<template>
    <div class="notice-edit-view">
      <h2>공지사항 수정</h2>
      <form @submit.prevent="handleUpdate">
        <div class="form-row">
          <label>제목</label>
          <input v-model="form.title" required />
        </div>
        <div class="form-row">
          <label>내용</label>
          <textarea v-model="form.content" rows="8" required />
        </div>
        <div class="form-row">
          <label>
            <input type="checkbox" v-model="form.is_pinned" />
            상단 고정
          </label>
        </div>
        <div class="form-row" v-if="fileList && fileList.length">
          <label>첨부파일</label>
          <div v-for="(file, idx) in fileList" :key="idx" style="margin-bottom:4px;">
            <a :href="file" :download="getFileName(file)">
              {{ getFileName(file) }}
            </a>
            <button type="button" @click="removeFile(idx)">X</button>
          </div>
        </div>
        <input type="file" multiple @change="onFileChange" />
        <div class="btn-row">
          <button type="submit">저장</button>
          <button type="button" @click="goBack">취소</button>
          <button type="button" @click="handleDelete">삭제</button>
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
  const form = ref({
    title: '',
    content: '',
    is_pinned: false,
  });
  
  const fileList = ref([]);
  const newFiles = ref([]);
  
  onMounted(async () => {
    const { data } = await supabase
      .from('notices')
      .select('*')
      .eq('id', route.params.id)
      .single();
    if (data) {
      form.value = {
        title: data.title,
        content: data.content,
        is_pinned: !!data.is_pinned,
      };
      if (data.file_url) {
        if (Array.isArray(data.file_url)) {
          fileList.value = [...data.file_url];
        } else if (typeof data.file_url === 'string') {
          fileList.value = [data.file_url];
        }
      }
    }
  });
  
  async function handleUpdate() {
    let uploadedUrls = [];
    for (const f of newFiles.value) {
      const safeName = f.name.replace(/[^a-zA-Z0-9._-]/g, '_');
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
      if (url) uploadedUrls.push(url);
    }

    const finalFileList = [
      ...fileList.value.filter(f => typeof f === 'string' && f.startsWith('http')),
      ...uploadedUrls
    ];

    const { error } = await supabase
      .from('notices')
      .update({
        title: form.value.title,
        content: form.value.content,
        is_pinned: form.value.is_pinned,
        updated_at: new Date().toISOString(),
        file_url: finalFileList
      })
      .eq('id', route.params.id);

    if (error) {
      alert('수정 실패: ' + error.message);
    } else {
      alert('수정되었습니다.');
      router.push(`/notices/${route.params.id}`);
    }
  }
  
  function goBack() {
    router.back();
  }
  
  async function handleDelete() {
    if (!confirm('정말 삭제하시겠습니까?')) return;
    const { error } = await supabase.from('notices').delete().eq('id', route.params.id);
    if (error) {
      alert('삭제 실패: ' + error.message);
    } else {
      alert('삭제되었습니다.');
      router.push('/admin/notices');
    }
  }

  function getFileName(url) {
    try {
      const name = decodeURIComponent(url.split('/').pop().split('?')[0]);
      // 타임스탬프_원본명 패턴이면 _ 뒤만 보여주기
      const parts = name.split('_');
      if (parts.length > 1 && /^\d{10,}$/.test(parts[0])) {
        return parts.slice(1).join('_');
      }
      return name;
    } catch {
      return '첨부파일';
    }
  }

  function removeFile(idx) {
    fileList.value.splice(idx, 1);
  }

  function onFileChange(e) {
    const files = Array.from(e.target.files);
    newFiles.value.push(...files);
  }
  </script>
  
  <style scoped>
  .notice-edit-view {
    max-width: 700px;
    margin: 0 auto;
    padding: 2rem 1rem;
  }
  .form-row {
    margin-bottom: 1rem;
  }
  .btn-row {
    margin-top: 1.5rem;
    display: flex;
    gap: 1rem;
  }
  </style>