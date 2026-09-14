extends Node
# Small LAN prototype. Server owns items, zombies, fuel, damage and buildings.
# Player locomotion uses client prediction with server displacement limits.
var game:Node
var online:bool=false
var snapshot_clock:float=0
var last_packet:Dictionary={}
var last_action:Dictionary={}
var pending_world:bool=false
const PORT:int=27808
func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_joined)
	multiplayer.peer_disconnected.connect(_peer_left)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(_failed)
	multiplayer.server_disconnected.connect(_failed)
func host() -> Error:
	var peer:ENetMultiplayerPeer=ENetMultiplayerPeer.new()
	var err:Error=peer.create_server(PORT,7)
	if err!=OK:return err
	multiplayer.multiplayer_peer=peer
	online=true
	return OK
func join(address:String) -> Error:
	var peer:ENetMultiplayerPeer=ENetMultiplayerPeer.new()
	var err:Error=peer.create_client(address,PORT)
	if err!=OK:return err
	multiplayer.multiplayer_peer=peer
	online=true
	return OK
func stop() -> void:
	online=false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	last_packet.clear()
	last_action.clear()
func _peer_joined(id:int) -> void:
	if not multiplayer.is_server():return
	game.add_player(id,false)
	pending_world=true
func _peer_left(id:int) -> void:
	if game.players.has(id):
		game.release_vehicle(game.players[id])
		game.players[id].queue_free()
		game.players.erase(id)
	last_packet.erase(id)
	last_action.erase(id)
	if multiplayer.is_server():pending_world=true
func _connected() -> void:
	game.begin_client(multiplayer.get_unique_id())
	ready_for_world.rpc_id(1)
func _failed() -> void:
	stop()
	game.return_to_menu()
	game.ui.toast("A kapcsolat megszakadt vagy nem jött létre.")
@rpc("any_peer","call_remote","reliable")
func ready_for_world() -> void:
	if not multiplayer.is_server():return
	var id:int=multiplayer.get_remote_sender_id()
	if game.players.has(id):
		world_state.rpc_id(id,game.pack_world())
@rpc("any_peer","call_remote","unreliable_ordered",1)
func motion(p:Array,yaw:float,pitch:float,drive:Vector2,brake:bool) -> void:
	if not multiplayer.is_server():return
	var id:int=multiplayer.get_remote_sender_id()
	if not game.players.has(id) or p.size()!=3:return
	for n in p:
		if not (n is float or n is int) or not is_finite(float(n)):return
	if not is_finite(yaw) or not is_finite(pitch):return
	var player:Node=game.players[id]
	var now:float=Time.get_ticks_msec()*0.001
	var dt:float=clampf(now-float(last_packet.get(id,now-0.05)),0.016,0.3)
	last_packet[id]=now
	var target:Vector3=Vector3(float(p[0]),float(p[1]),float(p[2]))
	if player.vehicle_id=="" and player.is_alive():
		if target.distance_to(player.position)<=maxf(1.4,dt*10) and absf(target.x)<=590 and absf(target.z)<=590 and target.y>=-2 and target.y<=80:
			player.position=target
			player.remote_target=target
		else:
			correct_position.rpc_id(id,[player.position.x,player.position.y,player.position.z])
	player.rotation.y=yaw
	player.pitch=clampf(pitch,-1.2,1.1)
	if player.vehicle_id!="" and game.vehicles.has(player.vehicle_id):
		var car:Node=game.vehicles[player.vehicle_id]
		car.drive_input=Vector2(clampf(drive.x,-1,1),clampf(drive.y,-1,1)) if is_finite(drive.x) and is_finite(drive.y) else Vector2.ZERO
		car.brake=brake
@rpc("authority","call_remote","reliable")
func correct_position(p:Array) -> void:
	if game.local_player:
		game.local_player.position=Vector3(p[0],p[1],p[2])
@rpc("any_peer","call_remote","reliable")
func action(kind:String,payload:Dictionary) -> void:
	if not multiplayer.is_server():return
	var id:int=multiplayer.get_remote_sender_id()
	var now:int=Time.get_ticks_msec()
	if now-int(last_action.get(id,0))<65:return
	last_action[id]=now
	if payload.size()>10:return
	game.execute_action(id,kind,payload)
@rpc("authority","call_remote","reliable")
func feedback(kind:String,message:String) -> void:
	game.receive_feedback(kind,message)
@rpc("authority","call_remote","reliable")
func world_state(state:Dictionary) -> void:
	game.apply_world(state)
@rpc("authority","call_remote","unreliable_ordered",2)
func snapshot(state:Dictionary) -> void:
	game.apply_snapshot(state)
func _process(delta:float) -> void:
	if not online or not game.playing:return
	snapshot_clock+=delta
	if snapshot_clock<0.1:return
	snapshot_clock=0
	if multiplayer.is_server():
		for id in game.players:
			if id==1:continue
			var p:Node=game.players[id]
			if p.vehicle_id!="" and game.vehicles.has(p.vehicle_id) and Time.get_ticks_msec()*0.001-float(last_packet.get(id,0))>0.5:
				game.vehicles[p.vehicle_id].drive_input=Vector2.ZERO
				game.vehicles[p.vehicle_id].brake=true
		var state:Dictionary=game.pack_snapshot()
		# Keep ordinary unreliable packets below the typical MTU.
		for player_state in state.players:
			snapshot.rpc({"players":[player_state],"hour":state.hour})
		for vehicle_state in state.vehicles:
			snapshot.rpc({"vehicles":[vehicle_state]})
		for offset in range(0,state.zombies.size(),4):
			snapshot.rpc({"zombies":state.zombies.slice(offset,offset+4)})
		if pending_world:
			world_state.rpc(game.pack_world())
			pending_world=false
	else:
		var p:Node=game.local_player
		if p and multiplayer.multiplayer_peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:
			motion.rpc_id(1,[p.position.x,p.position.y,p.position.z],p.rotation.y,p.pitch,game.drive_input,game.drive_brake)
