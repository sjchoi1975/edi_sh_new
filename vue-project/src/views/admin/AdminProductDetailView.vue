<template>
  <div class="board_640">
    <div class="form-title">제품 상세</div>
    <div class="form-grid">
      <div class="form-group">
        <label>기준월</label>
        <input :value="product.base_month || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>제품명</label>
        <input :value="product.product_name || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>보험코드</label>
        <input :value="product.insurance_code || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>약가</label>
        <input :value="product.price || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>수수료율 A등급(%)</label>
        <input :value="product.commission_rate_a !== undefined && product.commission_rate_a !== null ? (product.commission_rate_a * 100).toFixed(1) : '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>수수료율 B등급(%)</label>
        <input :value="product.commission_rate_b !== undefined && product.commission_rate_b !== null ? (product.commission_rate_b * 100).toFixed(1) : '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>수수료율 C등급(%)</label>
        <input :value="product.commission_rate_c !== undefined && product.commission_rate_c !== null ? (product.commission_rate_c * 100).toFixed(1) : '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>표준코드</label>
        <input :value="product.standard_code || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>단위/포장형태</label>
        <input :value="product.unit_packaging_desc || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>단위수량</label>
        <input :value="product.unit_quantity || '-'" readonly disabled />
      </div>
      <div class="form-group">
        <label>상태</label>
        <input :value="product.status === 'active' ? '활성' : (product.status === 'inactive' ? '비활성' : '-')" readonly disabled />
      </div>
      <div class="form-group">
        <label>비고</label>
        <input :value="product.remarks || '-'" readonly disabled />
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
