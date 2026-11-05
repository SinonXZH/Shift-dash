extends SceneTree
func _initialize() -> void:
	create_timer(6.0).timeout.connect(func(): quit(1))
	call_deferred("check_impacts")
func check_impacts() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.beat_audio.stop()
	game.tuning["disable_movement"] = true
	game.rhythm.bpm = 120
	game.rhythm.count_in_beats = 4
	game.rhythm.perfect_window = 0.1
	game.rhythm.good_window = 0.2
	for scenario in [[2, 2.15, true], [2, 2.0, false], [1, 2.15, false], [0, 2.4, false]]:
		for enemy in game.enemies:
			enemy.queue_free()
		game.enemies.clear()
		game.tuning["dash_mode"] = scenario[0]
		game.player.reset_at(Vector2(400, 400))
		game.rhythm.time = scenario[1]
		for x in [460, 580]:
			var enemy = load("res://scenes/actors/enemy.tscn").instantiate()
			game.current_room.get_node("Enemies").add_child(enemy)
			enemy.global_position = Vector2(x, 400)
			enemy.movement_disabled = true
			game.enemies.append(enemy)
		game.try_dash()
		game.player.dash_direction = Vector2.RIGHT
		game.tick_game(0.16)
		if scenario[2]:
			assert(is_equal_approx(game.player.active_dash_speed, 675.0))
			assert(game.player.global_position.x > 480 and game.player.global_position.x < 550)
			assert(game.enemies.size() == 1)
		else:
			assert(is_equal_approx(game.player.global_position.x, 640))
			assert(game.enemies.is_empty())
		game.player.cooldown = 0
		game.player.dash_left = 0
		game.rhythm.time = 3.15
		game.try_dash()
		assert(game.player.active_dash_speed >= 1500)
		await process_frame
	print("PASS: normal impact slows immediately within long frame; perfect and both archives retain speed; kills limited to actual path; next dash resets speed")
	game.queue_free()
	await process_frame
	quit()
