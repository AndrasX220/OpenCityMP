extends CharacterBody3D
const Art=preload("res://scripts/art.gd")
var game:Node
var uid:String=""
var variant:int=0
var health:float=100
var visual:Node3D
var home_position:Vector3
var goal:Vector3
var target_id:int=0
var think:float=0
var attack_delay:float=0
var phase:float=0
var alerted:float=0
var dead_shown:bool=false
var remote_target:Vector3
var path:PackedVector3Array=PackedVector3Array()
func _ready() -> void:
	collision_layer=4
	collision_mask=1
	var c:CollisionShape3D=CollisionShape3D.new()
	var s:CapsuleShape3D=CapsuleShape3D.new()
	s.radius=0.35
	s.height=1.8
	c.shape=s
	c.position.y=0.9
	add_child(c)
	visual=Art.character(self,true,variant)
	home_position=position
	goal=position
	remote_target=position
	think=float(variant)*0.12
func _physics_process(delta:float) -> void:
	if not game.playing:
		return
	if health<=0:
		if not dead_shown:
			dead_shown=true
			collision_layer=0
			create_tween().tween_property(visual,"rotation:z",1.5,0.4)
		return
	if not game.authoritative():
		var moving:float=position.distance_to(remote_target)
		position=position.lerp(remote_target,minf(1,delta*10))
		phase+=delta*6
		Art.animate_character(visual,phase,0.45 if moving>0.08 else 0.0,true)
		return
	think-=delta
	attack_delay=maxf(0,attack_delay-delta)
	alerted=maxf(0,alerted-delta)
	if think<=0:
		think=0.7
		var nearest:float=45
		target_id=0
		for p in game.players.values():
			if not p.is_alive():
				continue
			var dist:float=position.distance_to(p.position)
			if dist<nearest:
				var q:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(position+Vector3.UP*1.4,p.position+Vector3.UP*1.4,1)
				var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
				if hit.is_empty():
					nearest=dist
					target_id=p.peer_id
		if target_id>0:
			goal=game.players[target_id].position
		elif alerted<=0 and position.distance_to(goal)<1.5:
			goal=home_position+Vector3(randf_range(-7,7),0,randf_range(-7,7))
		path=game.world.path_to(position,goal)
	var destination:Vector3=goal
	if path.size()>0:
		destination=path[0]
		if Vector2(position.x,position.z).distance_to(Vector2(destination.x,destination.z))<1.0:
			path.remove_at(0)
	var to_goal:Vector3=destination-position
	to_goal.y=0
	var speed:float=3.8 if variant==1 else 2.3
	if target_id==0:
		speed=1.1 if alerted<=0 else 2.0
	var dir:Vector3=to_goal.normalized() if to_goal.length()>0.7 else Vector3.ZERO
	# Short-range obstacle steering complements the village A* grid.
	if dir.length()>0.1:
		var q:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(position+Vector3.UP*0.7,position+Vector3.UP*0.7+dir*1.1,1)
		var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			dir=dir.rotated(Vector3.UP,PI/2)
		rotation.y=lerp_angle(rotation.y,atan2(-dir.x,-dir.z),delta*5)
	velocity.x=dir.x*speed
	velocity.z=dir.z*speed
	velocity.y-=20*delta
	move_and_slide()
	if target_id>0:
		var p:Node=game.players[target_id]
		if position.distance_to(p.position)<1.65 and attack_delay<=0:
			p.hit(8+variant*2)
			attack_delay=1.3
			game.sound_event("hurt",position)
	phase+=delta*speed*2.7
	Art.animate_character(visual,phase,0.45 if dir.length()>0.1 else 0.0,true)
func hear(at:Vector3,radius:float) -> void:
	if health>0 and position.distance_to(at)<radius:
		goal=at
		alerted=15
func hit(damage:float) -> void:
	health=maxf(0,health-damage)
	alerted=15
func pack_state() -> Dictionary:
	return {"id":uid,"p":[position.x,position.y,position.z],"yaw":rotation.y,"health":health}
