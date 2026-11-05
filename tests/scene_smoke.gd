extends SceneTree
func _initialize() -> void:
	create_timer(7.0).timeout.connect(func(): quit(1))
	call_deferred("check_scenes")
func check_scenes() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	for number in [1, 2, 3]:
		game.room = number
		game.spawn_room()
		game.beat_audio.stop()
		assert(game.enemies.size() == 4 + number * 2)
		assert(game.player.global_position == game.current_room.get_node("PlayerSpawn").global_position)
		assert(game.rhythm.section == number - 1)
		var first = game.enemies[0]
		first.kind = 1
		first.fire_left = 0
		game.tick_game(0.01)
		assert(not game.bullets.is_empty())
		game.player.rhythm.time = 2.0
		game.player.cooldown = 0
		game.player.dash_left = 0
		game.try_dash()
		assert(game.player.empowered_dash)
		game.player.step(0.02, game.current_room.bounds())
		game.queue_redraw()
		game.player.queue_redraw()
		await process_frame
		for enemy in game.enemies:
			enemy.queue_free()
		game.enemies.clear()
		game.player.dash_left = 0
		game.player.global_position = game.current_room.get_node("Exit").global_position + Vector2(30, 50)
		game.tick_game(0.01)
		if number < 3:
			assert(game.room == number + 1)
		else:
			assert(game.mode == "won")
	game.start_run()
	assert(game.enemies.size() == 6)
	game.open_settings()
	assert(game.mode == "settings")
	game.close_settings()
	assert(game.mode == "playing")
	game.queue_free()
	await process_frame
	var preview = load("res://scenes/rooms/room_02.tscn").instantiate()
	root.add_child(preview)
	current_scene = preview
	await process_frame
	await process_frame
	assert(current_scene != preview)
	assert(current_scene.room_scenes.size() == 1 and current_scene.enemies.size() == 8)
	print("PASS: authored counts/spawns, three room rhythms, shooter bullets, empowered dash, exits/win, restart/settings, F6 room preview")
	current_scene.queue_free()
	await process_frame
	quit()
