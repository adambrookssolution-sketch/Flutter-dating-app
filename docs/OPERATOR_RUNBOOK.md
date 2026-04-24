# OPERATOR RUNBOOK — 고객 검증 기간 운영 매뉴얼

> 이 문서는 **당신(Gabriel)만을 위한 내부 운영 가이드**입니다.
> 고객에게는 공유하지 마세요.

---

## 상황 요약

- **환경:** 테스트 Firebase (`affinity-test-f4c84`, Spark 플랜)
- **고객:** María — APK 검증 단계
- **당신 계정:** `jenith.solution@gmail.com` (고객이 기능 체험용으로 로그인할 계정)
- **목적:** 고객이 두 가지 경로로 앱을 체험
  - **경로 A:** 고객 본인 이메일로 신규 가입 → 온보딩 전체 체험
  - **경로 B:** 당신 계정(`jenith.solution`)으로 로그인 → 승인된 상태 기능 체험

---

## 고객이 비디오 제출했을 때 (핵심 절차)

고객이 WhatsApp으로 "비디오 제출했어요"라고 연락 오면 **30초 안에 승인** 가능합니다.

### Step 1: 고객 UID 찾기

브라우저로 Firebase Console 열기:

```
https://console.firebase.google.com/project/affinity-test-f4c84/authentication/users
```

- 상단 검색창에 **고객 이메일** 입력
- 해당 행의 **UID 열** 복사 (예: `uAmjfWGdv3gtng4aVETaegBydv43`)

### Step 2: 승인 스크립트 실행

터미널(Git Bash) 열고 다음 한 줄 실행:

```bash
cd /d/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node lib/scripts/promote_user_to_approved.js \
  --project=affinity-test-f4c84 \
  --uid=<여기에_고객_UID_붙여넣기>
```

**성공 메시지:**
```
Target: affinity-test-f4c84, uid=<uid>
  + couples/<uid> upgraded to status=approved
Done.
```

### Step 3: 고객에게 확인 메시지

WhatsApp으로:
```
Listo, ya te aprobé. Cierra y vuelve a abrir la app,
o tira para abajo en la pantalla de espera para refrescar.
```

**예상 소요 시간: 1분**

---

## 자주 쓸 기타 명령어

### 고객 계정 상태 확인

```bash
cd /d/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node -e "
  const admin = require('firebase-admin');
  admin.initializeApp({ projectId: 'affinity-test-f4c84' });
  admin.firestore().collection('couples').doc('<UID>').get()
    .then(d => console.log(d.exists ? d.data() : 'NOT FOUND'))
    .then(() => process.exit(0));
  "
```

### 고객 UID를 이메일로 찾기 (CLI)

```bash
cd /d/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node -e "
  const admin = require('firebase-admin');
  admin.initializeApp({ projectId: 'affinity-test-f4c84' });
  admin.auth().getUserByEmail('<고객이메일>')
    .then(u => console.log('UID:', u.uid))
    .then(() => process.exit(0))
    .catch(e => { console.error(e.message); process.exit(1); });
  "
```

### 승인 이후 고객이 거부 플로우도 보고 싶다면

거부는 시연 못 함 (manage panel 미배포). 대신 스크린샷으로 설명하거나,
**새 계정을 하나 더 만들어서 그 계정을 거부 상태로** 만들어 체험시키기:

```bash
# (스크립트 별도 작성 필요 — 현재 없음. 요청 시 작성)
```

---

## 당신이 사전에 점검해야 할 것 (APK 보내기 전)

### 1. sa-key.json 유효성 확인

```bash
ls -la /d/app/sa-key.json
# 파일 있으면 OK
```

### 2. 스크립트 빌드 확인

```bash
ls /d/app/functions/lib/scripts/promote_user_to_approved.js
# 없으면 빌드 필요:
cd /d/app/functions && npm run build
```

### 3. 테스트: 당신 계정 상태 확인

당신 계정이 이미 `approved`인지:

```bash
cd /d/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node -e "
  const admin = require('firebase-admin');
  admin.initializeApp({ projectId: 'affinity-test-f4c84' });
  admin.auth().getUserByEmail('jenith.solution@gmail.com')
    .then(u => admin.firestore().collection('couples').doc(u.uid).get())
    .then(d => console.log(d.exists ? 'status=' + d.data().status : 'NO COUPLE DOC'))
    .then(() => process.exit(0));
  "
```

