<template>
  <div class="board_960">
    <div class="form-title">정산월 상세</div>
    <div class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col col-2">
          <label>정산월</label>
          <span class="input-readonly">{{ settlementMonth.settlement_month }}</span>
        </div>
        <div class="form-col col-2">
          <label>상태</label>
          <span class="input-readonly">{{ settlementMonth.status === 'active' ? '활성' : '비활성' }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>실적입력 시작일</label>
          <span class="input-readonly">{{ settlementMonth.start_date }}</span>
        </div>
        <div class="form-col col-2">
          <label>실적입력 종료일</label>
          <span class="input-readonly">{{ settlementMonth.end_date }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>전달 사항</label>
          <span class="input-readonly">{{ settlementMonth.notice }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>비고</label>
          <span class="input-readonly">{{ settlementMonth.remarks }}</span>
        </div>
      </div>
      <div class="btn-row" style="justify-content: flex-end; margin-top: 1.2rem">
        <button class="btn-delete" type="button" @click="handleDelete">삭제</button>
        <button class="btn-edit" type="button" @click="goEdit">수정</button>
        <button class="btn-list" type="button" @click="goList">목록</button>
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
const settlementMonth = ref({});

onMounted(async () => {
  const { data, error } = await supabase
    .from('settlement_months')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    settlementMonth.value = data;
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