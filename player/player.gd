extends CharacterBody2D

@onready var camera = $Camera2D
@onready var animated_sprite = $AnimatedSprite2D

const SPEED = 120.0
const JUMP_VELOCITY = -350.0
var push_force = 25.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if is_multiplayer_authority():
		camera.make_current()
		animated_sprite.play("idle")

func _physics_process(delta):
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			animated_sprite.flip_h = direction < 0
			animated_sprite.play("walking")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			animated_sprite.play("idle")

		move_and_slide()

		# Handle collision with RigidBody2D
		for index in range(get_slide_collision_count()):
			var collision = get_slide_collision(index)
			if collision.get_collider() is RigidBody2D:
				var collider = collision.get_collider()
				var collision_normal = collision.get_normal()

				# Apply impulse to the RigidBody2D
				var impulse = -collision_normal * push_force
				collider.apply_central_impulse(impulse)



#Player Death

@rpc("any_peer")
func player_died(player_id):
	# Notify the level script about player death
	get_parent().rpc("player_died", player_id)
