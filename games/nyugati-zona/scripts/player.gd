extends CharacterBody3D
const Art=preload("res://scripts/art.gd")
const Data=preload("res://scripts/data.gd")
var game:Node
var peer_id:int=1
var local:bool=false
var visual:Node3D
var pivot:Node3D
var camera:Camera3D
var view_weapon:Node3D
var light:SpotLight3D
var inventory:Dictionary={}
var health:float=100.0
var hunger:float=100.0
var thirst:float=100.0
var stamina:float=100.0
var equipment:String="hands"
var magazine:int=0
var rifle_magazine:int=0
var vehicle_id:String=""
var third_person:bool=true
var pitch:float=-0.10
var phase:float=0.0
var swing:float=0.0
var action_cooldown:float=0.0
var bleeding:float=0.0
var infection:float=0.0
var deaths:int=0
var mounted:bool=false
var remote_target:Vector3
var rendered_equipment:String="__unset__"
func _ready() -> void:
	collision_layer=2
	collision_mask=1
	var c:CollisionShape3D=CollisionShape3D.new()
	var s:CapsuleShape3D=CapsuleShape3D.new()
	s.radius=0.32
	s.height=1.85
	c.shape=s
	c.position.y=0.94
	add_child(c)
	visual=Art.character(self,false,peer_id%5)
	pivot=Node3D.new()
	pivot.position.y=1.62
	add_child(pivot)
	camera=Camera3D.new()
	camera.near=0.08
	camera.fov=78
	pivot.add_child(camera)
	camera.current=local
	light=SpotLight3D.new()
	light.light_color=Color("#ffdfaa")
	light.light_energy=3
	light.spot_range=32
	light.spot_angle=30
	light.visible=false
	camera.add_child(light)
	view_weapon=Node3D.new()
	view_weapon.position=Vector3(0.28,-0.26,-0.48)
	camera.add_child(view_weapon)
	update_equipment()
	remote_target=position
func capacity() -> float:
	return 35.0 if inventory.has("backpack") else 14.0
func is_alive() -> bool:
	return health>0
func update_equipment() -> void:
	if visual:
		visual.get_node("Gear").visible=inventory.has("backpack")
	if view_weapon and rendered_equipment!=equipment:
		rendered_equipment=equipment
		var hand:Node3D=visual.get_node("ArmR")
		var previous:Node=hand.get_node_or_null("HeldEquipment")
		if previous:
			hand.remove_child(previous)
			previous.queue_free()
		var held:Node3D=Node3D.new()
		held.name="HeldEquipment"
		hand.add_child(held)
		held.position=Vector3(0,-0.52,0)
		if equipment in ["pistol","rifle"]:
			held.rotation.x=1.1
			Art.weapon(held,equipment=="rifle")
		elif equipment=="axe":
			Art.box(held,Vector3(0,0.02,-0.16),Vector3(0.05,0.05,0.56),Color("#926945"))
			Art.box(held,Vector3(0,0.04,-0.40),Vector3(0.045,0.22,0.16),Color("#969e92"))
		for c in view_weapon.get_children():
			c.queue_free()
		if equipment in ["pistol","rifle"]:
			Art.weapon(view_weapon,equipment=="rifle")
		elif equipment=="axe":
			Art.box(view_weapon,Vector3(0,-0.10,0),Vector3(0.05,0.45,0.06),Color("#926945"))
			Art.box(view_weapon,Vector3(0,0.13,-0.08),Vector3(0.045,0.14,0.26),Color("#969e92"))
func _unhandled_input(event:InputEvent) -> void:
	if not local or not game.playing or game.ui.is_open():
		return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*float(game.settings.values.sensitivity))
		pitch=clampf(pitch-event.relative.y*float(game.settings.values.sensitivity),-1.20,1.1)
	if event.is_action_pressed("view"):
		third_person=not third_person
	if event.is_action_pressed("flashlight"):
		light.visible=not light.visible
