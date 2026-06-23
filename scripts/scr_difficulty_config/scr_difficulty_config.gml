// ══════════════════════════════════════════════════════════════════════════════════
// SCR_DIFFICULTY_CONFIG — Sistema global de dificultad
//
// PROPÓSITO: Centralizar todas las variables de dificultad en un solo lugar.
// Permite cambiar entre Fácil, Normal y Difícil sin hardcodes dispersos.
//
// VALORES ACTUALES:
//   - Normal: valores actuales del juego (Parry Window = 25, etc.)
//   - Fácil: parry más permisivo, enemigos lentos, recovery más rápida
//   - Difícil: player muere en 2 golpes, todo lo demás igual a normal
// ══════════════════════════════════════════════════════════════════════════════════

function scr_difficulty_config() {
	// ── Variable global de dificultad ──────────────────────────────────────
	// Valores posibles: "easy", "normal", "hard"
	// Se inicializa en Room Start (ver obj_time_manager)
	if (!variable_global_exists("difficulty")) {
		global.difficulty = "normal";
	}

	// ── NORMAL: valores actuales (BASE) ────────────────────────────────────
	global.config = {};
	global.config.normal = {
		// ─ PLAYER: Parry ─────────────────────────────────────────────
		parry_window_frames:         25,    // ventana perfecta al presionar block (frames reales)
		parry_slow_duration:         60,    // frames de slow-mo post-parry
		parry_stun_duration:         60,    // frames que el enemigo queda congelado tras parry
		parry_counter_window:        45,    // frames disponibles para contraataque
		parry_cooldown_max:          20,    // cooldown entre parries

		// ─ PLAYER: Damage & Recovery ─────────────────────────────────
		player_max_hp:               2,     // max HP (muere en 3 golpes con 1 HP/golpe actual)
		player_default_invuln:       90,    // frames de invulnerabilidad post-daño (~1.5s)
		player_hitstun:              20,    // frames de hitstun
		player_knockback_x:          24,    // empuje horizontal
		player_knockback_y:          -8,    // empuje vertical
		player_knockback_decay:      0.80,  // decay por frame
		damage_recovery_lock_duration: 90,  // frames que el player está bloqueado tras daño

		// ─ ENEMY: Multiplicadores de timing ──────────────────────────
		// Swordsman base: windup=30, cooldown=90
		// Archer base: aim_time=45, cooldown=90
		enemy_attack_windup_multiplier:   1.0,   // 1.0 = normal
		enemy_attack_cooldown_multiplier: 1.0,   // 1.0 = normal
		enemy_charge_time_multiplier:     1.0,   // 1.0 = normal (archer)
	};

	// ── FÁCIL: parry permisivo, enemigos lentos, recovery rápida ──────────
	global.config.easy = {
		// ─ PLAYER: Parry más permisivo ───────────────────────────────
		parry_window_frames:         ceil(global.config.normal.parry_window_frames * 1.5),    // 37
		parry_slow_duration:         ceil(global.config.normal.parry_slow_duration * 1.2),   // 72
		parry_stun_duration:         ceil(global.config.normal.parry_stun_duration * 1.3),   // 78
		parry_counter_window:        ceil(global.config.normal.parry_counter_window * 1.3),  // 58
		parry_cooldown_max:          ceil(global.config.normal.parry_cooldown_max * 0.8),    // 16

		// ─ PLAYER: Recovery más rápida ───────────────────────────────
		player_max_hp:               global.config.normal.player_max_hp,  // 2 (muere en 3 golpes)
		player_default_invuln:       ceil(global.config.normal.player_default_invuln * 0.65), // 58
		player_hitstun:              ceil(global.config.normal.player_hitstun * 0.75),        // 15
		player_knockback_x:          global.config.normal.player_knockback_x,
		player_knockback_y:          global.config.normal.player_knockback_y,
		player_knockback_decay:      global.config.normal.player_knockback_decay,
		damage_recovery_lock_duration: ceil(global.config.normal.damage_recovery_lock_duration * 0.65), // 58

		// ─ ENEMY: Enemigos más lentos ────────────────────────────────
		enemy_attack_windup_multiplier:   1.35,   // 35% más tiempo en windup
		enemy_attack_cooldown_multiplier: 1.25,   // 25% más cooldown
		enemy_charge_time_multiplier:     1.35,   // 35% más tiempo cargando (archer)
	};

	// ── DIFÍCIL: HP reducido, todo lo demás normal ──────────────────────
	global.config.hard = {
		// ─ PLAYER: Parry igual que normal ────────────────────────────
		parry_window_frames:         global.config.normal.parry_window_frames,
		parry_slow_duration:         global.config.normal.parry_slow_duration,
		parry_stun_duration:         global.config.normal.parry_stun_duration,
		parry_counter_window:        global.config.normal.parry_counter_window,
		parry_cooldown_max:          global.config.normal.parry_cooldown_max,

		// ─ PLAYER: HP reducido (menos que normal) ──────────────────────
		// Sistema: cada golpe enemigo hace 1 daño, hp <= 0 = muere
		// Normal (max_hp=2) → muere más rápido con max_hp=1
		// Hard debe ser menos dureza que normal → más difícil morir
		// NOTA: Si normal "muere en 3 golpes", hard con max_hp=1 "muere en 1 golpe"
		// Por eso hard tiene el mismo max_hp que normal por ahora
		player_max_hp:               1,     // max HP (muere más rápido que normal)
		player_default_invuln:       global.config.normal.player_default_invuln,
		player_hitstun:              global.config.normal.player_hitstun,
		player_knockback_x:          global.config.normal.player_knockback_x,
		player_knockback_y:          global.config.normal.player_knockback_y,
		player_knockback_decay:      global.config.normal.player_knockback_decay,
		damage_recovery_lock_duration: global.config.normal.damage_recovery_lock_duration,

		// ─ ENEMY: Enemigos iguales que normal ────────────────────────
		enemy_attack_windup_multiplier:   1.0,
		enemy_attack_cooldown_multiplier: 1.0,
		enemy_charge_time_multiplier:     1.0,
	};

	// ── Aplicar configuración actual ───────────────────────────────────────
	apply_current_difficulty_config();
}

