<template>
  <!-- No changes to template section -->
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSupabase } from '../composables/useSupabase'

const router = useRouter()
const supabase = useSupabase()

const route = computed(() => {
  // This is a placeholder for the route object
  // You might want to import it from vue-router
  return { params: { type: 'pending' } }
})

const breadcrumbSubMenu = computed(() => {
  if (route.params.type === 'pending') return '미승인 업체'
  return '승인 업체'
})

const handleStatusChange = async (company) => {
  if (!confirm('승인 상태를 변경하시겠습니까?')) return

  try {
    const { error } = await supabase
      .from('companies')
      .update({
        approval_status: company.approval_status === 'approved' ? 'pending' : 'approved',
        approved_at: company.approval_status === 'pending' ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', company.id)

    if (error) throw error

    alert('상태가 변경되었습니다.')
    fetchCompanies()
  } catch (err) {
    console.error('상태 변경 중 오류가 발생했습니다.', err)
    alert('상태 변경에 실패했습니다.')
  }
}

const handleDelete = async (company) => {
  if (!confirm('정말 삭제하시겠습니까?')) return

  try {
    const { error } = await supabase
      .from('companies')
      .delete()
      .eq('id', company.id)

    if (error) throw error

    alert('삭제되었습니다.')
    fetchCompanies()
  } catch (err) {
    console.error('삭제 중 오류가 발생했습니다.', err)
    alert('삭제에 실패했습니다.')
  }
}

const goToCreate = () => {
  router.push({
    path: '/admin/companies/create',
    query: { from: route.params.type }
  })
}

const goToEdit = (company) => {
  router.push({
    path: `/admin/companies/edit/${company.id}`,
    query: { from: route.params.type }
  })
}

const fetchCompanies = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('approval_status', route.params.type === 'pending' ? 'pending' : 'approved')
      .order('created_at', { ascending: false })

    if (error) throw error
    companies.value = data
  } catch (err) {
    console.error('업체 목록 조회 중 오류가 발생했습니다.', err)
    alert('업체 목록 조회에 실패했습니다.')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchCompanies()
})
</script>

<style>
  /* No changes to style section */
</style> 