<template>
  <div class="board_960">
    <div class="form-title">업체 상세 정보</div>

    <div class="form-row">
      <div class="form-col">
        <label>아이디(이메일)</label>
        <span class="input-readonly">{{ email }}</span>
      </div>
      <div class="form-col"></div>
      <div class="form-col"></div>
    </div>
    <div class="form-row">
      <div class="form-col">
        <label>업체명</label>
        <span class="input-readonly">{{ companyName }}</span>
      </div>
      <div class="form-col">
        <label>사업자등록번호</label>
        <span class="input-readonly">{{ businessNumber }}</span>
      </div>
      <div class="form-col">
        <label>대표자</label>
        <span class="input-readonly">{{ representative }}</span>
      </div>
    </div>
    <div class="form-row">
      <div class="form-col col-2 align-right">
        <label>사업장 소재지</label>
        <span class="input-readonly">{{ address }}</span>
      </div>
      <div class="form-col align-left">
        <label>유선전화</label>
        <span class="input-readonly">{{ landline }}</span>
      </div>
    </div>
    <div class="form-row">
      <div class="form-col">
        <label>담당자</label>
        <span class="input-readonly">{{ contactPerson }}</span>
      </div>
      <div class="form-col">
        <label>휴대폰 번호</label>
        <span class="input-readonly">{{ mobile }}</span>
      </div>
      <div class="form-col">
        <label>휴대폰 번호 2</label>
        <span class="input-readonly">{{ mobile2 }}</span>
      </div>
    </div>
    <div class="form-row">
      <div class="form-col">
        <label>수신용 이메일</label>
        <span class="input-readonly">{{ receiveEmail }}</span>
      </div>
      <div class="form-col">
        <label>구분</label>
        <span class="input-readonly">{{ companyGroup }}</span>
      </div>
      <div class="form-col">
        <label>수수료 등급</label>
        <span class="input-readonly">{{ commissionGrade }}</span>
      </div>
    </div>
    <div class="form-row">
      <div class="form-col">
        <label>관리자</label>
        <span class="input-readonly">{{ manager }}</span>
      </div>
      <div class="form-col">
        <label>승인여부</label>
        <span class="input-readonly">
          {{ approvalStatus === 'approved' ? '승인' : '미승인' }}
        </span>
      </div>
      <div class="form-col"></div>
    </div>
    <div class="form-row">
      <div class="form-col col-3">
        <label>비고</label>
        <span class="input-readonly">{{ remarks }}</span>
      </div>
    </div>
    <div class="btn-row" style="justify-content: flex-end; margin-top: 2rem">
      <button class="btn-reset-password" @click="resetPassword">비밀번호 초기화</button>
      <button class="btn-edit" @click="goEdit">수정</button>
      <button class="btn-list" type="button" @click="goList">목록</button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/supabase'

const route = useRoute()
const router = useRouter()

const email = ref('')
const companyName = ref('')
const businessNumber = ref('')
const representative = ref('')
const address = ref('')
const landline = ref('')
const contactPerson = ref('')
const mobile = ref('')
const mobile2 = ref('')
const receiveEmail = ref('')
const companyGroup = ref('')
const commissionGrade = ref('')
const manager = ref('')
const remarks = ref('')
const approvalStatus = ref('')

onMounted(async () => {
  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('id', route.params.id)
    .single()
  if (!error && data) {
    email.value = data.email || ''
    companyName.value = data.company_name || ''
    businessNumber.value = data.business_registration_number || ''
    representative.value = data.representative_name || ''
    address.value = data.business_address || ''
    landline.value = data.landline_phone || ''
    contactPerson.value = data.contact_person_name || ''
    mobile.value = data.mobile_phone || ''
    mobile2.value = data.mobile_phone_2 || ''
    receiveEmail.value = data.receive_email || ''
    companyGroup.value = data.company_group || ''
    commissionGrade.value = data.default_commission_grade || ''
    manager.value = data.assigned_pharmacist_contact || ''
    remarks.value = data.remarks || ''
    approvalStatus.value = data.approval_status || ''
  }
})

function goList() {
  const from = route.query.from === 'pending' ? 'pending' : 'approved'
  router.push(`/admin/companies/${from}`)
}

function goEdit() {
  const from = route.query.from === 'pending' ? 'pending' : 'approved'
  router.push(`/admin/companies/${route.params.id}/edit?from=${from}`)
}

async function resetPassword() {
  const { error } = await supabase.auth.admin.updateUserById(email.value, { password: 'asdf1234' })
  if (error) {
    alert('비밀번호 초기화 실패: ' + error.message)
  } else {
    alert('비밀번호가 asdf1234로 초기화되었습니다.')
  }
}
</script>
