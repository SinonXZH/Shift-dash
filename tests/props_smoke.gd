extends SceneTree
func _initialize() -> void:
	create_timer(6.0).timeout.connect(func(): quit(1))
	call_deferred("check_props")
func check_props() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.start_run()
	game.beat_audio.stop()
	for enemy in game.enemies:
		enemy.queue_free()
	game.enemies.clear()
	game.tuning["disable_movement"] = true
	var wall = load("res://scenes/props/obstacle.tscn").instantiate()
	game.current_room.add_child(wall)
	wall.global_position = Vector2(500, 400)
	wall.size = Vector2(80, 160)
	await physics_frame
	await physics_frame
	game.player.global_position = Vector2(400, 400)
	game.rhythm.time = 2.0
	game.try_dash()
	game.player.dash_direction = Vector2.RIGHT
	game.tick_game(0.1)
	assert(game.player.global_position.x < 448 and game.player.global_position.x > 440)
	assert(game.player.dash_left == 0)
	var enemy = load("res://scenes/actors/enemy.tscn").instantiate()
	game.current_room.add_child(enemy)
	enemy.global_position = Vector2(430, 400)
	await physics_frame
	enemy.step(1.0, Vector2(800, 400), game.current_room.bounds(), game.tuning, 1)
	assert(enemy.global_position.x < 445)
	enemy.queue_free()
	game.bullets.clear()
	game.player.global_position = Vector2(700, 400)
	game.add_bullet(Vector2(400, 400), Vector2(2000, 0))
	game.tick_game(0.1)
	assert(game.bullets.is_empty())
	wall.queue_free()
	var hazard = load("res://scenes/props/hazard.tscn").instantiate()
	game.current_room.add_child(hazard)
	hazard.global_position = Vector2(500, 400)
	hazard.size = Vector2(16, 100)
	await physics_frame
	await physics_frame
	game.player.global_position = Vector2(400, 400)
	game.player.cooldown = 0
	game.player.dash_left = 0
	game.player.invulnerability = 0
	game.player.last_rewarded_beat = -INF
	game.rhythm.time = 2.0
	game.try_dash()
	game.player.dash_direction = Vector2.RIGHT
	var health: int = game.health
	game.tick_game(0.1)
	assert(game.health == health - 1)
	assert(game.player.global_position.x > 600)
	game.player.global_position = hazard.global_position
	game.tick_game(0.01)
	assert(game.health == health - 1)
	hazard.dash_can_pass_safely = true
	game.player.invulnerability = 0
	game.player.dash_protection_left = 0.1
	game.tick_game(0.01)
	assert(game.health == health - 1)
	game.player.dash_protection_left = 0
	game.tick_game(0.01)
	assert(game.health == health - 2)
	print("PASS: high-speed wall collision, enemies blocked, bullets blocked, swept hazard damage, hurt grace, optional dash immunity")
	game.queue_free()
	await process_frame
	quit()
