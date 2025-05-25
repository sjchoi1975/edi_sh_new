<template>
  <div class="board_960">
    <div class="form-title">공지사항 등록</div>
    <form @submit.prevent="handleSubmit" class="notice-form grid-form" style="overflow-y:auto; max-height:70vh;">
      <div class="form-row">
        <div class="form-col col-3">
          <label>제목 <span class="required">*</span></label>
          <input v-model="title" type="text" required />
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>내용 <span class="required">*</span></label>
          <textarea v-model="content" required style="min-height:200px;"></textarea>
        </div>
      </div>
      <div class="form-row" style="justify-content: flex-start;">
        <div class="form-col" style="display: flex; align-items: center; width: auto; flex: none;">
          <span style="margin:0;">필수 공지 (상단 고정)</span>
          <input type="checkbox" v-model="isPinned" style="width:16px; height:16px; margin-left:8px;" />
        </div>
      </div>
      <div class="form-row file-row">
        <div class="form-col col-3">
          <label class="file-label" for="fileInput">파일 첨부</label>
          <input id="fileInput" type="file" multiple @change="onFileChange" ref="fileInput" style="display:none" />
          <div v-if="files.length" class="file-list">
            <div v-for="(f, idx) in files" :key="f.name + idx" class="file-item">
              <a :href="f.url || ''" class="file-link" :download="f.name">{{ f.name }}</a>
              <span class="file-remove" @click="removeFile(idx)">삭제</span>
            </div>
          </div>
        </div>
      </div>
      <div class="btn-row" style="justify-content: flex-end; margin-top: 1.2rem;">
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
const fileInput = ref(null);
const router = useRouter();

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
</script>