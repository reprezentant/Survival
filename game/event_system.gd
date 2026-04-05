extends Node


signal BUL_create_bulletin
signal BUL_destroy_bulletin
signal BUL_destroy_all_bulletins

signal STA_change_stage

signal INV_try_to_pickup_item
signal INV_ask_update_inventory
signal INV_inventory_updated
signal INV_hotbar_updated
signal INV_switch_two_inventory_item_indexes
signal INV_add_item_to_inventory
signal INV_add_item_ack
signal INV_delete_blueprint_costs_from_inventory
signal INV_delete_item_count
signal INV_delete_item_by_index
signal INV_delete_all_items_by_index
signal INV_add_item_by_index
signal INV_drop_item_to_world

signal PLA_freeze_player
signal PLA_unfreeze_player
signal PLA_change_energy
signal PLA_energy_updated
signal PLA_change_health
signal PLA_health_updated
signal PLA_player_sleep

signal EQU_delete_equipped_item
signal EQU_hotkey_pressed
signal EQU_equip_item
signal EQU_unequip_item
signal EQU_active_hotbar_slot_updated

signal SPA_spawn_scene
signal SPA_spawn_vfx

signal SFX_play_sfx
signal SFX_play_dynamic_sfx

signal MUS_play_music

signal GAM_fast_forward_day_night_anim
signal GAM_game_fade_in
signal GAM_game_fade_out
signal GAM_update_navmesh

signal HUD_hide_hud
signal HUD_show_hud

signal SET_music_volume_changed
signal SET_sfx_volume_changed
signal SET_res_scale_changed
signal SET_ssaa_changed
signal SET_fullscreen_changed
signal SET_ask_settings_resource
signal SET_save_settings
signal SET_save_game
signal SET_load_game

signal JOU_ask_state
signal JOU_state_updated
signal JOU_discover
signal JOU_test
signal JOU_entry_read


func connect_once(signal_name: String, target: Callable) -> void:
	# Callable should be a Callable(self, "method_name") or a bound Callable.
	# Defensive: handle null/malformed targets and prefer passing the Callable
	# directly to is_connected (Godot expects a Callable there).
	if target == null:
		push_warning("connect_once: provided callable is null for signal '%s'" % [signal_name])
		return

	if typeof(target) != TYPE_CALLABLE:
		push_warning("connect_once: target is not a Callable: %s" % [str(target)])
		return

	if not has_signal(signal_name):
		push_warning("connect_once: signal '%s' does not exist on EventSystem" % [signal_name])
		return

	# Try to obtain object+method from Callable and use the object+method form of
	# is_connected(signal, object, method) which is the safe API here.
	var tgt_obj = null
	var tgt_method = null
	# obtain object/method from callable
	tgt_obj = target.get_object()
	tgt_method = target.get_method()

	# Prefer is_connected with the Callable if available (target validated earlier)
	# This avoids passing raw Objects into is_connected.
	if typeof(target) == TYPE_CALLABLE:
		if is_connected(signal_name, target):
			return

	# Fallback: iterate explicit connection list and compare both target object and method name
	var conns := get_signal_connection_list(signal_name)
	for c in conns:
		if typeof(c) != TYPE_DICTIONARY:
			continue

		var conn_target = c.get("target", null)
		var conn_method = c.get("method", null)

		# If both object+method are known, match them. If only method known, match method only.
		if tgt_obj != null and conn_target == tgt_obj and str(conn_method) == str(tgt_method):
			return
		elif tgt_obj == null and tgt_method != null and str(conn_method) == str(tgt_method):
			return

	connect(signal_name, target)
