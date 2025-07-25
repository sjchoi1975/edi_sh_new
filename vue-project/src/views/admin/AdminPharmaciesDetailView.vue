<template>
  <div class="board_640">
    <div class="form-title">문전약국 상세</div>
    <div class="form-grid">
      <div class="form-group">
        <label>약국코드</label>
        <input class="input-readonly-detail" :value="pharmacy.pharmacy_code || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>약국명</label>
        <input class="input-readonly-detail" :value="pharmacy.name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>사업자등록번호</label>
        <input class="input-readonly-detail" :value="pharmacy.business_registration_number || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>주소</label>
        <input class="input-readonly-detail" :value="pharmacy.address || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>상태</label>
        <input class="input-readonly-detail" :value="pharmacy.status === 'active' ? '활성' : (pharmacy.status === 'inactive' ? '비활성' : '-')" readonly disabled />
      </div>
      <div class="form-group">
        <label>비고</label>
        <input class="input-readonly-detail" :value="pharmacy.remarks || '-'" readonly disabled />
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
const pharmacy = ref({});

onMounted(async () => {
  const { data, error } = await supabase
    .from('pharmacies')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    pharmacy.value = data;
  }
});

function goEdit() {
  router.push(`/admin/pharmacies/${route.params.id}/edit`);
}
function goList() {
  router.push('/admin/pharmacies');
}
async function handleDelete() {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const { error } = await supabase.from('pharmacies').delete().eq('id', route.params.id);
  if (!error) {
    alert('삭제되었습니다.');
    router.push('/admin/pharmacies');
  } else {
    alert('삭제 실패: ' + error.message);
  }
}
</script>
