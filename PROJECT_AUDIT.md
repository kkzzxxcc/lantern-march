# Project Overview

등불의 전선 / Lantern March. 독창적인 횡스크롤 단일 전선 전투 MVP. 플레이어는 영웅을 이동하고 병력을 소환하며 오라와 세 스킬로 지원한다. 일반 스테이지는 적 기지 파괴, 보스 스테이지는 보스 사망이 승리 조건이다. 본 보고서는 실제 소스와 저장된 실행 로그 기준이며 플랫폼 미검증을 구분한다. 감사 기준일: 2026-09-10.

# Engine / Version

Godot **4.6.stable.official.89cea1439**, GDScript, Compatibility renderer. Windows에서 실제 import, Main Scene, 자동 테스트, Web release export 실행. C# 및 외부 플러그인 의존 없음. 런타임 JSON 6개, GDScript 27개, Scene 7개, .tres/.res 0개. 엔진 실행 파일과 export template은 ZIP에 포함하지 않는다.

# Current Status

Current milestone: Web-first playable release. WEB MVP COMPLETION: **95% estimate**; FULL CROSS-PLATFORM PROJECT: **91% estimate**. Web rubric: core/content/progression70/70 + presentation/input10/10 + release/launcher10/10 + browser/PWA verification5/10. Remaining5 reflects real-device touch, audible listening, install/update lifecycle and sustained browser FPS gaps. Full-project rubric retains the prior cross-platform estimate for comparison; deferred native builds do not reduce the Web milestone score. Observed unresolved Critical0/Major0. No known blocking Web gameplay bug.

Android / iOS: **Deferred - intentionally not part of current Web milestone**. Public hosting is optional; no authenticated Git remote or configured hosting was present. No new login, credentials, SDK or native build was requested/performed.

# Implemented

실제 Main Menu, Stage Select, Battle, Pause, Upgrade, Equipment, Settings. 영웅 이동, 6종 소환, 8종 적, 보스2종, 스킬3개, 무기5/반지5, 스테이지10, 오라, 자원, 전투, 승패, 재시작, 영구 성장, 전투 EXP/3택 선택, 장비, 로컬 저장, 음량설정, 디버그 표시. Web release 산출물 포함.

# Partially Implemented

PWA metadata, root service worker, atomic cache population and content-versioned asset URLs are implemented. Chrome install UI and full upgrade/offline lifecycle are not yet certified. Safe areas are read through platform/web/web_adapter.gd; actual iPhone is NOT TESTED. Browser observations are separately recorded in browser_test.txt.

# Placeholder

독창적 절차형 도형 캐릭터/배경과 사인파 WAV 음향은 MVP 임시 자산이다. 유닛 역할별 실루엣과 간단한 이동/공격 자세만 있다. 스테이지10개는 적 구성·타이밍·거리·HP·보상·보스가 달라지며 배경은 공유한다. Wisp는 떠 있는 표현이며 독립 비행 충돌/지형 시스템은 없다. 현 UI는 영어이며 완성형 한글 현지화는 없다.

# Not Implemented

No public hosted URL. Cloud saves/multiplayer/accounts/payments are outside scope. Native Android/iOS delivery is intentionally deferred rather than counted as a Web defect.

# File Tree

실제 ZIP 포함 파일은 [review_artifacts/file_tree.txt](review_artifacts/file_tree.txt), 분류별 수치는 [source_metrics.json](review_artifacts/source_metrics.json), Git 상태는 [git_status.txt](review_artifacts/git_status.txt)와 [git_diff_stat.txt](review_artifacts/git_diff_stat.txt) 참조. Git snapshot은 git_status.txt 참조. 새 commit 전의 untracked 파일은 git diff --stat에 잡히지 않는다. GDScript 정확한 현재 줄 수는 source_metrics.json 참조(공백/주석 포함)이며 테스트 코드4개(.uid4개는 테스트 수에 포함하지 않음). 소스 파일89개 수치는 문서·로그·배포물을 제외한 초기 소스 범위였으며 최종 전체 포함 수는 file_tree/패키징 검증 로그가 기준이다.

# Architecture

Boot가 화면을 교체한다. Data/Save/Audio 세 autoload만 사용. BattleManager가 실제 _physics_process에서 simulate(delta)를 호출하고 자원/스폰/레지스트리/오라/유닛/투사체를 순서대로 진행한다. simulate는 실제 게임 경로이며 별도 가짜 전투 계산기가 아니다. UnitBase는 이동/공격/사망, UnitVisual은 렌더링을 담당. HeroController와 BossUnit이 확장한다. 데이터는 JSON이 권위 원본이며 GameData.validate가 참조를 확인한다.

BattleManager의 HUD 생성과 Save 호출은 여전히 결합 지점이다. 작은 MVP에는 가능하나 다음 규모 확장 전 진행도 서비스를 분리하는 것이 좋다. 대부분 UI가 런타임 생성되어 .tscn 파일 수가 적다. Unit은 매프레임 갱신하지만 대상 탐색은 시간 간격+공간 버킷을 사용한다. Scene Tree 전수검색을 전투 타겟 탐색에 사용하지 않는다. Dictionary 기반 데이터에 문자열 키가 많아 향후 typed Resource 전환 검토 대상이다.

