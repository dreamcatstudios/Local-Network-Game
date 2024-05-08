extends CharacterBody2D

@onready var camera = $Camera2D
@onready var ground_ray = $GroundRay
@onready var animated_sprite = $AnimatedSprite

# Movement variables
@export var jump_force = 400
@export var max_speed = 200
@export var acceleration = 1000
@export var friction = 800
@export var gravity = 800
@export var coyote_time = 0.1

# Push force for rigid bodies
@export var push_force = 80.0

var coyote_timer = 0
var direction = 0
var jump_pressed = false
var jump_released = false

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if is_multiplayer_authority():
		camera.make_current()
	animated_sprite.play("idle")  # Add this line to play the "idle" animation by default

func _physics_process(delta):
	if is_multiplayer_authority():
		# Get input
		direction = Input.get_axis("ui_left", "ui_right")
		jump_pressed = Input.is_action_just_pressed("jump")
		jump_released = Input.is_action_just_released("jump")

		# Apply gravity
		velocity.y += gravity * delta

		# Handle horizontal movement
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
			animated_sprite.flip_h = direction < 0
			animated_sprite.play("walking")
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			animated_sprite.play("idle")

		# Handle jumping
		if ground_ray.is_colliding():
			coyote_timer = coyote_time
		else:
			coyote_timer -= delta

		if jump_pressed and coyote_timer > 0:
			velocity.y = -jump_force
			coyote_timer = 0
		elif jump_released and velocity.y < 0:
			velocity.y *= 0.5

		# Apply movement
		move_and_slide()

		# Interact with rigid bodies
		#for i in get_slide_collision_count():
		#	var c = get_slide_collision(i)
		#	if c.get_collider() is RigidBody2D:
		#		c.get_collider().apply_central_impulse(-c.get_normal() * push_force)
