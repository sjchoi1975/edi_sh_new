<template>
  <div class="board_960">
    <div class="form-title">제품 상세</div>
    <div class="notice-form grid-form">
      <div class="form-row">
        <div class="form-col col-2">
          <label>기준월</label>
          <span class="input-readonly">{{ product.base_month }}</span>
        </div>
        <div class="form-col col-2">
          <label>제품명</label>
          <span class="input-readonly">{{ product.product_name }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>보험코드</label>
          <span class="input-readonly">{{ product.insurance_code }}</span>
        </div>
        <div class="form-col col-2">
          <label>약가</label>
          <span class="input-readonly">{{ product.price }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>수수료 등급 A(%)</label>
          <span class="input-readonly">{{ product.commission_rate_a }}</span>
        </div>
        <div class="form-col col-2">
          <label>수수료 등급 B(%)</label>
          <span class="input-readonly">{{ product.commission_rate_b }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>표준코드</label>
          <span class="input-readonly">{{ product.standard_code }}</span>
        </div>
        <div class="form-col col-2">
          <label>단위/포장형태</label>
          <span class="input-readonly">{{ product.unit_packaging_desc }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-2">
          <label>단위수량</label>
          <span class="input-readonly">{{ product.unit_quantity }}</span>
        </div>
        <div class="form-col col-2">
          <label>상태</label>
          <span class="input-readonly">{{ product.status === 'active' ? '활성' : '비활성' }}</span>
        </div>
      </div>
      <div class="form-row">
        <div class="form-col col-3">
          <label>비고</label>
          <span class="input-readonly">{{ product.remarks }}</span>
        </div>
      </div>
      <div class="btn-row" style="justify-content: flex-end; margin-top: 1.2rem; gap: 0.5rem;">
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
const product = ref({});

onMounted(async () => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .eq('id', route.params.id)
    .single();
  if (!error && data) {
    product.value = data;
  }
});

function goEdit() {
  router.push(`/admin/products/${route.params.id}/edit`);
}
function goList() {
  router.push('/admin/products');
}
async function handleDelete() {
  if (!confirm('정말 삭제하시겠습니까?')) return;
  const { error } = await supabase.from('products').delete().eq('id', route.params.id);
  if (!error) {
    alert('삭제되었습니다.');
    router.push('/admin/products');
  } else {
    alert('삭제 실패: ' + error.message);
  }
}
</script>
