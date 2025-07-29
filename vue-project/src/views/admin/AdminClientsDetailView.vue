<template>
  <div class="board_640">
    <div class="form-title">병의원 상세</div>
    <div class="form-grid">
      <div class="form-group">
        <label>병의원코드</label>
        <input :value="client.client_code || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>병의원명</label>
        <input :value="client.name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>사업자등록번호</label>
        <input :value="client.business_registration_number || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>원장명</label>
        <input :value="client.owner_name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>주소</label>
        <input :value="client.address || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>상태</label>
        <input :value="client.status === 'active' ? '활성' : (client.status === 'inactive' ? '비활성' : '-')" readonly disabled />
      </div>
      <div class="form-group">
        <label>비고</label>
        <input :value="client.remarks || '-'" readonly disabled />
      </div>
      <div class="button-area">
        <button class="btn-delete" @click="handleDelete">삭제</button>
        <button class="btn-edit" @click="goEdit">수정</button>
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
const client = ref({});

onMounted(async () => {
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    client.value = data;
  }
});

function goEdit() {
  // from 쿼리 파라미터가 있으면 함께 전달
  const from = route.query.from;
  if (from) {
    router.push(`/admin/clients/${route.params.id}/edit?from=${from}`);
  } else {
    router.push(`/admin/clients/${route.params.id}/edit`);
  }
}
function goList() {
  // 이전 화면이 관리자 실적 등록인지 확인
  if (route.query.from === 'admin-performance-register') {
    router.push('/admin/performance/register');
  } else if (route.query.from === 'admin-clients-assign-companies') {
    router.push('/admin/clients/assign-companies');
  } else if (route.query.from === 'admin-clients-commission-grades') {
    router.push('/admin/clients/commission-grades');
  } else if (route.query.from === 'admin-clients-assign-pharmacies') {
    router.push('/admin/clients/assign-pharmacies');
  } else {
    router.push('/admin/clients');
  }
}
async function handleDelete() {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const { error } = await supabase.from('clients').delete().eq('id', route.params.id);
  if (!error) {
    alert('삭제되었습니다.');
    router.push('/admin/clients');
  } else {
    alert('삭제 실패: ' + error.message);
  }
}
</script>