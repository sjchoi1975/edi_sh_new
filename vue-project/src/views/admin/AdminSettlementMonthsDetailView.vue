<template>
  <div class="board_640">
    <div class="form-title">정산월 상세</div>
    <div class="form-grid-2x">
      <div class="form-group">
        <label>정산월</label>
        <input :value="month.settlement_month || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>실적입력 시작일</label>
        <input :value="month.start_date || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>실적입력 종료일</label>
        <input :value="month.end_date || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>전달 사항</label>
        <div class="input-readonly-detail" style="white-space: pre-wrap;">{{ month.notice || '-' }}</div>
      </div>
      <div class="form-group">
        <label>비고</label>
        <input :value="month.remarks || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>상태</label>
        <input :value="month.status === 'active' ? '활성' : (month.status === 'inactive' ? '비활성' : '-')" readonly disabled />
      </div>
      <div style="justify-content: flex-end; margin-top: 2rem;">
        <button class="btn-delete" @click="handleDelete" style="margin-right: 1rem;">삭제</button>
        <button class="btn-edit" @click="goEdit" style="margin-right: 1rem;">수정</button>
        <button class="btn-list" @click="goList">목록</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const route = useRoute();
const router = useRouter();
const month = ref({});

onMounted(async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    month.value = data;
  }
});

function goEdit() {
  router.push(`/admin/settlement-months/${route.params.id}/edit`);
}
function goList() {
  router.push('/admin/settlement-months');
}
async function handleDelete() {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const { error } = await supabase.from('settlement_months').delete().eq('id', route.params.id);
  if (!error) {
    alert('삭제되었습니다.');
    router.push('/admin/settlement-months');
  } else {
    alert('삭제 실패: ' + error.message);
  }
}
</script> 

