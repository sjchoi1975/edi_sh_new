<template>
  <div class="performance-register-view">
    <div class="header-title">증빙 파일 제출</div>
    <div class="table-container" style="position:relative;">
      <!-- 상단 정보 영역 -->
      <div class="performance-header-row">
        <!-- 정산월 선택 드롭다운 -->
        <div class="info-box info-box-settlement">
          <span class="info-box-label">정산월</span>
          <select v-model="selectedSettlementMonth" class="prescription-select">
            <option value="">- 선택 -</option>
            <option v-for="month in availableMonths" :key="month.settlement_month" :value="month.settlement_month">
              {{ month.settlement_month }}
            </option>
          </select>
        </div>
        
        <!-- 실적 입력기간 표시 -->
        <div class="info-box info-box-period">
          <span class="info-box-label">제출기간</span>
          <span class="info-box-content">{{ inputPeriod }}</span>
        </div>
      </div>
      
      <!-- 테이블 -->
      <table class="input-table" v-if="selectedSettlementMonth">
        <thead>
          <tr>
            <th style="width:8%;">거래처코드</th>
            <th style="width:15%;">병의원명</th>
            <th style="width:12%;">사업자등록번호</th>
            <th style="width:8%;">원장명</th>
            <th style="width:20%;">주소</th>
            <th style="width:6%;">실적건수</th>
            <th style="width:8%;">처방액</th>
            <th style="width:6%;">제출여부</th>
            <th style="width:6%;">증빙파일</th>
            <th style="width:6%;">상세</th>
            <th style="width:5%;">제출</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="clientList.length === 0">
            <td colspan="11" style="text-align:center;padding:2rem;color:#666;">
              <div v-if="!selectedSettlementMonth" style="margin-bottom:1rem;">
                정산월을 선택하세요.
              </div>
              <div v-else style="margin-bottom:1rem;">
                해당 정산월에 실적이 등록된 거래처가 없습니다.
              </div>
            </td>
          </tr>
          <tr v-for="(client, index) in clientList" :key="client.id" v-else>
            <!-- 거래처코드 -->
            <td style="text-align:center;">{{ client.client_code }}</td>
            
            <!-- 병의원명 -->
            <td style="text-align:left;">{{ client.name }}</td>
            
            <!-- 사업자등록번호 -->
            <td style="text-align:center;">{{ client.business_registration_number }}</td>
            
            <!-- 원장명 -->
            <td style="text-align:center;">{{ client.owner_name }}</td>
            
            <!-- 주소 -->
            <td style="text-align:left;">{{ truncateText(client.address, 30) }}</td>
            
            <!-- 실적건수 -->
            <td style="text-align:center;">{{ client.performance_count || 0 }}</td>
            
            <!-- 처방액 -->
            <td style="text-align:right;">{{ formatCurrency(client.total_prescription_amount) }}</td>
            
            <!-- 제출여부 -->
            <td style="text-align:center;">
              <span :class="client.evidence_files_count > 0 ? 'active-badge' : 'inactive-badge'">
                {{ client.evidence_files_count > 0 ? '제출' : '미제출' }}
              </span>
            </td>
            
            <!-- 증빙파일 -->
            <td style="text-align:center;">
              {{ client.evidence_files_count > 0 ? client.evidence_files_count : '-' }}
            </td>
            
            <!-- 상세 -->
            <td style="text-align:center;">
              <button 
                v-if="client.evidence_files_count > 0"
                class="btn-secondary btn-sm"
                @click="openDetailModal(client)"
                title="증빙파일 상세보기"
              >
                상세
              </button>
              <span v-else style="color: #ccc;">-</span>
            </td>
            
            <!-- 제출 -->
            <td style="text-align:center;">
              <button 
                class="btn-primary btn-sm"
                @click="openUploadModal(client)"
                :disabled="!isInputPeriod"
                title="증빙파일 업로드"
              >
                제출
              </button>
            </td>
          </tr>
        </tbody>
      </table>
      
      <!-- 정산월 미선택 안내 -->
      <div v-if="!selectedSettlementMonth" style="position:absolute;top:0;left:0;width:100%;height:100%;display:flex;align-items:center;justify-content:center;z-index:10;background:rgba(255,255,255,0);">
        <div style="font-size:1.3rem;color:#666;text-align:center;">정산월을 선택하세요.</div>
      </div>
    </div>
  </div>

  <!-- 파일 업로드 모달 -->
  <div v-if="uploadModalVisible" class="modal-overlay" @click="closeUploadModal">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>증빙 파일 업로드 - {{ selectedClient?.name }}</h3>
        <button @click="closeUploadModal" class="modal-close">×</button>
      </div>
      <div class="modal-body">
        <div style="margin-bottom: 1rem;">
          <label style="display: block; margin-bottom: 0.5rem;">파일 선택 (최대 5개)</label>
          <input 
            ref="fileInput"
            type="file" 
            multiple 
            accept=".pdf,.jpg,.jpeg,.png,.doc,.docx,.xls,.xlsx"
            @change="handleFileSelect"
            style="width: 100%;"
          />
          <div style="font-size: 0.9rem; color: #666; margin-top: 0.5rem;">
            허용 파일: PDF, 이미지(JPG, PNG), 문서(DOC, DOCX, XLS, XLSX)
          </div>
        </div>
        
        <div v-if="selectedFiles.length > 0" style="margin-bottom: 1rem;">
          <label style="display: block; margin-bottom: 0.5rem;">선택된 파일</label>
          <div v-for="(file, index) in selectedFiles" :key="index" style="display: flex; justify-content: space-between; align-items: center; padding: 0.5rem; border: 1px solid #ddd; margin-bottom: 0.25rem;">
            <span>{{ file.name }}</span>
            <button @click="removeFile(index)" style="color: red; border: none; background: none; cursor: pointer;">×</button>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn-cancel" @click="closeUploadModal">취소</button>
        <button class="btn-primary" @click="uploadFiles" :disabled="selectedFiles.length === 0 || uploading">
          {{ uploading ? '업로드 중...' : '업로드' }}
        </button>
      </div>
    </div>
  </div>

  <!-- 상세보기 모달 -->
  <div v-if="detailModalVisible" class="modal-overlay" @click="closeDetailModal">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>{{ truncateText(selectedClient?.name || '', 20) }}</h3>
        <button @click="closeDetailModal" class="modal-close">×</button>
      </div>
      <div class="modal-body">
        <div v-if="clientFiles.length === 0" style="text-align: center; color: #666; padding: 2rem;">
          등록된 파일이 없습니다.
        </div>
        <div v-else>
          <div v-for="(file, index) in clientFiles" :key="file.id" style="display: flex; justify-content: space-between; align-items: center; padding: 0.75rem; border: 1px solid #ddd; margin-bottom: 0.5rem;">
            <div style="flex: 1;">
              <a @click="downloadFile(file)" style="color: #1976d2; cursor: pointer; text-decoration: underline;">
                {{ file.file_name }}
              </a>
              <div style="font-size: 0.85rem; color: #666;">
                업로드: {{ formatDate(file.uploaded_at) }}
              </div>
            </div>
            <button 
              @click="deleteFile(file, index)" 
              style="color: red; border: none; background: none; cursor: pointer; margin-left: 1rem;"
              title="파일 삭제"
              :disabled="!isInputPeriod"
            >
              삭제
            </button>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn-secondary" @click="downloadAllFiles" :disabled="clientFiles.length === 0">
          전체 다운로드
        </button>
        <button class="btn-cancel" @click="closeDetailModal">닫기</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/supabase'

