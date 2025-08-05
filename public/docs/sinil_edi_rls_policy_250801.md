# 신일제약 실적관리 시스템 RLS 정책 (2025-08-01)

## 📋 개요
본 문서는 신일제약 실적관리 시스템의 Row Level Security (RLS) 정책을 정리한 문서입니다.
Supabase의 RLS를 활용하여 데이터 접근을 제어하고 보안을 강화합니다.

---

## 🔐 RLS 정책 개요

### 1. 권한 체계
- **관리자 (admin)**: 모든 데이터에 대한 전체 접근 권한
- **일반 사용자 (user)**: 자신의 업체 데이터만 접근 가능
- **인증된 사용자 (authenticated)**: 공개 데이터 조회 가능

### 2. 주요 정책 원칙
- **최소 권한 원칙**: 필요한 최소한의 권한만 부여
- **업체별 격리**: 일반 사용자는 자신의 업체 데이터만 접근
- **관리자 우선**: 관리자는 모든 데이터에 접근 가능
- **공개 데이터**: 공지사항 등은 모든 인증된 사용자가 조회 가능

---

## 📊 테이블별 RLS 정책

### 1. `companies` 테이블

#### 1.1. 관리자 전체 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Admin can read all company data via user_metadata | SELECT | authenticated | `user_metadata.user_type = 'admin'` | 관리자는 모든 업체 데이터 조회 가능 |
| Allow admin to insert company data via user_metadata | INSERT | authenticated | - | 관리자는 업체 데이터 생성 가능 |
| Allow admin to update all company data | UPDATE | authenticated | `user_type = 'admin'` | 관리자는 모든 업체 데이터 수정 가능 |

#### 1.2. 일반 사용자 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow individual user to read their own company data | SELECT | authenticated | `auth.uid() = user_id` | 자신의 업체 데이터만 조회 가능 |
| Allow user to update their own limited company info | UPDATE | authenticated | `auth.uid() = user_id AND user_type = 'user'` | 자신의 업체 정보만 제한적으로 수정 가능 |
| Allow users to insert their own company data upon signup | INSERT | authenticated | `auth.uid() = user_id AND user_type = 'user' AND approval_status = 'pending'` | 회원가입 시 자신의 업체 정보 생성 |

#### 1.3. 공개 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow select for all | SELECT | public | `true` | 모든 사용자가 업체 목록 조회 가능 |

### 2. `notices` 테이블

#### 2.1. 관리자 전용 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow admin to insert notices | INSERT | authenticated | `user_type = 'admin'` | 관리자만 공지사항 작성 가능 |
| Allow admin to update notices | UPDATE | authenticated | `user_type = 'admin'` | 관리자만 공지사항 수정 가능 |
| Allow admin to delete notices | DELETE | authenticated | `user_type = 'admin'` | 관리자만 공지사항 삭제 가능 |

#### 2.2. 공개 조회 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow all authenticated users to read notices | SELECT | authenticated | `true` | 모든 인증된 사용자가 공지사항 조회 가능 |

### 3. `performance_records` 테이블

#### 3.1. 관리자 전체 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Admins can access all performance records | ALL | public | `user_type = 'admin'` | 관리자는 모든 실적 데이터 접근 가능 |

#### 3.2. 일반 사용자 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Users can view their company performance records | SELECT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 조회 가능 |
| Users can insert their company performance records | INSERT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 생성 가능 |
| Users can update their company performance records | UPDATE | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 수정 가능 |
| Users can delete their company performance records | DELETE | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 실적만 삭제 가능 |

### 4. `products` 테이블

#### 4.1. 관리자 전용 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow admin to read all products | SELECT | authenticated | `user_type = 'admin'` | 관리자는 모든 제품 조회 가능 |
| Allow admin to insert product data | INSERT | authenticated | `user_type = 'admin'` | 관리자만 제품 생성 가능 |
| Allow admin to update product data | UPDATE | authenticated | `user_type = 'admin'` | 관리자만 제품 수정 가능 |
| Allow admin to delete product data | DELETE | authenticated | `user_type = 'admin'` | 관리자만 제품 삭제 가능 |

#### 4.2. 공개 조회 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Allow authenticated users to read active products | SELECT | authenticated | `status = 'active'` | 인증된 사용자는 활성 제품만 조회 가능 |

### 5. `performance_evidence_files` 테이블

#### 5.1. 관리자 전체 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Admin full access to evidence files | ALL | public | `user_metadata.user_type = 'admin'` | 관리자는 모든 증빙 파일 접근 가능 |

#### 5.2. 일반 사용자 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Users can view their company evidence files | SELECT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 조회 가능 |
| Users can manage their company evidence files | ALL | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 관리 가능 |
| Users can insert their company evidence files | INSERT | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 업로드 가능 |
| Users can delete their company evidence files | DELETE | public | `company_id IN (SELECT id FROM companies WHERE user_id = auth.uid())` | 자신의 업체 증빙 파일만 삭제 가능 |

### 6. `settlement_months` 테이블

#### 6.1. 공개 조회 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Authenticated users can view settlement months | SELECT | public | `auth.role() = 'authenticated'` | 모든 인증된 사용자가 정산월 조회 가능 |

### 7. `settlement_share` 테이블

#### 7.1. 인증된 사용자 접근 정책
| 정책명 | 권한 | 역할 | 조건 | 설명 |
|--------|------|------|------|------|
| Authenticated can do anything | ALL | public | `auth.role() = 'authenticated'` | 인증된 사용자는 모든 작업 가능 |

