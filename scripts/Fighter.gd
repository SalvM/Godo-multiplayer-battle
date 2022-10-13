extends KinematicBody2D
"""
This is a base class for all the Fighter in a battle scenario.
"""

# Constants
enum State {
	IDLE, MOVE, JUMP, FALL, HURT, QUICK_ATTACK,
	CHARGED_ATTACK, DASH, FAINT, ROLL
}

# 2D space
var movement = Vector2(0, 0)
var speed = 200

# Statistics
export (String) var fighter_name = ""
export (int) var max_health = 100
export (int) var health = 100 setget set_health
export (int) var max_stamina = 80
export (int) var stamina = 80 setget set_stamina
export (int) var max_dashes = 3
export (int) var dashes = 3 setget set_dashes

var stamina_regeneration = 8
var basic_attack_cost = 20
var current_state = State.IDLE
var is_looking_left = false
var speed_bonus = 1.0
var is_enemy = false

# Combo
export (float) var timeTillNextInput = 0.2
var inputCooldown = timeTillNextInput
var usedKeys = ""
var wasInputMode = false

# Instances
onready var hitBox = $HitBox
onready var hurtBox = $HurtBox
onready var animationPlayer = $AnimationPlayer
onready var sprite = $Sprite
onready var collision = $Collision
onready var dash = $Dash

# Dash
var dash_duration = 0.1
var can_dash = true

func start_dash():
	if is_dashing():
		return
	if dashes < 1:
		return
	set_dashes(dashes - 1)
	dash.wait_time = dash_duration
	dash.start()
	speed_bonus = 6
	changeAnimation("DASH")

func is_dashing():
	return !dash.is_stopped()

func health_in_percentage(value) -> float:
	return float(value) / max_health * 100

func stamina_in_percentage(value) -> float:
	return float(value) / max_stamina * 100

func faint():
	changeAnimation("FAINT")
	#collision.disabled = true
	yield(animationPlayer, "animation_finished")

func consumeStamina(amount):
	set_stamina(stamina - amount)

func set_health(value):
	health = clamp(value, 0, max_health)
	if health == 0:
		faint()

func set_stamina(value):
	stamina = clamp(value, 0, max_stamina)

func set_dashes(value):
	dashes = clamp(value, 0, max_dashes)

func changeAnimation(type):
	if not animationPlayer.has_animation(type):
		return
	if animationPlayer.current_animation == type:
		return
	if animationPlayer.current_animation in ["HURT"]:
		yield(animationPlayer, "animation_finished")
	animationPlayer.play(type)
	current_state = State[type.to_upper()]

func isAttacking():
	return [State.QUICK_ATTACK, State.CHARGED_ATTACK].has(current_state)

func isFainted():
	return current_state == State.FAINT

func canAttack():
	return Input.is_action_just_pressed("Attack") && stamina >= basic_attack_cost && is_on_floor()

# Executes the right animation for the character input
func attack(character):
	consumeStamina(basic_attack_cost)
	match character:
		"M":
			changeAnimation("CHARGED_ATTACK")
		"L":
			changeAnimation("QUICK_ATTACK")

func flipHero():
	is_looking_left = !is_looking_left;
	sprite.scale.x = -sprite.scale.x
	hitBox.scale.x = -hitBox.scale.x
	hurtBox.scale.x = -hurtBox.scale.x

func move():
	if Input.is_action_pressed("ui_left"):
		if !is_looking_left:
			flipHero()
		movement.x = -speed * speed_bonus
		changeAnimation('MOVE')
	elif Input.is_action_pressed("ui_right"):
		if is_looking_left:
			flipHero()
		movement.x = speed * speed_bonus
		changeAnimation('MOVE')
	elif Input.is_action_pressed("ui_down"):
		movement.x = 0
		changeAnimation("CROUCH")
	else:
		movement.x = 0
		changeAnimation('IDLE')

	movement.y += 30
	if !is_on_floor():
		changeAnimation("JUMP" if movement.y < 0 else "FALL")
	elif Input.is_action_just_pressed("Dash"):
		start_dash()
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		movement.y = -660

	movement = move_and_slide(movement, Vector2.UP)

func _on_ready():
	pass

func _on_input(event):
	if isAttacking() || isFainted(): return
	# Sign an input key only once
	if event is InputEventKey:
		if event.pressed and not event.echo:
			# Temporarily stores the char from the input
			var character = OS.get_scancode_string(event.scancode)

			# Check if the character is valid for the combo
			if ["L","M"].find(character) >= 0:
				wasInputMode = true
				inputCooldown = timeTillNextInput
				usedKeys += character
				if canAttack():
					attack(character)

func _on_process(delta):
	if wasInputMode:
		inputCooldown -= delta
		if inputCooldown < 0 && usedKeys != null:
			wasInputMode = false
			inputCooldown = timeTillNextInput

func _on_physics_process(delta):
	if isAttacking() || isFainted(): return
	move()

func _ready():
	_on_ready()
	
func _input(event):
	_on_input(event)

func _process(delta):
	_on_process(delta)

func _physics_process(delta):
	_on_physics_process(delta)

func _on_AnimationPlayer_animation_finished(anim_name):
	if isAttacking() || anim_name == "DASH":
		changeAnimation("IDLE")

func _on_StaminaTimer_timeout():
	consumeStamina(-stamina_regeneration)
	#printt('stamina', stamina)