// 반응형 데이터
const availableMonths = ref([])
const selectedSettlementMonth = ref('')
const selectedMonthInfo = ref(null)
const clientList = ref([])
const currentUserId = ref(null)
const currentCompanyId = ref(null)

// 모달 관련
const uploadModalVisible = ref(false)
const detailModalVisible = ref(false)
const selectedClient = ref(null)
const selectedFiles = ref([])
const uploading = ref(false)
const clientFiles = ref([])

// 파일 input ref
const fileInput = ref(null)

// 실적 입력기간 계산
const inputPeriod = computed(() => {
  if (!selectedMonthInfo.value) return ''
  const start = selectedMonthInfo.value.start_date
  const end = selectedMonthInfo.value.end_date
  return start && end ? `${start} ~ ${end}` : ''
})

// 현재가 입력 가능 기간인지 확인
const isInputPeriod = computed(() => {
  if (!selectedMonthInfo.value) return false
  const now = new Date()
  const start = new Date(selectedMonthInfo.value.start_date)
  const end = new Date(selectedMonthInfo.value.end_date)
  return now >= start && now <= end
})

// 워치어
watch(selectedSettlementMonth, async (newValue) => {
  if (newValue) {
    // 선택된 정산월 정보 업데이트
    selectedMonthInfo.value = availableMonths.value.find(m => m.settlement_month === newValue)
    // 거래처 목록 조회
    await fetchClientList()
  } else {
    selectedMonthInfo.value = null
    clientList.value = []
  }
})

