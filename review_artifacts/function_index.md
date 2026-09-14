# Current source function index

## core/aura/hero_aura.gd

- L9: `func tick(delta: float) -> void:`
- L20: `func update_membership() -> void:`
- L31: `func remove(unit) -> void:`
- L35: `func clear() -> void:`
- L41: `func _draw() -> void:`

## core/combat/combat_calculator.gd

- L4: `static func damage(attack: float, defense: float) -> float:`

## core/combat/combat_registry.gd

- L9: `func register(unit) -> void:`
- L13: `func unregister(unit) -> void:`
- L20: `func _insert(unit) -> void:`
- L26: `func rebuild() -> void:`
- L32: `func tick(delta: float, interval: float) -> void:`
- L38: `func nearby(x: float, radius: float, team: int) -> Array:`
- L49: `func find_target(source):`

## core/combat/projectile_pool.gd

- L8: `func setup(manager) -> void:`
- L13: `func launch(source, target, power: float) -> bool:`
- L26: `func has_capacity() -> bool:`
- L31: `func cancel_target(unit) -> void:`
- L37: `func clear() -> void:`
- L44: `func effect(at: Vector2, color: Color, radius: float) -> void:`
- L48: `func tick(delta: float) -> void:`
- L70: `func _draw() -> void:`

## core/hero/hero_controller.gd

- L4: `func move_hero(delta: float) -> void:`

## core/resource/battle_resources.gd

- L11: `func setup(equipment: Dictionary, battle_upgrades: Dictionary) -> void:`
- L17: `func tick(delta: float) -> void:`
- L25: `func spend_supply(cost: float) -> bool:`
- L32: `func spend_mana(cost: float) -> bool:`

## core/unit/boss_unit.gd

- L7: `func tick(delta: float) -> void:`

## core/unit/unit_base.gd

- L26: `func configure(data: Dictionary, side: int, manager, at: Vector2) -> void:`
- L41: `func stat(key: String) -> float:`
- L51: `func tick(delta: float) -> void:`
- L80: `func move_hero(_delta: float) -> void:`
- L83: `func edge_distance(other) -> float:`
- L86: `func attack(victim) -> void:`
- L111: `func take_damage(power: float) -> void:`
- L119: `func heal(amount: float) -> void:`
- L124: `func die() -> void:`
- L133: `func move_support(delta: float) -> void:`

## systems/audio_manager.gd

- L10: `func _ready() -> void:`
- L29: `func start_music() -> void:`
- L38: `func play(id: String) -> void:`
- L50: `func apply_settings() -> void:`
- L58: `func shutdown() -> void:`
- L67: `func _exit_tree() -> void:`

## systems/battle_manager.gd

- L35: `func _ready() -> void:`
- L81: `func _base_data(health: float) -> Dictionary:`
- L84: `func _spawn(data: Dictionary, team: int, x: float):`
- L100: `func team_count(team: int) -> int:`
- L107: `func summon(index: int) -> bool:`
- L124: `func spawn_enemy(id: String, x: float = -1.0):`
- L131: `func _physics_process(delta: float) -> void:`
- L134: `func simulate(delta: float) -> void:`
- L160: `func _unhandled_input(event: InputEvent) -> void:`
- L178: `func cast_skill(index: int) -> bool:`
- L211: `func area_attack(x: float, radius: float, power: float, team: int) -> void:`
- L216: `func effect(at: Vector2, color: Color, radius: float) -> void:`
- L219: `func announce(message: String) -> void:`
- L222: `func _on_death(unit) -> void:`
- L236: `func _check_battle_level() -> void:`
- L248: `func choose_upgrade(index: int) -> bool:`
- L258: `func finish(result: String) -> void:`
- L271: `func debug_command(command: String) -> void:`
- L288: `func _notification(what: int) -> void:`
- L295: `func _exit_tree() -> void:`

## systems/game_data.gd

- L11: `func _ready() -> void:`
- L20: `func _read(path: String) -> Variant:`
- L31: `func roster() -> Array:`
- L36: `func validate() -> void:`

## systems/save_manager.gd

- L11: `func _ready() -> void:`
- L14: `func defaults() -> Dictionary:`
- L17: `func load_game() -> bool:`
- L73: `func _read_save(path: String) -> Variant:`
- L90: `func migrate(data: Dictionary) -> Dictionary:`
- L97: `func save_game() -> bool:`
- L121: `func _fail(message: String) -> bool:`
- L126: `func reward_stage(stage: Dictionary) -> Dictionary:`
- L145: `func upgrade_unit(id: String) -> bool:`
- L154: `func equip(slot: String, id: String) -> bool:`
- L166: `func equipment_modifiers() -> Dictionary:`
- L178: `func _commit(before: Dictionary) -> bool:`
- L184: `func set_setting(key: String, value: Variant) -> bool:`

## systems/spawn_manager.gd

- L10: `func setup(manager) -> void:`
- L15: `func tick(delta: float) -> void:`

## systems/stage_manager.gd

- L4: `static func objective(stage: Dictionary) -> String:`
- L7: `static func result_for_death(stage: Dictionary, unit) -> String:`

