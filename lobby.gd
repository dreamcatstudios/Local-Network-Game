# Main.gd
extends Control

var peer = ENetMultiplayerPeer.new()
var max_players = 2

@onready var address_line_edit = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/BootOptions/ConnectAddress
@onready var port_line_edit = $HBoxContainer/PanelContainer/MarginContainer/VBoxContainer/BootOptions/PortNumber

var ip_address
var level_instance

func _ready():
	var get_ip_address = IP.get_local_addresses()
	ip_address = get_local_ip_address(get_ip_address)
	address_line_edit.text = ip_address

func _on_host_pressed():
	var port = int(port_line_edit.text)
	peer.create_server(port, max_players)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_player_connected)
	level_instance = get_tree().change_scene_to_file("res://levels/level1/level_1.tscn")

func _on_join_pressed():
	var address = address_line_edit.text
	var port = int(port_line_edit.text)
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	level_instance = get_tree().change_scene_to_file("res://levels/level1/level_1.tscn")

func _on_player_connected(peer_id):
	print("Player connected: ", peer_id)
	if multiplayer.get_peers().size() >= max_players:
		print("Maximum player limit reached. Cannot add more players.")
		return

	if multiplayer.is_server():
		_spawn_player(peer_id)

func _spawn_player(peer_id):
	var spawn_point = get_spawn_point(peer_id)
	rpc("_spawn_player_remotely", peer_id, spawn_point)

func get_spawn_point(peer_id):
	var peer_index = peer_id - 1
	return level_instance.spawn_points[peer_index % level_instance.spawn_points.size()]

func get_local_ip_address(ip_addresses):
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.16.") or ip.begins_with("172.17.") or ip.begins_with("172.18.") or ip.begins_with("172.19.") or ip.begins_with("172.20.") or ip.begins_with("172.21.") or ip.begins_with("172.22.") or ip.begins_with("172.23.") or ip.begins_with("172.24.") or ip.begins_with("172.25.") or ip.begins_with("172.26.") or ip.begins_with("172.27.") or ip.begins_with("172.28.") or ip.begins_with("172.29.") or ip.begins_with("172.30.") or ip.begins_with("172.31."):
			return ip
	return ""