---

## 🔍 정책 조건 상세 분석

### 1. 사용자 타입 확인 방식

#### 1.1. user_metadata 방식
```sql
(auth.jwt() -> 'user_metadata'::text) ->> 'user_type'::text) = 'admin'::text
```
- **용도**: 회원가입 시나리오에서 사용자 타입 확인
- **장점**: JWT 토큰에서 직접 확인 가능
- **단점**: 토큰 갱신 시까지 변경사항 반영 안됨

#### 1.2. companies 테이블 조회 방식
```sql
(SELECT companies.user_type FROM companies WHERE companies.user_id = auth.uid()) = 'admin'::text
```
- **용도**: 일반적인 권한 확인
- **장점**: 실시간 데이터 반영
- **단점**: 추가 쿼리 필요

### 2. 업체별 접근 제어 방식

#### 2.1. 서브쿼리 방식
```sql
company_id IN (SELECT companies.id FROM companies WHERE companies.user_id = auth.uid())
```
- **용도**: 사용자의 업체 ID로 데이터 필터링
- **장점**: 명확한 업체별 격리
- **단점**: 복잡한 쿼리

#### 2.2. 직접 비교 방식
```sql
auth.uid() = user_id
```
- **용도**: 사용자 직접 소유 데이터
- **장점**: 단순하고 빠름
- **단점**: 1:1 관계에서만 사용 가능

### 3. 상태별 접근 제어

#### 3.1. 활성 상태 확인
```sql
status = 'active'::text
```
- **용도**: 활성 데이터만 접근 허용
- **적용**: products, companies, clients 등

#### 3.2. 승인 상태 확인
```sql
approval_status = 'approved'::text
```
- **용도**: 승인된 업체만 접근 허용
- **적용**: companies 테이블

---

## 🛡️ 보안 고려사항

### 1. 권한 상승 방지
- **관리자 권한 확인**: 모든 관리자 전용 정책에서 이중 확인
- **업체 소유권 확인**: 사용자가 다른 업체 데이터에 접근하지 못하도록 제한
- **상태 기반 접근**: 활성/승인된 데이터만 접근 허용

### 2. 데이터 무결성 보장
- **외래키 제약**: 데이터베이스 레벨에서 참조 무결성 보장
- **트리거 활용**: 자동 업데이트 및 감사 추적
- **RLS 정책**: 애플리케이션 레벨에서 추가 보안

### 3. 감사 추적
- **변경 이력**: created_by, updated_by 필드로 변경자 추적
- **타임스탬프**: created_at, updated_at 필드로 변경 시점 추적
- **상태 이력**: review_status, approval_status 필드로 상태 변경 추적

---

## 🔧 정책 관리 및 모니터링

### 1. 정책 활성화 확인
```sql
-- RLS 활성화 확인
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('companies', 'notices', 'performance_records', 'products');

-- 정책 목록 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### 2. 정책 성능 모니터링
```sql
-- 정책 실행 통계 확인
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### 3. 정책 테스트
```sql
-- 관리자 권한 테스트
SELECT * FROM companies WHERE user_type = 'admin';

-- 일반 사용자 권한 테스트
SELECT * FROM companies WHERE user_id = auth.uid();

-- 업체별 데이터 접근 테스트
SELECT * FROM performance_records 
WHERE company_id IN (
    SELECT id FROM companies WHERE user_id = auth.uid()
);
```

---

## 📋 정책 요약 테이블

| 테이블명 | 관리자 권한 | 일반 사용자 권한 | 공개 권한 | 주요 특징 |
|----------|-------------|------------------|-----------|-----------|
| `companies` | ALL | 자신의 업체만 CRUD | SELECT | 회원가입 시 자동 생성 |
| `notices` | ALL | - | SELECT (인증된 사용자) | 관리자만 작성/수정/삭제 |
| `performance_records` | ALL | 자신의 업체만 CRUD | - | 업체별 완전 격리 |
| `products` | ALL | SELECT (활성 제품만) | - | 관리자만 관리 |
| `performance_evidence_files` | ALL | 자신의 업체만 CRUD | - | 파일 업로드/다운로드 |
| `settlement_months` | - | - | SELECT (인증된 사용자) | 모든 사용자가 조회 가능 |
| `settlement_share` | - | - | ALL (인증된 사용자) | 공유 설정 관리 |

---

## 🚀 향후 개선 방안

### 1. 세분화된 권한 관리
- **역할 기반 접근 제어 (RBAC)**: 더 세밀한 권한 분류
- **조건부 권한**: 시간, 상태에 따른 동적 권한 부여
- **위임 권한**: 관리자가 특정 권한을 위임할 수 있는 기능

### 2. 보안 강화
- **2단계 인증**: 중요 작업 시 추가 인증
- **세션 관리**: 자동 로그아웃 및 세션 만료
- **API 요청 제한**: 과도한 요청 방지

### 3. 모니터링 및 알림
- **권한 위반 로그**: RLS 정책 위반 시 로그 기록
- **실시간 알림**: 보안 이벤트 발생 시 즉시 알림
- **정책 성능 분석**: 정책별 성능 영향 분석

이러한 RLS 정책을 통해 신일제약 실적관리 시스템은 안전하고 견고한 데이터 접근 제어를 구현하고 있습니다. 