<template>
  <div class="company-detail-view">
    <h2 style="margin-top:0;">업체 상세/수정</h2>
    <form @submit.prevent="handleSubmit" class="company-form">
      <div class="form-row">
        <label>아이디(이메일)</label>
        <input v-model="email" type="email" disabled />
      </div>
      <div class="form-row">
        <label>업체명</label>
        <input v-model="companyName" type="text" />
      </div>
      <div class="form-row">
        <label>사업자등록번호</label>
        <input v-model="businessNumber" type="text" />
      </div>
      <div class="form-row">
        <label>대표자</label>
        <input v-model="representative" type="text" />
      </div>
      <div class="form-row">
        <label>사업장 소재지</label>
        <input v-model="address" type="text" />
      </div>
      <div class="form-row">
        <label>유선전화</label>
        <input v-model="landline" type="text" />
      </div>
      <div class="form-row">
        <label>담당자</label>
        <input v-model="contactPerson" type="text" />
      </div>
      <div class="form-row">
        <label>휴대폰 번호</label>
        <input v-model="mobile" type="text" />
      </div>
      <div class="form-row">
        <label>휴대폰 번호 2</label>
        <input v-model="mobile2" type="text" />
      </div>
      <div class="form-row">
        <label>이메일 수신</label>
        <input v-model="receiveEmail" type="email" />
      </div>
      <div class="form-row">
        <label>구분</label>
        <input v-model="companyGroup" type="text" />
      </div>
      <div class="form-row">
        <label>수수료 등급</label>
        <input v-model="commissionGrade" type="text" />
      </div>
      <div class="form-row">
        <label>관리자</label>
        <input v-model="manager" type="text" />
      </div>
      <div class="form-row">
        <label>비고</label>
        <textarea v-model="remarks" rows="2" />
      </div>
      <div class="form-row">
        <label>승인여부</label>
        <input v-model="approvalStatus" type="text" />
      </div>
      <div class="btn-row" style="justify-content: flex-end;">
        <button class="btn-cancel" type="button" @click="goList">목록</button>
        <button class="btn-primary" type="submit">저장</button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const email = ref('');
const companyName = ref('');
const businessNumber = ref('');
const representative = ref('');
const address = ref('');
const landline = ref('');
const contactPerson = ref('');
const mobile = ref('');
const mobile2 = ref('');
const receiveEmail = ref('');
const companyGroup = ref('');
const commissionGrade = ref('');
const manager = ref('');
const remarks = ref('');
const approvalStatus = ref('');
const router = useRouter();

function goList() {
  router.push('/admin/companies');
}

const handleSubmit = async () => {
  // 저장 로직 구현 (기존과 동일하게)
  alert('저장되었습니다.');
  router.push('/admin/companies');
};
</script> 