**예상 결과:** `status=approved`

아니면 당신 계정도 먼저 승인 처리:
```bash
# 위에서 출력된 UID를 넣어서:
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node lib/scripts/promote_user_to_approved.js \
  --project=affinity-test-f4c84 \
  --uid=<당신_UID>
```

---

## 고객 검증 중 예상되는 질문과 답변 (FAQ)

### Q1: "이메일 확인 메일이 안 와요"

**원인:** 가입 시 Firebase가 보내는 이메일 확인 메일이 **스팸함**에 있거나,
테스트 Firebase 설정에 따라 **전혀 안 감**.

**답:** "스팸함을 확인해 주세요. 안 오면 이메일 확인 없이도 진행 가능합니다
— 다음 화면에서 프로필 설정으로 넘어가세요."

### Q2: "비밀번호 잊어버렸어요"

**원인:** SendGrid 미연결로 복구 메일 안 옴.

**답:** "이 검증 환경에서는 복구 메일이 아직 활성화 안 돼 있습니다.
제가 새 비밀번호로 리셋해 드릴게요."

**당신 조치:** Firebase Console → Authentication → 해당 사용자 → `...` 메뉴 →
"Send password reset email"은 작동 안 함. 대신 **당신이 직접 비밀번호 리셋**:

```bash
cd /d/app/functions
GOOGLE_APPLICATION_CREDENTIALS=/d/app/sa-key.json \
  node -e "
  const admin = require('firebase-admin');
  admin.initializeApp({ projectId: 'affinity-test-f4c84' });
  admin.auth().getUserByEmail('<고객이메일>')
    .then(u => admin.auth().updateUser(u.uid, { password: 'Temp2026!' }))
    .then(() => console.log('Password reset to: Temp2026!'))
    .then(() => process.exit(0));
  "
```

그 다음 고객에게: "새 비밀번호는 `Temp2026!` 입니다. 로그인 후 바꿀 수 있습니다."

### Q3: "도시 검색이 안 돼요"

**원인:** Places API 키 미활성 (테스트 Firebase Spark). Fallback UI로 전환됨.

**답:** "도시 검색은 프로덕션에서 구글 자동완성으로 작동합니다. 이 검증
환경에서는 임시 입력창에 도시명을 직접 타이핑해 주세요."

### Q4: "알림이 안 와요"

**원인:** FCM 푸시는 Cloud Functions(Blaze 플랜)이 필요. 테스트 환경은 Spark.

**답:** "푸시 알림은 프로덕션 환경에서 활성화됩니다. 지금은 앱을 열어서
Inbox를 수동으로 확인해 주세요."

### Q5: "피드가 비어있어요"

**원인:** 필터가 너무 좁게 적용됐거나, 내 위치와 너무 멀리 있음.

**답 절차:**
1. "오른쪽 상단 파인애플 버튼 → 초기화(Reset) 눌러 주세요"
2. 그래도 비어있으면: 고객 계정의 geo 좌표를 확인해서 조정

---

## 검증 완료 후 당신이 할 일

고객이 "OK, 다음 단계로 가자"라고 승인하면:

1. **당신 계정 비밀번호 변경** (공유한 비밀번호 무효화)
2. **고객 테스트 계정 삭제** (Firebase Auth Console에서)
3. **프로덕션 전환 준비:**
   - Blaze 플랜 활성화
   - 실제 Firebase 프로젝트(`affinity-dating-app-cf807`)로 전환
   - SendGrid 연동 + SPF/DKIM/DMARC 설정
   - GCP Places API 키 발급
   - Cloud Functions 배포
   - Firestore Rules + Indexes 배포
   - Storage Rules 배포
   - 실제 데이터 마이그레이션(`migrate_profiles_to_couples.ts --write`)

---

## 긴급 상황 대응

### 고객이 화났을 때 (앱이 전혀 안 됨)

1. **APK 버전 확인:** 고객이 설치한 버전이 최신인지 (다시 다운로드 요청)
2. **로그인 상태 확인:** Firebase Auth에 계정 있는지
3. **승인 상태 확인:** `status=approved`인지 (위 확인 명령어)
4. **네트워크:** 고객이 Wi-Fi/모바일 데이터 연결 확인

문제 지속되면 **당신이 직접 LDPlayer로 같은 계정 로그인**해서 재현 → 원인 파악

---

**End of OPERATOR_RUNBOOK.md**
