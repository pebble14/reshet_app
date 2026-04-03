# Docs 구조 가이드

## 디렉토리 용도

- architecture: 시스템 구조, 설계, 엔진 규칙
- database: DB 구조, 스키마, relation 모델
- ux: UI/UX 정책
- features: 기능 단위 설명
- logs: 변경 이력, 진행 상태

## 규칙

- 모든 문서는 반드시 /docs 하위에 위치한다
- 루트 및 /lib 등에 .md 파일 생성 금지 (예외: README.md, AGENTS.md)
- 새 문서는 반드시 위 기준에 따라 위치를 결정한다
- 애매한 경우 architecture로 보내지 말고 database/ux/features를 우선 검토한다
