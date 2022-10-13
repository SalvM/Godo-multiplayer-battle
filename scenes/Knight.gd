extends "res://scripts/Fighter.gd"

onready var playerLabel = $HUD2/Label
onready var healthBar = $HUD/HealthBar
onready var staminaBar = $HUD/StaminaBar
onready var dashBar = $HUD/DashBar
onready var SFX = $SFX

const swoosh = preload("res://assets/swoosh_3.mp3")
const plate_armor = preload("res://assets/plate_armor.mp3")

var player_state

func set_health(value):
	if value == health:
		return
	var prev_health = health
	health = clamp(value, 0, max_health)
	var new_health_percentage = health_in_percentage(health) if health > 0 else 0
	if new_health_percentage == 0:
		faint()
		return
	healthBar.set_value(new_health_percentage)

func set_stamina(value):
	if value == stamina:
		return
	var prev_stamina = stamina
	stamina = clamp(value, 0, max_stamina)
	var new_stamina_percentage = stamina_in_percentage(stamina) if stamina > 0 else 0
	staminaBar.set_value(new_stamina_percentage)

func set_dashes(value):
	if value == dashes:
		return
	dashes = clamp(value, 0, max_dashes)
	dashBar.set_value(dashes)

func set_player_name():
	playerLabel.text = fighter_name
	
func consumeStamina(amount):
	set_stamina(stamina - amount)

func faint():
	.faint()
	hurtBox.get_node("Collision").set_deferred("disabled", true)
	hitBox.get_node("Collision").set_deferred("disabled", true)
	$HUD.hide()
	$HUD2.hide()
	if is_enemy:
		return
	send_player_state()

func move_puppet(coordinates: Vector2):
	position.x = coordinates.x
	position.y = coordinates.y

func _on_AnimationPlayer_animation_finished(anim):
	if is_enemy:
		return
	._on_AnimationPlayer_animation_finished(anim)

func _on_StaminaTimer_timeout():
	._on_StaminaTimer_timeout()

func _on_DashTimer_timeout():
	speed_bonus = 1.0
	dash.stop()

func send_player_state():
	player_state = {
		"T": Server.client_clock,
		"P": get_global_position(),
		"S": current_state,
		"L": is_looking_left,
		#"B": [health, stamina, dashes] # bars
	}
	Server.send_player_state(player_state)

func play_sound(_sound):
	SFX.stream = _sound
	SFX.play()

func play_swoosh():
	play_sound(swoosh)
	
func play_plate_armor():
	play_sound(plate_armor)

func _on_ready():
	hitBox.get_node("Collision").disabled = true
	$HUD2/Label.text = fighter_name
	if is_enemy:
		set_physics_process(false)
		return
	$StaminaTimer.start()
	$DashRegenTimer.start()

func _on_physics_process(delta):
	if is_enemy:
		return
	._on_physics_process(delta)
	send_player_state()

func _on_input(event):
	if is_enemy:
		return
	._on_input(event)

func _on_process(event):
	if is_enemy:
		return
	._on_process(event)

func _on_HurtBox_area_entered(area):
	if is_enemy:
		return
	# Check type of damage and the ID of the player who attacked
	Server.fetch_player_damage()
	changeAnimation("HURT")

func _on_DashRegenTimer_timeout():
	set_dashes(dashes + 1)
