<template>
  <div class="board_640">
    <div class="form-title">병의원 상세</div>
    <form class="form-grid">
      <div class="form-group">
        <label>병의원코드</label>
        <input class="input-readonly-detail" :value="client.client_code || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>병의원명</label>
        <input class="input-readonly-detail" :value="client.name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>사업자등록번호</label>
        <input class="input-readonly-detail" :value="client.business_registration_number || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>원장명</label>
        <input class="input-readonly-detail" :value="client.owner_name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>주소</label>
        <input class="input-readonly-detail" :value="client.address || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>상태</label>
        <input class="input-readonly-detail" :value="client.status === 'active' ? '활성' : (client.status === 'inactive' ? '비활성' : '-')" readonly disabled />
      </div>
      <div class="form-group">
        <label>비고</label>
        <input class="input-readonly-detail" :value="client.remarks || '-'" readonly disabled />
      </div>
      <div style="justify-content: flex-end; margin-top: 2rem;">
        <button class="btn-list" type="button" @click="goList">목록</button>
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

function goList() {
  // 이전 화면이 실적 등록인지 확인
  if (route.query.from === 'performance-register') {
    router.push('/performance/register');
  } else {
    router.push('/clients');
  }
}
</script>