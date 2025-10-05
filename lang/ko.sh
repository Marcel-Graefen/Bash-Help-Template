#!/bin/bash

## 한국어 (Korean)
LANGUAGE_NAME="한국어"
LANGUAGE_NAME_EN="Korean"

# TEXTE
TEXT_BACKTITLE="도움말 시스템"
TEXT_PROMPT="옵션을 선택하세요:"
TEXT_LABEL="파일"

TEXT_SKIPPED_DENY="건너뜀 (거부됨)"
TEXT_NO_READ_PERMISSION="읽기 권한 없음"
TEXT_FILE_TOO_LARGE="파일이 너무 큼"
TEXT_SEARCH_START="검색 시작:"
TEXT_RECOGNIZED_SINGLE_FILE="인식됨: 단일 INI 파일"
TEXT_RECOGNIZED_DIRECTORY="인식됨: 디렉토리"
TEXT_RECOGNIZED_WILDCARD="인식됨: 와일드카드 패턴"
TEXT_RECOGNIZED_RECURSIVE="인식됨: 재귀 패턴"
TEXT_INVALID_PATH="잘못된 경로"
TEXT_SEARCHED_DIRECTORY="검색된 디렉토리"
TEXT_SUCCESS="성공"
TEXT_DIRECTORIES="디렉토리"
TEXT_FILES="파일"

# BUTTONS
BTN_OK="확인"
BTN_CANCEL="취소"
BTN_CLOSE="닫기"
BTN_BACK="뒤로"
BTN_PREV="이전"
BTN_NEXT="다음"
BTN_HOME="메인 메뉴"
BTN_EXIT="종료"
BTN_LANGUAGE="언어 선택"
BTN_HELP="도움말"

# FEHLER
ERR_100="필수 구성이 누락되었습니다"
ERR_101="파일에 INI 구조가 잘못되었습니다"
ERR_102="언어 파일을 찾을 수 없습니다"
ERR_103="기본 언어를 사용할 수 없습니다"
ERR_104="주 메뉴 섹션을 찾을 수 없습니다"
ERR_105="잘못된 구성 형식"

ERR_200="파일을 찾을 수 없거나 읽을 수 없습니다"
ERR_201="잘못된 파일 경로"
ERR_202="디렉토리에 INI 파일이 없습니다"
ERR_203="디렉토리가 존재하지 않습니다"
ERR_204="파일 접근이 거부되었습니다"

ERR_300="메뉴 옵션을 찾을 수 없습니다"
ERR_301="다음에 대한 메뉴 항목을 찾을 수 없습니다"
ERR_302="유효한 메뉴 섹션을 찾을 수 없습니다"
ERR_303="잘못된 메뉴 탐색"
ERR_304="빈 메뉴 구조"

ERR_400="잘못된 파일 경로가 감지되었습니다"
ERR_401="접근 위반이 감지되었습니다"
ERR_402="경로 이동 시도가 차단되었습니다"

ERR_500="언어 파일을 로드할 수 없습니다"
ERR_501="잘못된 언어 구성"
ERR_502="지원되지 않는 언어 코드"

ERR_600="다음에 대한 콘텐츠를 찾을 수 없습니다"
ERR_601="콘텐츠 파일을 읽을 수 없습니다"
ERR_602="잘못된 콘텐츠 형식"

ERR_700="내부 시스템 오류"
ERR_701="Whiptail을 사용할 수 없습니다"
ERR_702="터미널 크기가 너무 작습니다"

# 유형 상수
TYPE_CONFIG="구성"
TYPE_CONTENT="콘텐츠"
TYPE_ERROR="오류"
TYPE_FILE="파일"
TYPE_LANGUAGE="언어"
TYPE_MENU="메뉴"
TYPE_SYSTEM="시스템"
TYPE_VERIFY="검증"

# 상태 유형
TYPE_STATUS_COMPLETED="완료됨"
TYPE_STATUS_FAILED="실패함"
TYPE_STATUS_PENDING="보류 중"
TYPE_STATUS_VERIFIED="검증됨"

# 작업 유형
TYPE_OPERATION_READ="읽기 작업"
TYPE_OPERATION_VALIDATE="유효성 검사 작업"
TYPE_OPERATION_VERIFY="검증 작업"

# 모듈 유형
TYPE_MODULE_CORE="코어 모듈"
TYPE_MODULE_FILE="파일 모듈"
TYPE_MODULE_VERIFY="검증 모듈"