func _physics_process(delta:float) -> void:
	action_cooldown=maxf(0,action_cooldown-delta)
	swing=maxf(0,swing-delta)
	if not local:
		if not game.authoritative():
			position=position.lerp(remote_target,minf(1.0,delta*12))
		phase+=delta*5
		Art.animate_character(visual,phase,0.3 if position.distance_to(remote_target)>0.07 else 0.0)
		pose_arms()
		return
	if not game.playing:
		return
	var enabled:bool=not game.ui.is_open() and is_alive()
	if vehicle_id!="" and game.vehicles.has(vehicle_id):
		var car:Node=game.vehicles[vehicle_id]
		global_position=car.global_position+Vector3(0,1.25,0)
		if enabled:
			var drive:Vector2=Input.get_vector("left","right","back","forward")
			game.set_drive_input(drive,Input.is_action_pressed("jump"))
		else:
			game.set_drive_input(Vector2.ZERO,true)
		visual.visible=false
		camera.position=Vector3(0,1.2,6.8)
		pivot.rotation.x=pitch-0.1
		view_weapon.visible=false
		return
	var input:Vector2=Input.get_vector("left","right","forward","back") if enabled else Vector2.ZERO
	var direction:Vector3=(basis*Vector3(input.x,0,input.y)).normalized()
	var crouch:bool=enabled and Input.is_action_pressed("crouch")
	var sprint:bool=enabled and Input.is_action_pressed("sprint") and stamina>3 and not crouch
	var speed:float=6.8 if sprint else (2.0 if crouch else 4.2)
	if Data.mass(inventory)>capacity()*0.85:
		speed*=0.78
	if mounted:
		speed*=0.65
		sprint=false
	velocity.x=move_toward(velocity.x,direction.x*speed,delta*22)
	velocity.z=move_toward(velocity.z,direction.z*speed,delta*22)
	velocity.y-=20*delta
	if is_on_floor() and enabled and Input.is_action_just_pressed("jump") and not crouch and not mounted:
		velocity.y=6.0
	move_and_slide()
	position.x=clampf(position.x,-590,590)
	position.z=clampf(position.z,-590,590)
	if position.y<-10:
		position=Vector3(5,2,55)
	stamina=clampf(stamina+delta*(-12.0 if sprint and input.length()>0.1 else 8.0),0,100)
	pivot.position.y=lerpf(pivot.position.y,1.12 if crouch else 1.62,delta*12)
	pivot.rotation.x=pitch
	var desired:Vector3=Vector3(0.53,0.2,3.5) if third_person else Vector3.ZERO
	if third_person:
		var end:Vector3=pivot.to_global(desired)
		var q:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(pivot.global_position,end,1)
		var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			desired=pivot.to_local(hit.position)+(pivot.to_local(pivot.global_position)-pivot.to_local(hit.position)).normalized()*0.2
	camera.position=desired
	visual.visible=third_person
	view_weapon.visible=not third_person and not mounted
	phase+=delta*Vector2(velocity.x,velocity.z).length()*2.6
	Art.animate_character(visual,phase,minf(0.6,Vector2(velocity.x,velocity.z).length()*0.1))
	pose_arms()
	camera.fov=lerpf(camera.fov,float(game.settings.values.fov)*(0.75 if enabled and Input.is_action_pressed("aim") else 1.0),delta*8)
func survival_tick(delta:float) -> void:
	if not is_alive():
		return
	hunger=maxf(0,hunger-delta*0.022)
	thirst=maxf(0,thirst-delta*0.036)
	if hunger<=0 or thirst<=0:
		health=maxf(0,health-delta*0.7)
	health=maxf(0,health-bleeding*delta*0.12)
func hit(amount:float) -> void:
	if not is_alive():
		return
	health=maxf(0,health-amount)
	if amount>=8:
		bleeding=minf(3,bleeding+0.25)
func ray(max_distance:float=4.5) -> Dictionary:
	var start:Vector3=camera.global_position
	var end:Vector3=start-camera.global_basis.z*max_distance
	var q:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(start,end,1|4)
	q.exclude=[get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q)
func pack_state() -> Dictionary:
	return {"id":peer_id,"p":[position.x,position.y,position.z],"yaw":rotation.y,"health":health,"hunger":hunger,"thirst":thirst,"stamina":stamina,"bleeding":bleeding,"inventory":inventory,"equipment":equipment,"magazine":magazine,"rifle_magazine":rifle_magazine,"vehicle":vehicle_id,"deaths":deaths}

func pose_arms() -> void:
	if equipment in ["pistol","rifle"]:
		visual.get_node("ArmR").rotation.x=-1.1-swing
		visual.get_node("ArmL").rotation.x=-1.0 if equipment=="rifle" else -0.35
	elif swing>0:
		visual.get_node("ArmR").rotation.x=-sin(swing/0.24*PI)*1.8
	view_weapon.rotation.x=-swing*1.4