/// @function apply_current_difficulty_config()
/// @description Aplica los valores de la dificultad actual a global.current_config
function apply_current_difficulty_config() {
	// Leer la dificultad actual y cargar la configuración correspondiente
	if (global.difficulty == "easy") {
		global.current_config = global.config.easy;
	} else if (global.difficulty == "hard") {
		global.current_config = global.config.hard;
	} else {
		global.current_config = global.config.normal;  // "normal" es el default
	}

	// Debug: mostrar que la configuración fue cargada
	if (variable_global_exists("debug_difficulty") && global.debug_difficulty) {
		show_debug_message("[DIFFICULTY] Configuración aplicada: " + global.difficulty);
		show_debug_message("  parry_window_frames: " + string(global.current_config.parry_window_frames));
		show_debug_message("  player_max_hp: " + string(global.current_config.player_max_hp));
		show_debug_message("  damage_recovery_lock: " + string(global.current_config.damage_recovery_lock_duration));
		show_debug_message("  enemy_windup_mult: " + string(global.current_config.enemy_attack_windup_multiplier));
	}
}

/// @function set_difficulty(_new_difficulty)
/// @description Cambia la dificultad a "easy", "normal" o "hard"
/// @param {string} _new_difficulty La dificultad nueva
function set_difficulty(_new_difficulty) {
	if (_new_difficulty == "easy" || _new_difficulty == "normal" || _new_difficulty == "hard") {
		global.difficulty = _new_difficulty;
		apply_current_difficulty_config();
		show_debug_message("[DIFFICULTY] Dificultad cambiada a: " + global.difficulty);
	} else {
		show_debug_message("[DIFFICULTY] ERROR: dificultad inválida '" + _new_difficulty + "' (usa: easy, normal, hard)");
	}
}

/// @function get_difficulty_string()
/// @description Retorna la dificultad actual como string legible
/// @return {string} "Easy", "Normal" o "Hard"
function get_difficulty_string() {
	switch (global.difficulty) {
		case "easy":   return "Easy";
		case "hard":   return "Hard";
		case "normal": return "Normal";
		default:       return "Unknown";
	}
}

/// @function apply_difficulty_to_existing_objects()
/// @description Aplica los valores de dificultad a objetos ya creados en la room
/// @details Esto permite cambiar dificultad en runtime sin resetear la room
function apply_difficulty_to_existing_objects() {
	// ── Actualizar player existente ──────────────────────────────────
	if (instance_exists(obj_player)) {
		with (obj_player) {
			// Parry
			parry_window_max = global.current_config.parry_window_frames;
			parry_slow_duration_max = global.current_config.parry_slow_duration;
			parry_cooldown_max = global.current_config.parry_cooldown_max;
			counter_window_max = global.current_config.parry_counter_window;

			// HP y invulnerabilidad
			max_hp = global.current_config.player_max_hp;
			// NO cambiar hp actual para no matar/curar instantáneamente
			default_invuln = global.current_config.player_default_invuln;
			default_hitstun = global.current_config.player_hitstun;
			damage_recovery_lock_duration = global.current_config.damage_recovery_lock_duration;

			// Knockback
			default_knockback_x = global.current_config.player_knockback_x;
			knockback_y_force = global.current_config.player_knockback_y;
			knockback_decay = global.current_config.player_knockback_decay;
		}
	}

	// ── Actualizar enemigos espadachín existentes ────────────────────
	if (instance_exists(obj_enemy_swordsman)) {
		with (obj_enemy_swordsman) {
			attack_windup = ceil(ESWORDSMAN_WINDUP * global.current_config.enemy_attack_windup_multiplier);
			attack_cooldown_max = ceil(ESWORDSMAN_COOLDOWN * global.current_config.enemy_attack_cooldown_multiplier);
		}
	}

	// ── Actualizar enemigos arquero existentes ───────────────────────
	if (instance_exists(obj_enemy_archer)) {
		with (obj_enemy_archer) {
			aim_charge_time = ceil(EARCHER_AIM_TIME * global.current_config.enemy_charge_time_multiplier);
			shoot_cooldown_max = ceil(EARCHER_SHOOT_COOLDOWN * global.current_config.enemy_attack_cooldown_multiplier);
		}
	}

	// ── Debug ────────────────────────────────────────────────────────
	show_debug_message("[APPLY-DIFFICULTY] Dificultad aplicada a objetos existentes");
}
