extends Node2D

@export var spawn_points: Array[Vector2] = [Vector2(100, 200), Vector2(800, 200)]
@export var player_scene: PackedScene

@onready var animation_player = $Platforms/PlatformAnimation

var checkpoint_position = null

func _ready():
	load_checkpoint()
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_player_connected)
		_spawn_player(1)  # Spawn the host player with peer_id 1

	# Animations
	# Check if the current peer is the server (host) and has multiplayer authority
	if is_multiplayer_authority():
		# Start playing the animation automatically on the host
		animation_player.play("platform")

func _on_player_connected(peer_id):
	if multiplayer.is_server():
		_spawn_player(peer_id)

func _spawn_player(peer_id):
	var spawn_point = get_spawn_point(peer_id)
	rpc("_spawn_player_remotely", peer_id, spawn_point)


@rpc("call_local")
func _spawn_player_remotely(peer_id, spawn_point):
	# Load the checkpoint position
	var checkpoint_position = load_checkpoint()
	var player = player_scene.instantiate()
	
	var offset = Vector2.ZERO
	if peer_id != 1:  # Apply offset to players other than peer ID 1
		offset = Vector2(50, 0)
	
	if checkpoint_position:
		player.position = checkpoint_position + offset
	else:
		player.position = spawn_point + offset
	
	player.name = str(peer_id)
	player.add_to_group("player")
	add_child(player)

func get_spawn_point(peer_id):
	var peer_index = peer_id - 1
	var spawn_point = spawn_points[peer_index % spawn_points.size()]
	
	# Offset the spawn point for players other than peer ID 1
	if peer_id != 1:
		spawn_point += Vector2(100, 0)  # Adjust the offset as needed
	
	return spawn_point


func _on_door_1_trigger_body_entered(body):
	$DoorNodes/DoorAnimation.play("door1")
	$DoorNodes/Door1Trigger.visible = false

func _on_checkpoint_body_entered(body):
	if body.is_in_group("player"):
		var position = body.position
		save_checkpoint(position)

#func _on_death_zone_body_entered(body):
	#if body.is_in_group("player"):
		#var peer_id = int(str(body.name))
		#var spawn_point = get_spawn_point(peer_id)
		#body.position = spawn_point
		#



func save_checkpoint(position):
	# Save the checkpoint position
	checkpoint_position = position
	var file_path = "user://checkpoint.save"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file != null:
		file.store_var(checkpoint_position)
		print("Checkpoint saved successfully.")
		file.close()
	else:
		print("Error opening checkpoint file for writing.")

func load_checkpoint():
	# Load the checkpoint position
	var file_path = "user://checkpoint.save"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file != null:
			var status = file.get_error()
			if status == OK:
				checkpoint_position = file.get_var()
				print("Checkpoint loaded successfully. Position: ", checkpoint_position)
			else:
				print("Error reading checkpoint file: ", status)
			file.close()
		else:
			print("Error opening checkpoint file for reading.")
	else:
		print("Checkpoint file does not exist.")

	# Return the loaded checkpoint position or null if it couldn't be loaded
	return checkpoint_position






#Player Death Code
func _on_death_area_body_entered(body):
	if body.is_in_group("player"):
		print("death")
		var player_id = int(str(body.name))
		body.rpc("player_died", player_id)
		
@rpc("any_peer", "call_local")
func player_died(player_id):
	# Respawn both players at the last checkpoint or spawn points
	var checkpoint_position = load_checkpoint()
	for player in get_tree().get_nodes_in_group("player"):
		var peer_id = int(str(player.name))
		var spawn_point = get_spawn_point(peer_id)
		
		var offset = Vector2.ZERO
		if peer_id != 1:  # Apply offset to players other than peer ID 1
			offset = Vector2(100, 0)  # Adjust the offset as needed
		
		if player.is_multiplayer_authority():
			if checkpoint_position:
				player.position = checkpoint_position + offset
			else:
				player.position = spawn_point + offset
		else:
			player.rpc("respawn_player", checkpoint_position, spawn_point, offset)

@rpc("any_peer", "call_local")
func respawn_player(checkpoint_position, spawn_point, offset):
	if checkpoint_position:
		position = checkpoint_position + offset
	else:
		position = spawn_point + offset
