<template>
  <div class="admin-products-view">
    <div class="header-title">제품 목록</div>
    <div class="table-container">
      <div class="table-header">
        <span style="display:flex;align-items:center;gap:8px;">
          <label>기준월</label>
          <Calendar
            v-model="selectedMonth"
            view="month"
            dateFormat="yy-mm"
            showIcon
            placeholder="YYYY-MM"
            inputClass="p-datepicker"
            :locale="koLocale"
          />
        </span>
        <span class="p-input-icon-left">
          <InputText
                v-model="filters['global'].value"
                placeholder="제품명, 보험코드 검색"
                class="search-input"
              />
        </span>
      </div>
      <DataTable
        :value="filteredProducts"
        paginator
        :rows="20"
        :rowsPerPageOptions="[20, 50, 100]"
        scrollable
        scrollHeight="680px"
        v-model:filters="filters"
        :globalFilterFields="['base_month', 'product_name', 'insurance_code']"
        class="custom-table"
      >
        <template #empty>
          등록된 제품이 없습니다.
        </template>
        <template #loading>
          제품 목록을 불러오는 중입니다...
        </template>
        <Column field="product_name" header="제품명" :headerStyle="{ width: '18%' }" :sortable="true">
          <template #body="slotProps">
            <a
              href="#"
              style="color:#1976d2;text-decoration:underline;cursor:pointer;"
              @click.prevent="goToDetail(slotProps.data.id)"
            >
              {{ slotProps.data.product_name }}
            </a>
          </template>
        </Column>
        <Column field="insurance_code" header="보험코드" :headerStyle="{ width: '14%' }" :sortable="true" />
        <Column field="price" header="약가" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="commission_rate_a" header="수수료A(%)" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="commission_rate_b" header="수수료B(%)" :headerStyle="{ width: '8%' }" :sortable="true" />
        <Column field="standard_code" header="표준코드" :headerStyle="{ width: '12%' }"   :sortable="true" />
        <Column field="unit_packaging_desc" header="단위/포장형태" :headerStyle="{ width: '10%' }" :sortable="true" />
        <Column field="unit_quantity" header="단위수량" :headerStyle="{ width: '10%' }" :sortabl e="true" :sortable="true" />
        <Column field="remarks" header="비고" :headerStyle="{ width: '12%' }" :sortable="true" />
      </DataTable>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Calendar from 'primevue/calendar';
import { useRouter } from 'vue-router';
import { supabase } from '@/supabase';

const products = ref([]);
const filters = ref({ 'global': { value: null, matchMode: 'contains' } });
const selectedMonth = ref(new Date()); // Date 객체로 관리
const router = useRouter();

const koLocale = {
  firstDayOfWeek: 0,
  dayNames: ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'],
  dayNamesShort: ['일', '월', '화', '수', '목', '금', '토'],
  dayNamesMin: ['일', '월', '화', '수', '목', '금', '토'],
  monthNames: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  monthNamesShort: ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'],
  today: '오늘',
  clear: '초기화'
}

const filteredProducts = computed(() => {
  if (!selectedMonth.value) return products.value;
  const year = selectedMonth.value.getFullYear();
  const month = String(selectedMonth.value.getMonth() + 1).padStart(2, '0');
  const ym = `${year}-${month}`;
  return products.value.filter(p => p.base_month === ym);
});

function goToDetail(id) {
  router.push(`/products/${id}`);
}

const fetchProducts = async () => {
  const { data, error } = await supabase
    .from('products')
    .select('*')
    .order('base_month', { ascending: false })
    .order('product_name', { ascending: true });
  if (!error && data) {
    products.value = data;
  }
};

onMounted(() => {
  fetchProducts();
});
</script> 