// 라이프사이클
onMounted(async () => {
  // 1. 사용자 정보 먼저 로드
  await getCurrentUser()
  console.log('사용자 정보 로드 완료:', { currentUserId: currentUserId.value, companyId: currentCompanyId.value })
  
  // 2. 기본 데이터들 로드
  await fetchAvailableMonths()
  console.log('정산월 데이터 로드 완료:', availableMonths.value)
  
  // 3. 기본 정산월 설정 (가장 최근 월로)
  if (availableMonths.value.length > 0) {
    selectedSettlementMonth.value = availableMonths.value[0].settlement_month
    console.log('기본 정산월 설정:', selectedSettlementMonth.value)
  }
})

// 유틸리티 함수들
function truncateText(text, maxLength) {
  if (!text) return ''
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text
}

function formatCurrency(amount) {
  if (!amount) return '-'
  return Number(amount).toLocaleString()
}

function formatDate(dateString) {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('ko-KR')
}

// 데이터 fetch 함수들
async function getCurrentUser() {
  try {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session?.user) return
    
    currentUserId.value = session.user.id
    
    // 사용자의 회사 정보 조회
    const { data: company } = await supabase
      .from('companies')
      .select('id')
      .eq('user_id', session.user.id)
      .single()
      
    if (company) {
      currentCompanyId.value = company.id
    }
  } catch (err) {
    console.error('사용자 정보 조회 오류:', err)
  }
}

async function fetchAvailableMonths() {
  try {
    const { data, error } = await supabase
      .from('settlement_months')
      .select('*')
      .eq('status', 'active')
      .order('settlement_month', { ascending: false })
      
    if (error) {
      console.error('정산월 조회 오류:', error)
      return
    }
    
    availableMonths.value = data || []
  } catch (err) {
    console.error('정산월 조회 예외:', err)
  }
}

async function fetchClientList() {
  if (!selectedSettlementMonth.value || !currentCompanyId.value) return
  
  try {
    // 해당 정산월에 실적을 등록한 거래처들 조회
    const { data: performanceData, error: performanceError } = await supabase
      .from('performance_records')
      .select(`
        client_id,
        clients!inner(
          id,
          client_code,
          name,
          business_registration_number,
          owner_name,
          address
        ),
        prescription_qty,
        products!inner(price)
      `)
      .eq('company_id', currentCompanyId.value)
      .eq('settlement_month', selectedSettlementMonth.value)
      
    if (performanceError) {
      console.error('실적 데이터 조회 오류:', performanceError)
      return
    }
    
    // 거래처별로 실적 데이터 집계
    const clientMap = new Map()
    
    performanceData?.forEach(record => {
      const clientId = record.client_id
      const client = record.clients
      
      if (!clientMap.has(clientId)) {
        clientMap.set(clientId, {
          ...client,
          performance_count: 0,
          total_prescription_amount: 0,
          evidence_files_count: 0
        })
      }
      
      const clientData = clientMap.get(clientId)
      clientData.performance_count += 1
      clientData.total_prescription_amount += (record.prescription_qty * record.products.price)
    })
    
    // 증빙파일 개수 조회
    for (const [clientId, clientData] of clientMap.entries()) {
      try {
        const { count } = await supabase
          .from('performance_evidence_files')
          .select('*', { count: 'exact', head: true })
          .eq('company_id', currentCompanyId.value)
          .eq('client_id', clientId)
          .eq('settlement_month', selectedSettlementMonth.value)
          
        clientData.evidence_files_count = count || 0
      } catch (err) {
        console.error(`증빙파일 개수 조회 오류 (client: ${clientId}):`, err)
        clientData.evidence_files_count = 0
      }
    }
    
    clientList.value = Array.from(clientMap.values())
    
  } catch (err) {
    console.error('거래처 목록 조회 예외:', err)
    clientList.value = []
  }
}

