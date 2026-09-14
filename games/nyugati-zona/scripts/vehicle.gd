extends CharacterBody3D
const Art=preload("res://scripts/art.gd")
var game:Node
var uid:String=""
var kind:String="hatch"
var fuel:float=4
var condition:float=55
var battery:bool=false
var driver:int=0
var speed:float=0
var drive_input:Vector2=Vector2.ZERO
var brake:bool=false
var visual:Node3D
var lamps:Array[SpotLight3D]=[]
var cargo:Dictionary={}
var network_position:Vector3
var network_yaw:float=0
func _ready() -> void:
	collision_layer=1
	collision_mask=1
	visual=Art.car(self,kind,Color("#a93930") if kind=="hatch" else Color("#aa9c70"))
	var c:CollisionShape3D=CollisionShape3D.new()
	var s:BoxShape3D=BoxShape3D.new()
	s.size=Vector3(1.65,1.76,3.7)
	c.shape=s
	c.position.y=0.90
	add_child(c)
	for x in [-0.57,0.57]:
		var l:SpotLight3D=SpotLight3D.new()
		l.position=Vector3(x,0.96,-1.9)
		l.light_color=Color("#ffe1a4")
		l.spot_range=40
		l.spot_angle=28
		l.light_energy=2.8
		l.visible=false
		add_child(l)
		lamps.append(l)
	network_position=position
	network_yaw=rotation.y
func _physics_process(delta:float) -> void:
	if not game.playing:
		return
	if not game.authoritative():
		position=position.lerp(network_position,minf(1.0,delta*12))
		rotation.y=lerp_angle(rotation.y,network_yaw,minf(1,delta*12))
	else:
		if driver>0 and battery and condition>0 and fuel>0:
			var acceleration:float=drive_input.y*8.0
			speed=clampf(speed+acceleration*delta,-7,27.0*(0.5+condition/200.0))
			fuel=maxf(0,fuel-delta*(0.002+absf(speed)*0.00015))
		else:
			speed=move_toward(speed,0,delta*4)
		if absf(drive_input.y)<0.01 or brake:
			speed=move_toward(speed,0,delta*(15.0 if brake else 2.2))
		rotation.y-=drive_input.x*speed*0.035*delta
		velocity=-basis.z*speed
		velocity.y=-2.0
		var old:Vector3=velocity
		move_and_slide()
		if get_slide_collision_count()>0:
			for i in range(get_slide_collision_count()):
				var hit:KinematicCollision3D=get_slide_collision(i)
				if absf(hit.get_normal().y)<0.7 and absf(speed)>2:
					condition=maxf(0,condition-absf(old.length())*0.03)
					speed*=0.55
					break
		position.x=clampf(position.x,-585,585)
		position.z=clampf(position.z,-585,585)
		if driver>0:
			for z in game.zombies.values():
				if z.health>0 and global_position.distance_to(z.global_position)<2.2 and absf(speed)>4:
					z.hit(absf(speed)*5)
					condition=maxf(0,condition-0.3)
	for l in lamps:
		l.visible=driver>0 and battery
	for c in visual.get_children():
		if str(c.name).begins_with("Wheel"):
			c.rotation.x-=speed*delta/0.32
func title() -> String:
	return "%s · %.0f%% · %.1f L · %s" % ["Duna S13" if kind=="hatch" else "Volna 210",condition,fuel,"akku rendben" if battery else "AKKU HIÁNYZIK"]
func pack_state() -> Dictionary:
	return {"id":uid,"p":[position.x,position.y,position.z],"yaw":rotation.y,"fuel":fuel,"condition":condition,"battery":battery,"driver":driver,"speed":speed,"cargo":cargo.duplicate()}
