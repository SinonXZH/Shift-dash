extends SceneTree
func _initialize() -> void:
	create_timer(5.0).timeout.connect(func(): quit(1))
	call_deferred("check_modes")
func check_modes() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.beat_audio.stop()
	game.rhythm.bpm = 120
	game.rhythm.count_in_beats = 4
	game.rhythm.perfect_window = 0.1
	game.rhythm.good_window = 0.2
	for mode in [0, 1, 2]:
		game.tuning["dash_mode"] = mode
		for sample in [[2.4, false, false], [2.15, true, false], [2.05, true, true]]:
			game.player.reset_at(Vector2(400, 400))
			game.player.invulnerability = 0
			game.rhythm.time = sample[0]
			game.player.try_dash()
			var allowed: bool = mode == 0 or sample[1]
			assert((game.player.dash_left > 0) == allowed)
			var burst: bool = sample[1] if mode == 0 else sample[2]
			assert(game.player.empowered_dash == burst)
			if not allowed:
				assert(game.player.cooldown == 0 and game.player.dash_protection_left == 0)
				assert(game.player.global_position == Vector2(400, 400))
			else:
				assert(is_equal_approx(game.player.active_dash_speed, game.tuning["dash_speed"] * (game.tuning["onbeat_speed"] if burst else 1)))
	game.player.reset_at(Vector2(400, 400))
	game.tuning["dash_mode"] = 1
	game.rhythm.time = 2.15
	game.player.try_dash()
	game.player.dash_left = 0
	game.player.cooldown = 0
	game.rhythm.time = 2.17
	game.player.try_dash()
	assert(game.player.dash_left == 0 and game.player.rhythm_feedback == "本拍已使用")
	game.open_settings()
	game.settings.dash_mode.select(0)
	game.settings.apply_values()
	assert(game.tuning["dash_mode"] == 0)
	var saved := ConfigFile.new()
	assert(saved.load("user://debug_settings.cfg") == OK)
	assert(saved.get_value("tuning", "dash_mode") == 0)
	game.settings.reset_fields()
	assert(game.settings.dash_mode.get_selected_id() == 2)
	game.close_settings()
	game.update_ui()
	print("PASS: both modes x three timing grades, miss consumes nothing, duplicate beat blocked, mode UI/save/default")
	game.queue_free()
	await process_frame
	quit()