// 모달 관련 함수들
function openUploadModal(client) {
  selectedClient.value = client
  selectedFiles.value = []
  uploadModalVisible.value = true
}

function closeUploadModal() {
  uploadModalVisible.value = false
  selectedClient.value = null
  selectedFiles.value = []
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

function openDetailModal(client) {
  selectedClient.value = client
  detailModalVisible.value = true
  fetchClientFiles(client.id)
}

function closeDetailModal() {
  detailModalVisible.value = false
  selectedClient.value = null
  clientFiles.value = []
}

// 파일 처리 함수들
function handleFileSelect(event) {
  const files = Array.from(event.target.files)
  if (files.length > 5) {
    alert('최대 5개의 파일만 선택할 수 있습니다.')
    return
  }
  selectedFiles.value = files
}

function removeFile(index) {
  selectedFiles.value.splice(index, 1)
}

async function uploadFiles() {
  if (selectedFiles.value.length === 0) return
  if (!selectedClient.value || !currentCompanyId.value) return
  
  uploading.value = true
  
  try {
    for (const file of selectedFiles.value) {
      // 파일명 정리 (한글, 특수문자 제거)
      const cleanFileName = file.name.replace(/[^a-zA-Z0-9.-]/g, '_')
      const timestamp = Date.now()
      const randomId = Math.random().toString(36).substring(2, 8)
      const fileName = `${timestamp}_${randomId}_${cleanFileName}`
      
      // 간단한 파일 경로 사용
      const filePath = `private/${fileName}`
      
      console.log('업로드 시도:', filePath)
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('performance-evidence')
        .upload(filePath, file)
        
      if (uploadError) {
        console.error('파일 업로드 오류:', uploadError)
        alert(`파일 업로드 실패: ${file.name}`)
        continue
      }
      
      console.log('업로드 성공:', uploadData.path)
      
      // 데이터베이스에 파일 정보 저장
      const { error: insertError } = await supabase
        .from('performance_evidence_files')
        .insert({
          company_id: currentCompanyId.value,
          client_id: selectedClient.value.id,
          settlement_month: selectedSettlementMonth.value,
          file_name: file.name, // 원본 파일명 저장
          file_path: uploadData.path, // Storage 경로 저장
          file_size: file.size,
          uploaded_by: currentUserId.value
        })
        
      if (insertError) {
        console.error('파일 정보 저장 오류:', insertError)
        alert(`파일 정보 저장 실패: ${file.name}`)
      } else {
        console.log('DB 저장 성공:', file.name)
      }
    }
    
    alert('파일 업로드가 완료되었습니다.')
    closeUploadModal()
    await fetchClientList() // 목록 새로고침
    
  } catch (err) {
    console.error('파일 업로드 예외:', err)
    alert('파일 업로드 중 오류가 발생했습니다.')
  } finally {
    uploading.value = false
  }
}

async function fetchClientFiles(clientId) {
  try {
    const { data, error } = await supabase
      .from('performance_evidence_files')
      .select('*')
      .eq('company_id', currentCompanyId.value)
      .eq('client_id', clientId)
      .eq('settlement_month', selectedSettlementMonth.value)
      .order('uploaded_at', { ascending: false })
      
    if (error) {
      console.error('증빙파일 조회 오류:', error)
      return
    }
    
    clientFiles.value = data || []
  } catch (err) {
    console.error('증빙파일 조회 예외:', err)
    clientFiles.value = []
  }
}

async function downloadFile(file) {
  try {
    const { data, error } = await supabase.storage
      .from('performance-evidence')
      .download(file.file_path)
      
    if (error) {
      console.error('파일 다운로드 오류:', error)
      alert('파일 다운로드에 실패했습니다.')
      return
    }
    
    const url = URL.createObjectURL(data)
    const a = document.createElement('a')
    a.href = url
    a.download = file.file_name
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    
  } catch (err) {
    console.error('파일 다운로드 예외:', err)
    alert('파일 다운로드 중 오류가 발생했습니다.')
  }
}

async function deleteFile(file, index) {
  if (!confirm('이 파일을 삭제하시겠습니까?')) return
  
  try {
    // 스토리지에서 파일 삭제
    const { error: storageError } = await supabase.storage
      .from('performance-evidence')
      .remove([file.file_path])
      
    if (storageError) {
      console.error('스토리지 파일 삭제 오류:', storageError)
    }
    
    // 데이터베이스에서 파일 정보 삭제
    const { error: dbError } = await supabase
      .from('performance_evidence_files')
      .delete()
      .eq('id', file.id)
      
    if (dbError) {
      console.error('파일 정보 삭제 오류:', dbError)
      alert('파일 삭제에 실패했습니다.')
      return
    }
    
    // 목록에서 제거
    clientFiles.value.splice(index, 1)
    
    // 전체 목록 새로고침
    await fetchClientList()
    
    alert('파일이 삭제되었습니다.')
    
  } catch (err) {
    console.error('파일 삭제 예외:', err)
    alert('파일 삭제 중 오류가 발생했습니다.')
  }
}

async function downloadAllFiles() {
  if (clientFiles.value.length === 0) {
    alert('다운로드할 파일이 없습니다.');
    return;
  }

  const zip = new window.JSZip();
  const today = new Date().toISOString().slice(0, 10);
  const folderNameInZip = `증빙파일_${selectedClient.value?.name}_${today}`;
  const folder = zip.folder(folderNameInZip);

  try {
    // 모든 파일을 병렬로 다운로드 (성능 향상)
    const filePromises = clientFiles.value.map(async (file) => {
      try {
        const { data, error } = await supabase.storage
          .from('performance-evidence')
          .download(file.file_path);

        if (error) {
          console.error(`파일 다운로드 오류 (${file.file_name}):`, error);
          // 실패한 파일은 사용자에게 알릴 수 있도록 파일명과 함께 에러 상태 반환
          return { name: file.file_name, error: true, message: error.message };
        }
        // 성공 시 파일명과 데이터 반환
        return { name: file.file_name, data, error: false };
      } catch (err) {
        console.error(`파일 처리 예외 (${file.file_name}):`, err);
        return { name: file.file_name, error: true, message: err.message };
      }
    });

    const downloadedFileResults = await Promise.all(filePromises);

    let hasSuccessfulDownloads = false;
    downloadedFileResults.forEach(result => {
      if (result && !result.error) {
        folder.file(result.name, result.data, { binary: true });
        hasSuccessfulDownloads = true;
      } else if (result && result.error) {
        // 개별 파일 다운로드 실패 시 알림 (선택 사항)
        console.warn(`다운로드 실패: ${result.name} - ${result.message}`);
      }
    });

    if (!hasSuccessfulDownloads) {
      alert('모든 파일 다운로드에 실패했습니다.');
      return;
    }

    // ZIP 파일 생성 및 다운로드
    zip.generateAsync({ type: 'blob', compression: "DEFLATE", compressionOptions: { level: 9 } })
      .then(function (content) {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(content);
        // 최종 ZIP 파일명 설정
        link.download = `${folderNameInZip}.zip`; 
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(link.href); // 메모리 해제
      })
      .catch(err => {
        console.error('ZIP 생성 오류:', err);
        alert('ZIP 파일 생성에 실패했습니다.');
      });

  } catch (err) {
    console.error('전체 다운로드 예외:', err);
    alert('일부 파일 다운로드에 실패했거나 ZIP 생성 중 오류가 발생했습니다.');
  }
}
</script> 