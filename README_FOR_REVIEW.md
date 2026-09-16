# 등불의 전선 / Lantern March — Review Guide

Godot **4.6 stable**, GDScript, Compatibility renderer. Main Scene: res://scenes/boot/boot.tscn.

## 실행

Windows 간편 실행: 압축 해제한 폴더의 **PLAY_LANTERN_MARCH.bat** 더블클릭. Node.js20 이상이 필요하며 현재 개발 PC에는 설치되어 있다. 브라우저가 자동으로 열리고 Enter로 서버를 종료한다. 같은 포트8060을 유지해야 같은 브라우저 저장을 사용한다.

OpenClaw 및 다른 Agent 이관은 **HANDOFF.md**, 결정은 DECISIONS.md, 남은 작업은 TODO.md를 먼저 읽는다. Android/iOS native는 현재 Web milestone에서 의도적으로 제외했다.

## 개발 실행

ZIP 압축을 해제하고 Godot4.6에서 project.godot을 Import한 뒤 F6가 아닌 **F5**로 실행한다. 설치된 엔진은 ZIP에 포함하지 않는다. 별도 플러그인/패키지 설치는 필요 없다.

이미 빌드된 Web 실행(Node.js 필요):

~~~powershell
node tools/serve.mjs build/web 8060
~~~

Chrome에서 http://127.0.0.1:8060/ 접속. 파일을 더블클릭한 file:// 실행은 지원하지 않는다. 서버는 Ctrl+C로 종료한다. 공개 호스팅은 별도 미완료다.

## 조작

A/D 또는 좌우 화살표 이동, 1~6 병력 소환, J/K/L 단일탄/범위공격/회복, Escape 일시정지, 터치 하단 버튼도 동일 행동. F3 디버그 패널은 디버그 빌드만. Begin→스테이지 선택→적 기지 파괴; 보스 스테이지는 보스 처치. 영웅/아군 기지 사망은 패배. Camp에서 훈련·장비·설정.

## 테스트와 Web 재빌드

~~~powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Godot "C:\path\Godot_v4.6-stable_win64_console.exe"
powershell -ExecutionPolicy Bypass -File tools/export-web.ps1 -Godot "C:\path\Godot_v4.6-stable_win64_console.exe"
~~~

테스트는 프로젝트 .tools/userdata 아래 독립 APPDATA를 사용하고 artifacts에 결과를 쓴다. Web 재빌드는 Node.js와 네트워크가 필요하며 공식 release에서 threadless export template만 .tools/templates로 받는다. 원본 JSON이 권위 데이터다. CI/다른 OS에서는 같은 Godot --headless --path . --script res://tests/... 명령을 순서대로 실행할 수 있다. export template은 엔진과 정확히4.6 버전을 맞춘다.

## Web 배포 도구 회귀검증

`node --test tools/web-release.test.mjs` (Node.js 20+). 합성 export와 Node VM으로 릴리스 해시·경로별 캐시 정리·업데이트 중 화면 유지·설치 실패를 검증합니다. 실제 브라우저 설치/오프라인/IndexedDB 저장 검증은 아닙니다. 최신 결과: `review_artifacts/web_pwa_2026-09-16.md`.

## 검수 핵심

- PROJECT_AUDIT.md: 상세 요구사항/코드경로/한계/실제 케이스 구분.
- review_artifacts/test_results.txt 및 logs/*.json: **24케이스/237assertions**, 실패0. 기존76PASS는 assertion 개수였음.
- tests/runtime_e2e.gd: 실제 Main Scene/자동 physics 승리→UI훈련/장착→다른프로세스 복원.
- systems/battle_manager.gd, core/unit/unit_base.gd: 전투 조율/공격/사망.
- core/aura/hero_aura.gd, core/combat/combat_registry.gd, core/combat/projectile_pool.gd: 오라/타겟/풀.
- systems/save_manager.gd, data/: 저장 및 전체 콘텐츠.
- review_artifacts/package_validation.txt: 압축 해제본 실행과 파일 무결성.

완료 플랫폼: Windows Godot headless runtime, Chrome localhost Web release. 미검증: Android APK/실기기, iOS native/Safari, PWA 설치·오프라인, 실제 모바일 safe area와 성능, 청감 오디오. Known Critical Issues: 관찰0. 환경 로그의 Windows root certificate-store 오류와 Android SDK 경고는 명시적으로 남겨두었다. 게임 에러0과 환경 로그 에러0을 혼동하지 않는다.

전체 코드와 원본 자산, 빌드된 Web, 테스트 및 감사 자료가 이 패키지에 있으므로 별도 파일 수집은 필요 없다.


# OpenClaw Migration Checkpoint — 2026-09-14

Migration checkpoint: 2026-09-14. This pass preserves existing gameplay code, tests and Web release; no new feature or native-platform work. Latest recorded automated run:24 actual cases /237 assertions /0 failures. Tests were not rerun for documentation-only migration. Latest Web release:c7fa17a690861329. Previous lantern_march_review.zip predates the latest Web milestone; this migration ZIP is the authoritative source snapshot. Final Git/bundle and archive results: review_artifacts/migration_git.txt and migration_validation.txt.

Latest Chrome observation (port8062): actual Stage1 victory,130gold reward, Stage2 unlock, CinderLv2 training(310→210gold), Sunspike equip and settings changes. Final refresh/reopen after all those changes was interrupted and is NOT VERIFIED on this release. Earlier port8061 refresh evidence applies to the earlier build. Do not claim final Web-save lifecycle complete. Actual mobile devices, audible listening, PWA installation/update lifecycle and sustained browser rendering FPS remain NOT TESTED.