## ui/action_button.gd

- L8: `func _ready() -> void:`
- L19: `func _input(event: InputEvent) -> void:`
- L38: `func _dispatch(pressed: bool) -> void:`
- L46: `func _notification(what: int) -> void:`

## ui/battle_hud.gd

- L19: `func _ready() -> void:`
- L90: `func _action(text: String, action: String, minimum: Vector2) -> ActionButton:`
- L97: `func _process(delta: float) -> void:`
- L105: `func _update() -> void:`
- L124: `func _build_overlay() -> void:`
- L143: `func _clear_overlay() -> void:`
- L149: `func show_pause(paused: bool) -> void:`
- L160: `func _offer_upgrade(choices: Array) -> void:`
- L168: `func _on_ended(result: String, reward: Dictionary) -> void:`
- L186: `func toggle_debug() -> void:`
- L201: `func _router():`

## ui/menu_screen.gd

- L8: `func _ready() -> void:`
- L27: `func _build() -> void:`
- L49: `func _main_menu() -> void:`
- L79: `func _scroll_grid(columns: int) -> GridContainer:`
- L90: `func _stages() -> void:`
- L103: `func _upgrades() -> void:`
- L121: `func _equipment() -> void:`
- L144: `func _settings() -> void:`
- L174: `func _router():`
- L177: `func _exit_tree() -> void:`

## ui/safe_margin.gd

- L4: `func _ready() -> void:`
- L8: `func _resize() -> void:`

## ui/ui_kit.gd

- L10: `static func style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 10) -> StyleBoxFlat:`
- L22: `static func theme() -> Theme:`
- L40: `static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:`
- L47: `static func button(text: String, callback: Callable, minimum: Vector2 = Vector2(160, 54)) -> Button:`
- L57: `static func panel() -> PanelContainer:`
- L62: `static func fill(control: Control) -> void:`
- L65: `static func spacer() -> Control:`

## scenes/boot/boot.gd

- L8: `func _ready() -> void:`
- L12: `func _clear() -> void:`
- L19: `func show_screen(id: String) -> void:`
- L25: `func start_battle(id: int) -> void:`
- L35: `func _build_orientation_notice() -> void:`
- L52: `func _orientation_changed() -> void:`

## platform/web/web_adapter.gd

- L4: `static func safe_margins(viewport_width: float) -> Array:`

## tests/audit_suite.gd

- L11: `func _initialize() -> void:`
- L14: `func begin(name: String, category: String) -> void:`
- L18: `func verify(condition: bool, description: String, evidence: Variant = "") -> void:`
- L23: `func fixture():`
- L32: `func dispose(b) -> void:`
- L36: `func run() -> void:`
- L62: `func aura_cycles() -> void:`
- L97: `func target_edges() -> void:`
- L129: `func combat_edges() -> void:`
- L171: `func projectile_lifecycle() -> void:`
- L195: `func resources_and_cooldowns() -> void:`
- L222: `func save_bad_values() -> void:`
- L248: `func content_and_equipment() -> void:`
- L273: `func performance_profile() -> void:`
- L298: `func save_transaction_failures() -> void:`
- L313: `func support_positioning() -> void:`

## tests/runtime_e2e.gd

- L20: `func _initialize() -> void:`
- L23: `func record(condition: bool, name: String, detail: Variant = "") -> void:`
- L28: `func run() -> void:`
- L98: `func enter_battle() -> void:`
- L109: `func _physics_process(_delta: float) -> bool:`
- L149: `func action(name: String) -> void:`
- L159: `func observe(b) -> void:`
- L187: `func send_touch(button, index: int, pressed: bool) -> void:`
- L194: `func click_text(text: String, required: bool = true) -> void:`
- L206: `func find_button(node, text: String, any: bool = false):`
- L213: `func find_sliders(node, result: Array) -> void:`
- L217: `func finish(id: String) -> void:`
- L230: `func run_boss_stages() -> void:`

## tests/save_probe.gd

- L3: `func _initialize() -> void:`
- L6: `func run() -> void:`

## tests/test_runner.gd

- L10: `func _initialize() -> void:`
- L14: `func check(condition: bool, name: String, detail: String = "") -> void:`
- L19: `func begin_case(name: String, category: String, real_scene: bool = true, real_save: bool = false) -> void:`
- L23: `func make_battle(stage_id: int = 1):`
- L31: `func step(battle,seconds: float) -> void:`
- L36: `func _run() -> void:`
- L176: `func restartart_status(battle) -> String:`
- L179: `func natural_stage_one() -> void:`
- L221: `func stress_test() -> void:`
- L244: `func ui_and_touch_test() -> void:`
- L323: `func campaign_test() -> void:`
- L366: `func find_button(node: Node, text: String):`
- L373: `func tap(button) -> void:`
- L389: `func extended_combat_test() -> void:`

## assets/visuals/battle_ground.gd

- L7: `func _draw() -> void:`

## assets/visuals/unit_visual.gd

- L7: `func _draw() -> void:`
- L79: `func _draw_gate(color: Color, dark: Color, light: Color) -> void:`
- L90: `func _box(color: Color) -> StyleBoxFlat:`