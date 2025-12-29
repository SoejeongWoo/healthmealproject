앱 이름: 오늘의 식단 (Flutter + Firebase)

> Flutter와 Firebase를 활용해 레시피(식단) 공유 · 찜하기 · 사용자 인증 · AI 코치 기능을 제공하는 모바일 애플리케이션


## 프로젝트 소개

오늘의 식*은 사용자가 건강한 식단과 레시피를 공유하고, 관심 있는 레시피를 찜하며, Firebase 기반 인증과 실시간 데이터 관리를 경험하기 위해 제작한 Flutter 프로젝트입니다.

Flutter의 UI 구성과 Provider 상태 관리, Firebase Authentication 및 Cloud Firestore 연동을 중심으로 실제 서비스 형태의 앱 구조를 목표로 개발했습니다.

## 프로젝트 목표

* Flutter를 이용한 모바일 앱 UI/UX 구현
* Firebase Authentication을 통한 사용자 인증 (이메일 / Google 로그인)
* Cloud Firestore를 활용한 실시간 데이터 관리
* Provider 기반 상태 관리 패턴 적용
* 정렬, 필터링, 찜하기 등 사용자 인터랙션 기능 구현


## ⚙️ 주요 기능

### 🔐 사용자 인증

* 이메일 / 비밀번호 로그인
* Google 계정 로그인
* 로그인 시 Firestore에 사용자 문서 자동 생성

  * 이름, 이메일, 상태 메시지, 찜 목록 저장

### 🍽 레시피(식단) 게시글

* 레시피 목록 GridView 형태로 출력
* 이미지, 음식 이름, 태그(옵션), 조리 시간 표시
* 레시피 상세 페이지 이동

### 찜(Wishlist) 기능

* 레시피 찜 / 해제
* 사용자별 찜 목록 관리
* 찜한 레시피 하트 아이콘 표시

### 정렬 및 필터링

* 최신순
* 좋아요순
* 조리 시간 짧은순 / 긴순
* 디저트 태그 필터

### AI 코치 (확장 기능)

* 하단 네비게이션을 통해 AI 코치 페이지 접근
* 건강/식단 관련 기능 확장 가능 구조

### 프로필 관리

* 사용자 프로필 조회
* 상태 메시지 및 사용자 정보 로드


## 🛠 기술 스택

### Frontend

* **Flutter**
* **Dart**
* Material Design 3

### State Management

* **Provider**

  * WishlistProvider
  * UserProvider
  * LoginProvider
  * DropDownProvider

### Backend (Firebase)

* **Firebase Authentication**

  * Email/Password 로그인
  * Google Sign-In
* **Cloud Firestore**

  * 사용자 정보 저장
  * 레시피 데이터 관리
  * 찜 목록 관리

### 기타

* dotenv (`.env`) 환경 변수 관리
* Firebase CLI / flutterfire 사용


## ✍️ 배운 점 / 느낀 점

* Flutter의 위젯 구조와 상태 관리 흐름을 실제 앱에 적용해볼 수 있었다.
* Firebase Authentication과 Firestore를 연동하면서 비동기 처리의 중요성을 이해할 수 있었다.
* Provider를 사용한 상태 관리로 UI와 로직을 분리하는 경험을 했다.
* 단순한 기능 구현을 넘어 서비스 구조를 고려한 앱 설계의 중요성을 느꼈다.