<template>
  <div class="board_960">
    <div class="form-title">문전약국 상세</div>
    <div class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col col-2">
          <label>약국코드</label>
          <span class="input-readonly">{{ pharmacy.pharmacy_code }}</span>
        </div>
        <div class="form-col col-2">
          <label>약국명</label>
          <span class="input-readonly">{{ pharmacy.name }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>사업자등록번호</label>
          <span class="input-readonly">{{ pharmacy.business_registration_number }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>주소</label>
          <span class="input-readonly">{{ pharmacy.address }}</span>
        </div>
        <div class="form-col col-2">
          <label>상태</label>
          <span class="input-readonly">{{ pharmacy.status === 'active' ? '활성' : '비활성' }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>비고</label>
          <span class="input-readonly">{{ pharmacy.remarks }}</span>
        </div>
      </div>
      <div class="btn-row">
        <button class="btn-danger" @click="handleDelete">삭제</button>
        <button class="btn-primary" @click="goEdit">수정</button>
        <button class="btn-cancel" @click="goList">목록</button>
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

const fetchPharmacy = async () => {
  const { data, error } = await supabase
    .from('pharmacies')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    pharmacy.value = data;
  }
};

onMounted(() => {
  fetchPharmacy();
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
  if (error) {
    alert('삭제 실패: ' + error.message);
  } else {
    alert('삭제되었습니다.');
    router.push('/admin/pharmacies');
  }
}
</script>
