<template>
    <div class="board_960">
      <div class="form-title">거래처 상세</div>
      <div class="notice-form grid-form">
        <div class="form-row">
          <div class="form-col col-2">
            <label>거래처코드</label>
            <span class="input-readonly">{{ client.client_code }}</span>
          </div>
          <div class="form-col col-2">
            <label>병의원명</label>
            <span class="input-readonly">{{ client.name }}</span>
          </div>
        </div>
        <div class="form-row">
          <div class="form-col col-2">
            <label>사업자등록번호</label>
            <span class="input-readonly">{{ client.business_registration_number }}</span>
          </div>
          <div class="form-col col-2">
            <label>원장명</label>
            <span class="input-readonly">{{ client.owner_name }}</span>
          </div>
        </div>
        <div class="form-row">
          <div class="form-col col-2">
            <label>주소</label>
            <span class="input-readonly">{{ client.address }}</span>
          </div>
          <div class="form-col col-2">
            <label>상태</label>
            <span class="input-readonly">{{ client.status === 'active' ? '활성' : '비활성' }}</span>
          </div>
        </div>
        <div class="form-row">
          <div class="form-col col-3">
            <label>비고</label>
            <span class="input-readonly">{{ client.remarks }}</span>
          </div>
        </div>
        <div class="btn-row" style="justify-content: flex-end; margin-top: 1.2rem">
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
    router.push('/clients');
  }
  </script>