# Scene Tree

구성된 Main Scene: res://scenes/boot/boot.tscn. 7개 실제 .tscn은 아래 파일 트리 참조. 전투 자식은 _ready에서 생성되므로 에디터 .tscn 파일만 보면 비어 보일 수 있다.

~~~text
/root
  Data (autoload)
  Save (autoload)
  Audio (autoload; music and pooled SFX players)
  Boot
    current screen OR Battle
      BattleGround (Node2D, auto-generated node name)
      HeroAura (Node2D, auto-generated node name)
      Actors
        player base / enemy base / Hero / spawned UnitBase or BossUnit
          UnitVisual
      ProjectilePool
      Camera2D
      Interface (CanvasLayer)
        BattleHUD (Control)
    orientation notice (CanvasLayer)
~~~

Registry, Resources, Spawner는 RefCounted 객체로 Battle 소유이며 Managers Node가 따로 없다. Friendly/Enemy는 별도 Node 폴더가 아니라 Actors 안에서 team으로 구분한다. 오라는 Area2D가 아닌 단일 전선 x거리 판정이다.

# Core Code Locations

| Requirement | Implementation (res://) | Function | Verification |
| --- | --- | --- | --- |
| Hero Movement | core/hero/hero_controller.gd | move_hero | runtime E2E movement |
| Friendly Unit Spawn | systems/battle_manager.gd | summon / _spawn | all six content + runtime cost |
| Enemy Spawn | systems/spawn_manager.gd | tick | runtime spawn; all enemy fixtures |
| Supply / Mana Recovery | core/resource/battle_resources.gd | tick / spend_supply / spend_mana | 30 vs 60 Hz, caps and costs |
| Target Detection | core/combat/combat_registry.gd | find_target / nearby / unregister | nearest, factions, death, retarget |
| Unit Movement / Attack | core/unit/unit_base.gd | tick / attack / edge_distance | range and attack edge cases |
| Damage Calculation | core/combat/combat_calculator.gd | damage | zero attack and high defense minimum1 |
| Death / Enemy Base Damage | core/unit/unit_base.gd | take_damage / die | runtime base destruction and cleanup |
| Aura Apply / Remove | core/aura/hero_aura.gd | update_membership / remove / clear | 8 allies x20 cycles and death cleanup |
| Stat Buff | core/unit/unit_base.gd | stat | 100 ->120 ->100 without accumulated writes |
| Hero Skill 1 / 2 / 3 | systems/battle_manager.gd | cast_skill / area_attack | three skills + resource/pool edges |
| Projectile Acquire | core/combat/projectile_pool.gd | launch / has_capacity | saturation rejects and no instant damage |
| Projectile Return | core/combat/projectile_pool.gd | tick / cancel_target / clear | impact, dead target, TTL and finish |
| Victory / Defeat | systems/stage_manager.gd | result_for_death | natural wins; hero/base/boss fixtures |
| End / Reward | systems/battle_manager.gd | finish / _on_death | runtime UI and production save |
| Reward / Stage Unlock | systems/save_manager.gd | reward_stage | stage1&2 unlocked3, repeat reward |
| Save / Load | systems/save_manager.gd | save_game / load_game / migrate | fresh process full equality, invalid formats |
| Equipment Equip | systems/save_manager.gd | equip / equipment_modifiers | all equipment stats; real UI persistent weapon |
| Unit Upgrade | systems/save_manager.gd | upgrade_unit | UI cinder level2, gold debit |
| InputMap / Multitouch | ui/action_button.gd | _input / _dispatch / _notification | simultaneous action, outside release |
| Menus | scenes/boot/boot.gd | show_screen / start_battle | actual Main Scene E2E |
| Boss Phase / Skill | core/unit/boss_unit.gd | tick | phase fixture and campaign bosses |
| Battle EXP / Three Choices | systems/battle_manager.gd | _check_battle_level / choose_upgrade | extended combat fixture |
| Audio / Settings | systems/audio_manager.gd | play / start_music / apply_settings | resources and settings path, listening untested |


모든 정의 함수의 실제 파일/라인 인덱스: [function_index.md](review_artifacts/function_index.md).

# InputMap

A/Left: move_left, D/Right: move_right. 1~6: summon_unit_1~6. J/K/L: skill_1~3. Escape: pause. F3: debug toggle(디버그 빌드 전용). 터치 전투 버튼은 ActionButton._dispatch에서 같은 InputEventAction을 발생시킨다. 실제 게임 로직은 BattleManager._unhandled_input과 HeroController 입력축에서 공유한다. Touch ID를 추적하고 버튼 밖 release, focus loss, exit에서 해제한다. 메뉴 버튼 callback은 deferred 처리해 입력 전달 중 Scene 삭제를 피한다.

# Data Structure

단위: HP/공격/방어 수치, 공격속도 회/초, 이동/사거리 px, 자원비용, 쿨다운 초. 아래 값은 최종 JSON에서 직접 생성했다. 장비·성장·오라 반영 전 기본값이다.

## Friendly Units (all spawnable)

| Name | Role | HP | Attack | Defense | AttackSpeed | MoveSpeed | Range | Supply | Cooldown | Behavior |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Cinder Guard | melee | 160 | 24 | 3 | 1 | 72 | 56 | 20 | 2 | melee |
| Moss Bastion | tank | 420 | 16 | 9 | 1 | 42 | 62 | 40 | 6 | melee |
| Reed Ranger | ranged | 105 | 28 | 1 | 1 | 64 | 310 | 30 | 4 | projectile |
| Prism Weaver | aoe | 95 | 32 | 1 | 0.65 | 53 | 265 | 48 | 7 | area |
| Dawn Mender | healer | 125 | 22 | 2 | 1 | 57 | 230 | 38 | 7 | heal |
| Ember Engine | siege | 250 | 65 | 5 | 0.45 | 34 | 350 | 65 | 10 | projectile |


Tank는 높은 HP/방어를 가진 근접병, Ranger는 풀 투사체, Mage는 범위 피해, Healer는 아군 회복, Siege는 기지 공격 배율2이다. 모두 실제 summon 경로에서 생성 확인.

## Enemies and Bosses (all reachable)

| ID / Name | Role | HP | Attack | Defense | AS | Move | Range | Behavior |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| husk / Ash Husk | melee | 100 | 15 | 2 | 1 | 50 | 52 | {"attack_type":"melee"} |
| skitter / Glass Skitter | fast | 65 | 14 | 0 | 1.5 | 110 | 48 | {"attack_type":"melee"} |
| bulwark / Iron Husk | tank | 300 | 21 | 8 | 1 | 33 | 62 | {"attack_type":"melee"} |
| slinger / Cinder Slinger | ranged | 95 | 19 | 1 | 1 | 46 | 275 | {"attack_type":"projectile"} |
| wisp / Hollow Wisp | special | 85 | 18 | 1 | 1 | 86 | 180 | {"attack_type":"projectile"} |
| bell / Fracture Bell | aoe | 160 | 26 | 3 | 0.6 | 36 | 240 | {"attack_type":"area"} |
| cantor / Rust Cantor | support | 155 | 18 | 3 | 1 | 45 | 240 | {"attack_type":"buff"} |
| warden / Night Warden | elite | 420 | 36 | 8 | 1 | 48 | 70 | {"attack_type":"melee"} |
| kiln / The Walking Kiln | boss | 1900 | 40 | 8 | 0.65 | 25 | 90 | {"attack_type":"area"} |
| eclipse / The Hollow Crown | boss | 3200 | 49 | 11 | 0.75 | 31 | 320 | {"attack_type":"projectile"} |


Cantor는 주변 적에게 4초 공격/속도15% 지원. 두 보스는 BossUnit.tick에서 HP 임계점 아래 2페이즈 진입, 속도/공격 주기 조절과 고유 스킬 반복. Kiln은 범위 분출, Crown은 Wisp 소환. 특수 행동은 완성형 애니메이션 없이 도형 효과로 표현한다.

## Skills

| Name | Type | Key | Mana | Cooldown | Parameters |
| --- | --- | --- | --- | --- | --- |
| Sunbolt | projectile | J | 25 | 4 | {"id":"sunbolt","name":"Sunbolt","key":"J","type":"projectile","mana_cost":25,"cooldown":4,"range":620,"power":100,"description":"Strike the nearest enemy ahead."} |
| Lantern Flare | area | K | 45 | 9 | {"id":"flare","name":"Lantern Flare","key":"K","type":"area","mana_cost":45,"cooldown":9,"range":300,"radius":180,"power":88,"description":"Burn enemies in front of you."} |
| First Light | heal | L | 35 | 10 | {"id":"renew","name":"First Light","key":"L","type":"heal","mana_cost":35,"cooldown":10,"radius":310,"power":105,"description":"Heal yourself and nearby allies."} |


cast_skill(0/1/2)가 공통 입력과 자원 조건을 거친다. Flare는 영웅 앞 중심 범위, First Light는 영웅 및 주변 아군 회복(기지 제외). 데이터 range 항목과 실제 앞쪽 시전 중심 상수는 분리돼 있어 조정 시 코드를 함께 확인해야 한다.

## Equipment

| ID | Name | Slot | Stats |
| --- | --- | --- | --- |
| wickblade | Wickblade | weapon | {"attack":4} |
| sunspike | Sunspike | weapon | {"attack":12} |
| iron_oath | Iron Oath | weapon | {"attack":8,"defense":5} |
| glass_staff | Glass Staff | weapon | {"attack":14,"mana_recovery":1} |
| daybreak | Daybreak | weapon | {"attack":22,"attack_speed":0.2} |
| trail_ring | Trail Ring | ring | {"aura_range":20} |
| spring_loop | Spring Loop | ring | {"hp":80} |
| river_knot | River Knot | ring | {"mana_recovery":1.5} |
| harvest_band | Harvest Band | ring | {"supply_recovery":1.5} |
| halo | Keeper Halo | ring | {"aura_range":50,"defense":4} |


Owned 검증 후 equip, 다음 전투 초기화에서 modifiers를 hero/resource/aura에 반영한다. 초기 wickblade/trail_ring, 이후 첫 클리어 드롭. 반지 슬롯2개, 동일 반지 중복 장착 제한. 레벨 성장과 장비 저장은 실제 SaveManager 사용.

## Stages

| ID / Name | Enemy composition: weight@start seconds | Interval / first spawn | Length / enemy HP / player HP | Boss | Reward |
| --- | --- | --- | --- | --- | --- |
| 1 / The Quiet Verge | husk:5@0, skitter:2@14 | 7 / 4 | 2100 / 600 / 1100 | — | {"gold":130,"exp":45,"equipment":"sunspike"} |
| 2 / Reed Crossing | husk:5@0, skitter:2@14, slinger:2@12 | 6.65 / 4 | 2180 / 730 / 1140 | — | {"gold":175,"exp":65,"equipment":"spring_loop"} |
| 3 / Copper Orchard | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22 | 6.3 / 4 | 2260 / 860 / 1180 | — | {"gold":220,"exp":85,"equipment":"iron_oath"} |
| 4 / A Road of Embers | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16 | 5.95 / 4 | 2340 / 990 / 1220 | — | {"gold":265,"exp":105,"equipment":"river_knot"} |
| 5 / Heart of the Kiln | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16 | 5.6 / 4 | 2420 / 1120 / 1260 | kiln @28s | {"gold":310,"exp":125,"equipment":"glass_staff"} |
| 6 / The Pale Causeway | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16, bell:2@25, cantor:1@30 | 5.25 / 4 | 2500 / 1250 / 1300 | — | {"gold":355,"exp":145,"equipment":"harvest_band"} |
| 7 / Bells in the Mist | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16, bell:2@25, cantor:1@30 | 4.9 / 4 | 2580 / 1380 / 1340 | — | {"gold":400,"exp":165,"equipment":"daybreak"} |
| 8 / The Broken Watch | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16, bell:2@25, cantor:1@30, warden:1@35 | 4.550000000000001 / 4 | 2660 / 1510 / 1380 | — | {"gold":445,"exp":185,"equipment":"halo"} |
| 9 / The Last Lantern | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16, bell:2@25, cantor:1@30, warden:1@35 | 4.2 / 4 | 2740 / 1640 / 1420 | — | {"gold":490,"exp":205,"equipment":""} |
| 10 / Crown of the Hollow | husk:5@0, skitter:2@14, slinger:2@12, bulwark:2@22, wisp:2@16, bell:2@25, cantor:1@30, warden:1@35 | 3.85 / 4 | 2820 / 1770 / 1460 | eclipse @28s | {"gold":535,"exp":225,"equipment":""} |


난이도 차이는 위 구성과 간격/거리/체력이다. 공통 전장과 가중 랜덤 스폰 방식이므로 완전히 다른10개 맵이라고 주장하지 않는다. StageSelect는 Data.stages를 순회하며 잠금을 적용한다. 스테이지5/10은 기지 무적, 보스 사망이 승리. 마지막 해금은10으로 제한. 자동 정책으로10단계 모두 승리했으나 사람의 난이도/재미 평가는 별도 필요하다.

## Growth

초기180 gold. 유닛 훈련비100×현재레벨, 레벨당 HP20/공격5. 영구 영웅 성장 레벨당 HP25/공격3. 첫 승리 gold/drop, 반복 승리 gold40%. 전투 EXP는 영구 EXP와 분리되고 전투 레벨마다 랜덤3택 선택으로 공격/오라/자원 회복을 강화한다. 세이브 v1은 gold, hero_level/exp, unit_levels, owned_equipment, equipped, unlocked_stage, cleared, settings를 기록한다.

# Test Results

Executed on Windows with Godot 4.6.stable.official.89cea1439.
Reproduction command: powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Godot <absolute Godot 4.6 console executable>
Actual automated cases: 24 = 11 focused + 10 audit + 1 runtime E2E across two processes + 1 save probe across two processes + 1 boss runtime case.
Assertions: 237 = 84 + 115 + 28 + 4 + 2 + 4. Failures: 0.
The previous 76 PASS claim counted assertions, not cases. Campaign stage iterations and boundary cycles are not additional cases.
Browser observations are separate manual UI scenarios and excluded from these counts.
Focused tests use production Battle Scene / simulate, but disable automatic physics; they are not end-to-end runtime tests.
Runtime E2E loads configured Main Scene, uses automatic physics and input, and wins stages 1 and 2 naturally. --fixed-fps 60 accelerates wall time and is not a 60 FPS performance measurement.
Save probe uses production SaveManager and a separate process.
Only the Windows root certificate store error is exempted in tools/test.ps1. No other error/warning allowed.



| Test code | Actual case | Category | Real Scene | Automatic Physics | Save file | Result |
| --- | --- | --- | --- | --- | --- | --- |
| tests/runtime_e2e.gd -- boss | Stage5 and Stage10 UI entry and automatic physics victory | Runtime / Scene (progression entry fixture) | true | true | true | PASS |
| tests/test_runner.gd | catalog_and_input | Unit / Configuration | false | false | false | PASS |
| tests/test_runner.gd | battle_core | Scene / Integration | true | false | false | PASS |
| tests/test_runner.gd | restart_and_hero_defeat | Scene / Integration | true | false | false | PASS |
| tests/test_runner.gd | friendly_base_defeat | Scene / Integration | true | false | false | PASS |
| tests/test_runner.gd | boss_phase_and_victory | Scene / Integration | true | false | false | PASS |
| tests/test_runner.gd | save_progress_and_recovery | Save Persistence | false | false | true | PASS |
| tests/test_runner.gd | stage_one_policy | Integration | true | false | false | PASS |
| tests/test_runner.gd | entity_99 | Performance | true | false | false | PASS |
| tests/test_runner.gd | healer_support_siege_exp | Scene / Integration | true | false | false | PASS |
| tests/test_runner.gd | ui_and_multitouch | Scene / Touch | true | false | false | PASS |
| tests/test_runner.gd | campaign_10_stages | Integration / Save | true | false | false | PASS |
| tests/audit_suite.gd | aura_reentry_and_cleanup | Integration / Scene | true | false | false | PASS |
| tests/audit_suite.gd | target_range_death_and_faction | Integration / Scene | true | false | false | PASS |
| tests/audit_suite.gd | shared_damage_and_attack_boundaries | Unit / Scene | true | false | false | PASS |
| tests/audit_suite.gd | projectile_pool_acquire_release_and_saturation | Integration / Scene | true | false | false | PASS |
| tests/audit_suite.gd | resources_delta_caps_costs_cooldowns | Unit / Integration | true | false | false | PASS |
| tests/audit_suite.gd | save_invalid_missing_migration_and_ownership | Save Persistence | true | false | true | PASS |
| tests/audit_suite.gd | all_content_reachable_and_equipment_stats | Scene / Integration | true | false | false | PASS |
| tests/audit_suite.gd | 50_and_100_entities_cpu_and_cleanup | Performance / Scene | true | false | false | PASS |
| tests/audit_suite.gd | save_transaction_rollback | Save Persistence / Regression | true | false | true | PASS |
| tests/audit_suite.gd | support_rear_positioning | Scene / Regression | true | false | false | PASS |
| tests/runtime_e2e.gd | Main Scene -> 2 wins -> progression -> process reload | Runtime / End-to-End / Touch / Persistence | true | true | true | PASS |
| tests/save_probe.gd | write process -> read process | Save Persistence | false | false | true | PASS |


각 assertion 이름·대상·근거와 케이스 메타데이터는 review_artifacts/logs/*.json에 원문 포함. 동일 테스트 재실행이나 패키지 재검증은 케이스/Assertion 총계에 더하지 않는다. focused scene 테스트는 수동 simulate와 fixture 직접 피해/좌표 조정을 사용하므로 자연스러운 승리 근거로 오인하면 안 된다. 자연10-stage 정책도 수동 step integration이며 실제 자동 physics E2E는 별도 코드다.

## Real Vertical Slice path

Boot.show_screen -> MenuScreen._stages -> Boot.start_battle -> Battle._ready -> _physics_process/simulate -> HeroController.move_hero -> BattleResources.tick -> Battle.summon -> SpawnManager.tick/spawn_enemy -> UnitBase.tick/CombatRegistry.find_target -> attack/take_damage/CombatCalculator.damage -> die/Battle._on_death -> StageManager.result_for_death -> Battle.finish -> Save.reward_stage/save_game. HeroAura.update_membership와 UnitBase.stat이 버프/복구를 제공하고 Battle.cast_skill은 Mana와 풀을 사용한다. runtime_e2e는 지정 Main Scene에서 이 경로로 Stage1·2를 승리하고 UI 훈련/장착/설정 후 프로세스를 종료한다.

## Focused audit findings and fixes

- AttackSpeed0에서 공격을 막고 공격 시점 alive/valid/현재 사거리 재확인. Hero 이동 이후 오래된 사거리로 공격하는 경로 수정.
- 사망 시 registry의 모든 버킷/남은 target 참조와 aura 및 projectile target을 즉시 제거.
- 풀 포화 시 즉시 피해를 주던 fallback 제거. 발사 실패는 false, 자동 공격은 짧게 재시도, 스킬은 자원 낭비 방지.
- 터치 입력 처리 중 메뉴 삭제 문제를 guarded deferred callback으로 수정. 다중 Touch ID와 밖에서 release 검증.
- 잘못된 save version 타입/미래 버전 보호 및 cleared ID 정규화. 이전 테스트용 reward-save 우회 test_mode 제거; presentation_enabled는 HUD 표시만 제어.
- 동시 사망 EXP와 전투 선택 상태 처리, 오디오 burst 제한과 종료 자원 정리 보완.

오라: 공격100→120→100, 방어·속도 각각15% 추가 후 원본 복구를 8유닛 동시20회 반복 검사. stat은 원본을 곱해 읽으며 원본 stats를 누적 덮어쓰지 않는다. death/scene cleanup과 대상 사망도 검사. 풀은64개 Dictionary slot 선할당, 발사별 Node instantiate/free 없음; 명중/목표 사망/TTL/종료 시 반납. 자원은 delta 기반30/60Hz 비교, clamp/부족/쿨다운 검증.

# Browser Test

[실제 관찰 기록](review_artifacts/browser_test.txt). 최종 Web release Chrome에서 메뉴/전투/키보드/훈련/새로고침 저장을 확인했다. 1920×1080과2560×1440 HUD 배치 확인. 이전844×390 검사도 기록했지만 최종 수정본의 모바일 실기기 증거로 사용하지 않는다. Web export 파일은 build/web에 포함. 공개 URL 없음. PWA manifest/service worker가 존재하나 설치·오프라인은 NOT TESTED.

# Save Persistence Test

Process A: 정상 UI+전투로 Stage1/2승리, Cinder훈련, Sunspike장착, music0.32 저장. Process B: 실제 Save.load_game 후 모든필드 일치. gold385, heroLv2/exp30, CinderLv2, owned4종, weaponSunspike/ringTrail, unlocked3, cleared[1,2]. 이는 fixture로 값을 주입한 save_probe와 구분한 실제 런타임 결과다. [원문 JSON](review_artifacts/logs/runtime-e2e-reload.json).

파일 없음/손상/v0/잘못된 수치/소유권/잘못된 version타입/future version도 검사. tmp flush + backup + rename으로 저장하며 손상 시 backup/default 복구. v1보다 새 버전은 덮어쓰기 거부. OS 전원차단 중 내구성 및 클라우드 동기화는 미검증. 테스트는 별도 user:// 파일명과 APPDATA로 실제 사용자 저장을 분리한다. ZIP에는 개인 저장파일 미포함. 브라우저 저장은 origin별 IndexedDB라 포트/도메인 변경 시 공유되지 않는다.

# Android Status

Android: Deferred - intentionally not part of current Web milestone. Existing preset retained. No SDK installation, APK or device test in this milestone.

# iOS Status

iOS: Deferred - intentionally not part of current Web milestone. Existing preset retained. No Xcode/native export/TestFlight work in this milestone.

# Performance

| Initial / end entities | Ticks | Median μs | p95 μs | Target queries / total μs | Memory before / after bytes | Projectile slots / active |
| --- | --- | --- | --- | --- | --- | --- |
| 50 / 43 | 300 | 196 | 636 | 1000 / 16630 | 24003270 / 24019820 | 64 / 0 |
| 100 / 95 | 300 | 251 | 1460 | 2000 / 56298 | 24531780 / 24545946 | 64 / 0 |


CPU headless microbench이며 FPS가 아니다. 100개 fixture는 정상99개 상한을 넘어 부하 주입. 죽은 registry entry 없음을 확인. 버킷200px/10Hz 갱신, 타겟 탐색0.2초, 오라0.12초, HUD0.1초. 짧은 실행 메모리 증가는 위 수치이며 장시간 plateau/Signal 증가 추세/실기기60FPS/발열/GPU는 NOT TESTED. 사망 시 signal 연결은 해당 node 해제와 함께 제거되지만 정량 Signal count 프로파일은 없다.

# Known Errors

최종 자동 검증에서 프로젝트 Script Parse/Runtime 실패0. 관찰된 미해결 Critical0/Major0은 검증 범위에 한정되며 미검증 플랫폼 무결점을 의미하지 않는다. Windows 환경의 ERROR: Failed to read the root certificate store는 로그에 존재하고 테스트 스캐너에서 명시적으로 제외했다.

# Known Warnings

Android build-tools 디렉터리 부재 경고가 export/editor 환경에서 발생. 인증서 저장소 접근 제한은 엔진 내장 CA fallback을 사용하는 환경 문제이며 모든 로그를 오류0으로 보고하지 않는다. 위 두 환경 상태 원문은 검수 로그에 보존한다. 청감 음향 품질은 NOT TESTED.

# Technical Debt

BattleManager는 조율+HUD생성+저장연결까지 맡는 중간 크기 책임 집중점이다. Boot라는 루트 이름을 UI _router가 직접 참조하므로 리네이밍에 취약. Dictionary 키와 일부 UI/전투 수치 상수, 프로그램 생성 UI의 에디터 가시성 한계. Data validation은 기본 스키마/참조를 검사하나 모든 악의적 수치 조합을 완전 보장하지 않는다. 타겟 bucket 갱신 간격으로 빠른 유닛 후보가 짧게 지연될 수 있다. 유닛 본체는 스폰/사망마다 생성/해제하고 투사체만 풀링한다. Deprecated API나 순환 preload로 인한 Godot4.6 parse failure는 실행 검사에서 관찰되지 않았다.

가짜 구현 검색 원문: implementation_scan.txt. UnitBase.move_hero의 pass는 HeroController override 확장점이다. return true는 앞 조건을 통과한 성공 결과이며 무조건 성공 검증기가 아니다. debug 강제승리 기능은 OS.is_debug_build 보호 아래만 가능하고 runtime E2E는 사용하지 않는다. Placeholder는 실제 임시 자산 품질을 뜻한다. Scene용 스크립트가 .tscn에 직접 연결되지 않아도 class_name.new()로 생성되는 경로를 확인했다. 모든 콘텐츠 소환/장비 반영은 focused audit에 포함한다.

# Missing Requirements

| Requirement | Status | Implementation / Verification |
| --- | --- | --- |
| Hero Movement | PASS | core/hero/hero_controller.gd :: move_hero; runtime E2E movement |
| Friendly Unit Spawn | PASS | systems/battle_manager.gd :: summon / _spawn; all six content + runtime cost |
| Enemy Spawn | PASS | systems/spawn_manager.gd :: tick; runtime spawn; all enemy fixtures |
| Supply / Mana Recovery | PASS | core/resource/battle_resources.gd :: tick / spend_supply / spend_mana; 30 vs 60 Hz, caps and costs |
| Target Detection | PASS | core/combat/combat_registry.gd :: find_target / nearby / unregister; nearest, factions, death, retarget |
| Unit Movement / Attack | PASS | core/unit/unit_base.gd :: tick / attack / edge_distance; range and attack edge cases |
| Damage Calculation | PASS | core/combat/combat_calculator.gd :: damage; zero attack and high defense minimum1 |
| Death / Enemy Base Damage | PASS | core/unit/unit_base.gd :: take_damage / die; runtime base destruction and cleanup |
| Aura Apply / Remove | PASS | core/aura/hero_aura.gd :: update_membership / remove / clear; 8 allies x20 cycles and death cleanup |
| Stat Buff | PASS | core/unit/unit_base.gd :: stat; 100 ->120 ->100 without accumulated writes |
| Hero Skill 1 / 2 / 3 | PASS | systems/battle_manager.gd :: cast_skill / area_attack; three skills + resource/pool edges |
| Projectile Acquire | PASS | core/combat/projectile_pool.gd :: launch / has_capacity; saturation rejects and no instant damage |
| Projectile Return | PASS | core/combat/projectile_pool.gd :: tick / cancel_target / clear; impact, dead target, TTL and finish |
| Victory / Defeat | PASS | systems/stage_manager.gd :: result_for_death; natural wins; hero/base/boss fixtures |
| End / Reward | PASS | systems/battle_manager.gd :: finish / _on_death; runtime UI and production save |
| Reward / Stage Unlock | PASS | systems/save_manager.gd :: reward_stage; stage1&2 unlocked3, repeat reward |
| Save / Load | PASS | systems/save_manager.gd :: save_game / load_game / migrate; fresh process full equality, invalid formats |
| Equipment Equip | PASS | systems/save_manager.gd :: equip / equipment_modifiers; all equipment stats; real UI persistent weapon |
| Unit Upgrade | PASS | systems/save_manager.gd :: upgrade_unit; UI cinder level2, gold debit |
| InputMap / Multitouch | PASS | ui/action_button.gd :: _input / _dispatch / _notification; simultaneous action, outside release |
| Menus | PASS | scenes/boot/boot.gd :: show_screen / start_battle; actual Main Scene E2E |
| Boss Phase / Skill | PASS | core/unit/boss_unit.gd :: tick; phase fixture and campaign bosses |
| Battle EXP / Three Choices | PASS | systems/battle_manager.gd :: _check_battle_level / choose_upgrade; extended combat fixture |
| Audio audible quality | NOT TESTED | AudioManager resources/settings implemented; no listening verification |
| Mobile real multitouch / safe area | NOT TESTED | ActionButton/SafeMargin implemented; injected touch only |
| Public Web / PWA install offline | PARTIAL | build/web release present, localhost Chrome PASS |
| Android signed APK | PARTIAL | export_presets.cfg preparation only |
| iOS native archive | PARTIAL | export_presets.cfg preparation only |
| Rendered 50/100 entity FPS and thermal | NOT TESTED | headless CPU profiling only |
| Original assets / IP | PASS | code/data/assets scan and original procedural asset provenance |


# Priorities

1. Real mobile-browser multitouch/safe-area and audible audio QA.
2. PWA install/update testing on HTTPS; sustained Chrome rendering FPS with 50 entities.
3. Human balance sessions across10 stages and support-unit survival checks.
4. After this Web milestone, schedule Android/iOS native work.

# IP / Asset Provenance

게임 내 이름, 절차형 도형 아트, WAV 및 icon.svg는 이 프로젝트에서 새로 제작했다. 원작 캐릭터/스프라이트/음향/대사/맵을 가져오지 않았다. 코드·데이터·assets 문자열 스캔에서 원작명 없음. 폴더의 역사적 이름 Paladog는 사용자 작업 경로일 뿐 게임 제목이 아니다. Godot 엔진/웹 런타임은 별도 MIT 라이선스이며 THIRD_PARTY_NOTICES.md에 안내한다. 일반 원작명 문자열 검색은 캐릭터 유사성에 대한 전문 법적 심사를 대체하지 않는다.

# Package Verification

최종 패키지는 project.godot, 전체 소스/Scene/데이터/원본Asset/테스트/도구, 본 문서 및 README_FOR_REVIEW, review_artifacts와 실제 build/web release를 포함한다. .git/.godot/.tools, 로컬 저장/인증정보/키스토어는 제외. 압축 해제본 import와 Main Scene 실행 결과 및 SHA256 파일비교는 review_artifacts/package_validation.txt에서 확인한다. 엔진 캐시 없이 import하여 누락 리소스를 검사한다. 동일 소스 검증 재실행은 테스트 총계에 더하지 않는다.

# External Review Notes

빠른 시작은 README_FOR_REVIEW.md. 이 ZIP 하나에 검수에 필요한 전체 소스 및 실제 로그가 포함되어 있다. 문서 서술보다 실제 코드와 로그를 우선하고 미검증 플랫폼 결과를 추정하지 말아야 한다. export template/엔진은 제외하지만 이미 생성된 Web release는 들어 있다.

공식 근거: [Godot 4.6 stable](https://godotengine.org/download/archive/4.6-stable/), [Web export](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_web.html), [Android export](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html), [iOS export](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_ios.html).

위 내용을 기준으로 현재 구현이 최초 요구사항에 맞게 제대로 되어 있는지 검토해 주세요. 구조적 문제, Godot 4.6.x 기준 잘못된 구현, 크로스플랫폼 문제, 성능 문제, 저장 시스템 문제, UI/게임 로직 결합 문제, 구현 누락, 실행 시 발생할 가능성이 높은 버그를 우선적으로 찾아주세요. 필요하다면 검수를 위해 어떤 파일의 전체 내용을 추가로 보내야 하는지도 정확한 파일 경로와 함께 알려주세요.

# Web Milestone Changes

SaveManager._commit snapshots and rolls back failed mutations. upgrade_unit/equip return the save result; reward_stage returns saved=false with zero granted reward, and the victory UI offers Retry saving reward. Settings use set_setting with rollback. This confirms Godot file-API completion; IndexedDB synchronization is asynchronous and browser refresh validation is separate.

UnitBase.move_support maintains a position110px behind the nearby friendly front regardless of heal/buff eligibility, observes the opposing front and stops or retreats. Both teams share it. A test originally demanded no backward retreat after ally death; that over-restrictive test expectation was corrected to forbid forward runaway while allowing retreat. Final regression suite passes.

WebAdapter isolates JavaScriptBridge from UI and combat. tools/finalize-web.mjs hashes executable/data, writes viewport-fit=cover, manifest, theme metadata and service worker. Immutable versioned URLs prevent combining old executable with new data. Worker install waits for all release assets; no forced skipWaiting while existing clients run. Safe asset deployment: publish the complete release directory atomically; keep previous hashed assets available while active clients finish. Hosting deployments are not performed here.

Actual automatic-physics boss case uses a clearly declared progression entry fixture (heroLv5, front unitsLv4, earned-campaign-style equipment); no invincibility, altered damage, free battle resources or simulate calls. Stage5 victory42.17s, Stage10 victory189.93s. The full naturally progressed10-stage integration remains separate.

Balance: roles retain cost/range/armor/heal/siege tradeoffs; no blanket stat buffs were applied. Stage1 normal runtime wins around32s and final boss takes substantially longer. Single-unit dominant-strategy absence and human enjoyment are not proven by the scripted mixed-army policy; further playtest is NEXT.

Handoff: HANDOFF.md, DECISIONS.md, TODO.md. Play package: lantern_march_web_release.zip. Source package: lantern_march_review.zip. ZIP tooling enforces forward slash entry paths and verifies extracted payload hashes.


# OpenClaw Migration Checkpoint — 2026-09-14

Migration checkpoint: 2026-09-14. This pass preserves existing gameplay code, tests and Web release; no new feature or native-platform work. Latest recorded automated run:24 actual cases /237 assertions /0 failures. Tests were not rerun for documentation-only migration. Latest Web release:c7fa17a690861329. Previous lantern_march_review.zip predates the latest Web milestone; this migration ZIP is the authoritative source snapshot. Final Git/bundle and archive results: review_artifacts/migration_git.txt and migration_validation.txt.

Latest Chrome observation (port8062): actual Stage1 victory,130gold reward, Stage2 unlock, CinderLv2 training(310→210gold), Sunspike equip and settings changes. Final refresh/reopen after all those changes was interrupted and is NOT VERIFIED on this release. Earlier port8061 refresh evidence applies to the earlier build. Do not claim final Web-save lifecycle complete. Actual mobile devices, audible listening, PWA installation/update lifecycle and sustained browser rendering FPS remain NOT TESTED.
