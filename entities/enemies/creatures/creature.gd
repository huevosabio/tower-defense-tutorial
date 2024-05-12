class_name Creature
extends Enemy

@onready var sprite := $Sprite2D as Sprite2D

func _ready() -> void:
	var objective: Node2D = $/root/Map/Objective
	nav_agent.set_target_position(objective.global_position)
	nav_agent.max_speed = speed
	
	hud.health_bar.max_value = health
	hud.health_bar.value = health
	
	var shooter = get_shooter()
	if shooter:
		shooter.has_shot.connect(self._on_shooter_has_shot)


func _calculate_rot(start_rot: float, target_rot: float, _speed: float, delta: float) -> float:
	return lerp_angle(start_rot, target_rot, _speed * delta)

func set_textures(texture: Texture2D):
	sprite.texture = texture
	anim_sprite.sprite_frames = SpriteFrames.new()
	anim_sprite.sprite_frames.add_animation("die")
	anim_sprite.sprite_frames.add_animation("idle")
	anim_sprite.sprite_frames.add_animation("move")
	anim_sprite.sprite_frames.set_frame(
		"die", 0, texture
	)
	anim_sprite.sprite_frames.set_frame(
		"idle", 0, texture
	)
	anim_sprite.sprite_frames.set_frame(
		"move", 0, texture
	)
	anim_sprite.play("idle")

func _move(delta: float) -> void:
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var cur_agent_pos: Vector2 = global_position
	var new_velocity: Vector2 = cur_agent_pos.direction_to(next_path_pos) * speed
	if not nav_agent.avoidance_enabled:
		velocity = new_velocity
		move_and_slide()
	else:
		nav_agent.set_velocity(new_velocity)
	anim_sprite.global_rotation = _calculate_rot(anim_sprite.global_rotation,
			velocity.angle(), rot_speed, delta)
	collision_shape.global_rotation = _calculate_rot(collision_shape.global_rotation,
			velocity.angle(), rot_speed, delta)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

	
func set_health(value: int) -> void:
	health = max(0, value)
	if is_instance_valid(hud):
		hud.health_bar.value = health
	if health == 0:
		state_machine.transition_to("Die")


func get_shooter() -> Shooter:
	return null


func play_animation(anim_name: String) -> void:
	anim_sprite.play(anim_name)


func die() -> void:
	collision_shape.set_deferred("disabled", true)
	speed = 0
	nav_agent.set_velocity(Vector2.ZERO)
	anim_sprite.play("die")
	default_sound.stop()
	enemy_died.emit(self)


func _on_animated_sprite_2d_animation_finished():
	if anim_sprite.animation == "die":
		enemy_removed.emit()
		queue_free()


func _on_shooter_has_shot(reload_time):
	hud.animate_reload_bar(reload_time)
