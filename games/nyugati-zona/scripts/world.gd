extends Node3D
const Art=preload("res://scripts/art.gd")
const Thing=preload("res://scripts/thing.gd")
const Vehicle=preload("res://scripts/vehicle.gd")
const Zombie=preload("res://scripts/zombie.gd")
const Data=preload("res://scripts/data.gd")
var game:Node
var scenery:Node3D
var rng:RandomNumberGenerator=RandomNumberGenerator.new()
var navigation:AStarGrid2D=AStarGrid2D.new()
var footprints:Array[Rect2]=[]
func generate() -> void:
	rng.seed=20081012
	scenery=Node3D.new()
	scenery.name="Scenery"
	add_child(scenery)
	navigation.region=Rect2i(-170,-170,340,340)
	navigation.cell_size=Vector2(2,2)
	navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	Art.box(scenery,Vector3(0,-0.5,0),Vector3(1200,1,1200),Color("#72744c"),true)
	road(Vector3(0,0.016,0),Vector3(9,0.03,1000))
	road(Vector3(0,0.018,-94),Vector3(520,0.032,8),true)
	road(Vector3(0,0.017,150),Vector3(430,0.03,7),true)
	for side in [-1,1]:
		Art.box(scenery,Vector3(side*5.9,0.025,-4),Vector3(2.5,0.05,235),Color("#b3ad94"))
		for i in range(8):
			var z:float=62-i*22
			var p:Vector3=Vector3(side*22,0,z)
			house(p,-side*PI/2,Color(["c2b28f","bba783","c4bc9f","b4b59b"][i%4]),false)
			var loot_pos:Vector3=p+Vector3(side*1.7,0,1.3)
			spawn_thing("home_"+str(side)+"_"+str(i),"loot",loot_pos,{"pool":"home","name":"Háztartási készletek"})
			for j in range(5):
				var x:float=side*12
				Art.box(scenery,Vector3(x,0.55,z-8+j*0.95),Vector3(0.10,1.1,0.10),Color("#969079"),true)
			lamp_post(Vector3(side*6.8,0,z+7))
	# Starting shelter and clear early-game resources.
	bus_stop(Vector3(6.7,0,57))
	spawn_thing("start","loot",Vector3(8.2,0,55.5),{"pool":"start","name":"Hátrahagyott túrafelszerelés"})
	spawn_thing("starter_tools","loot",Vector3(11,0,42),{"pool":"forest","name":"Erdész szerszámosládája"})
	sign_board(scenery,Vector3(6.8,0,75),"BEREKFALVA",Color("#e4dcc4"))
	# Workyard on the right, police post on the left.
	house(Vector3(40,0,23),PI,Color("#b8ac91"),true)
	spawn_thing("garage_loot","loot",Vector3(40,0,23),{"pool":"garage","name":"Garázs alkatrészei"})
	spawn_thing("workbench","bench",Vector3(37,0,22))
	spawn_thing("workshop_loot","loot",Vector3(44,0,23),{"pool":"workshop","name":"Műhely készletei"})
	spawn_car("duna",Vector3(11,0,29),"hatch",PI,4,55,false)
	spawn_car("volna",Vector3(-8,0,-117),"sedan",0,12,80,true)
	house(Vector3(-40,0,-113),PI/2,Color("#a1aaa2"),true)
	sign_board(scenery,Vector3(-29,0,-109),"RENDŐRSÉG",Color("#31495e"))
	spawn_thing("police","loot",Vector3(-40,0,-113),{"pool":"police","name":"Rendőrségi fegyverszekrény"})
	gas_station(Vector3(43,0,-61))
	church(Vector3(-64,0,-45))
	panel_block(Vector3(-89,0,-152),5)
	panel_block(Vector3(-123,0,-159),4)
	# Recognisable old blue bus, static display vehicle.
	var bus:Node3D=Node3D.new()
	scenery.add_child(bus)
	bus.position=Vector3(10,0,-12)
	bus.rotation.y=0.14
	Art.car(bus,"bus",Color("#355a77"))
	Art.collider(bus,Vector3(0,1.45,0),Vector3(2.45,2.9,9.4))
	spawn_thing("bus_loot","loot",Vector3(12,0,-9),{"pool":"home","name":"Busz csomagtere"})
	# Forestry and farm.
	house(Vector3(-150,0,-150),0,Color("#918d6a"),true)
	sign_board(scenery,Vector3(-145,0,-141),"RÁBA-VÖLGYI ERDÉSZET",Color("#3f6248"))
	spawn_thing("forest_loot","loot",Vector3(-150,0,-148),{"pool":"forest","name":"Erdészeti készletek"})
	spawn_thing("forest_bench","bench",Vector3(-146,0,-150))
	house(Vector3(150,0,162),PI,Color("#a39d80"),true)
	sign_board(scenery,Vector3(144,0,151),"ARANYKALÁSZ MAJOR",Color("#ded5b6"))
	var tractor:Node3D=Node3D.new()
	scenery.add_child(tractor)
	tractor.position=Vector3(136,0,168)
	Art.car(tractor,"tractor",Color("#4c774b"))
	Art.collider(tractor,Vector3(0,1,0),Vector3(1.8,2.1,3.6))
	spawn_thing("farm","loot",Vector3(150,0,161),{"pool":"garage","name":"Mezőgazdasági alkatrészek"})
	for i in range(11):
		Art.box(scenery,Vector3(127+i*4,0.02,208),Vector3(1.8,0.04,72),Color("#62553c"))
		for j in range(8):
			Art.box(scenery,Vector3(127+i*4,0.5,181+j*8),Vector3(0.06,1,0.06),Color("#ae955b"))
	# Checkpoint.
	for side in [-1,1]:
		Art.box(scenery,Vector3(side*5,0.55,-230),Vector3(4,1.1,0.6),Color("#ada68f"),true)
	Art.box(scenery,Vector3(0,1.4,-229),Vector3(7,0.15,0.16),Color("#c7c6b0"))
	sign_board(scenery,Vector3(7,0,-221),"KARANTÉN  /  BELÉPNI TILOS",Color("#9d4337"))
	spawn_thing("military","loot",Vector3(9,0,-238),{"pool":"military","name":"Honvédségi utánpótlás"})
	for i in range(3):
		tent(Vector3(-13-i*7,0,-243))
	# Terrain identity, distant wooded ridges and reed pond.
	Art.cylinder(scenery,Vector3(250,-0.15,-160),58,0.12,Color("#667f78"),-1,24)
	for i in range(150):
		var theta:float=rng.randf()*TAU
		var radius:float=rng.randf_range(51,64)
		var p:Vector3=Vector3(250+cos(theta)*radius,0,-160+sin(theta)*radius)
		Art.box(scenery,p+Vector3(0,0.65,0),Vector3(0.06,1.3,0.06),Color("#999764"))
	for i in range(52):
		var p:Vector3=Vector3(rng.randf_range(-220,-72),0,rng.randf_range(-200,180))
		if not occupied(p,8):
			spawn_thing("tree_"+str(i),"tree",p,{"hp":128,"variant":i%5})
	for i in range(520):
		var p:Vector3=Vector3(rng.randf_range(-530,530),0,rng.randf_range(-530,530))
		if absf(p.x)<65 or absf(p.z+94)<12 or absf(p.z-150)<12 or occupied(p,10) or Vector2(p.x-250,p.z+160).length()<65:
			continue
		background_tree(p,rng.randf_range(0.8,1.7),i%3)
	for i in range(20):
		var theta:float=i*TAU/20
		var p:Vector3=Vector3(cos(theta)*750,-16,sin(theta)*750)
		Art.tapered(scenery,p,Vector3(260,100+rng.randf()*50,260),Color("#586858"),0.1)
	# Spatially placed infected; the spawn shelter stays safe.
	for i in range(34):
		var p:Vector3=Vector3(rng.randf_range(-55,55),0,rng.randf_range(-175,-25))
		if occupied(p,3):
			p.x=rng.randf_range(-4,4)
		spawn_zombie("z_"+str(i),p,i%5)
	for i in range(6):
		spawn_zombie("checkpoint_"+str(i),Vector3(rng.randf_range(-12,12),0,-236-rng.randf()*18),4)
	for footprint in footprints:
		var a:Vector2i=Vector2i((footprint.position/2).floor())
		var b:Vector2i=Vector2i((footprint.end/2).ceil())
		for x in range(a.x,b.x+1):
			for y in range(a.y,b.y+1):
				if navigation.is_in_boundsv(Vector2i(x,y)):
					navigation.set_point_solid(Vector2i(x,y),true)
	Art.bake_static(scenery)
func occupied(p:Vector3,margin:float=0) -> bool:
	for rect in footprints:
		if rect.grow(margin).has_point(Vector2(p.x,p.z)):
			return true
	return false
func path_to(from:Vector3,to:Vector3) -> PackedVector3Array:
	var a:Vector2i=Vector2i(roundi(from.x/2),roundi(from.z/2))
	var b:Vector2i=Vector2i(roundi(to.x/2),roundi(to.z/2))
	var result:PackedVector3Array=PackedVector3Array()
	if not navigation.is_in_boundsv(a) or not navigation.is_in_boundsv(b):
		return result
	if navigation.is_point_solid(a) or navigation.is_point_solid(b):
		return result
	for p in navigation.get_point_path(a,b,true):
		result.append(Vector3(p.x,0,p.y))
	if result.size()>0:
		result.remove_at(0)
	return result
func road(p:Vector3,s:Vector3,cross:bool=false) -> void:
	Art.box(scenery,p,s,Color("#555a55"))
	var length:float=s.x if cross else s.z
	for i in range(int(length/12)):
		var q:Vector3=p+Vector3(-length/2+i*12,0.022,0) if cross else p+Vector3(0,0.022,-length/2+i*12)
		Art.box(scenery,q,Vector3(4,0.01,0.13) if cross else Vector3(0.13,0.01,4),Color("#c4ba91"))
func house(p:Vector3,yaw:float,color:Color,garage:bool=false) -> void:
	var n:Node3D=Node3D.new()
	scenery.add_child(n)
	n.position=p
	n.rotation.y=yaw
	footprints.append(Rect2(Vector2(p.x-5,p.z-5),Vector2(10,10)))
	var wall:Color=color
	Art.box(n,Vector3(0,0.005,0),Vector3(8,0.01,8),Color("#9a8a6a"))
	Art.box(n,Vector3(0,1.55,-4),Vector3(8.2,3.1,0.20),wall,true)
	for x in [-4,4]:
		Art.box(n,Vector3(x,1.55,0),Vector3(0.2,3.1,8),wall,true)
	# Door gap and two distinct recessed windows.
	for x in [-2.35,2.35]:
		Art.box(n,Vector3(x,0.50,4),Vector3(3.3,1,0.20),wall,true)
		Art.box(n,Vector3(x,2.78,4),Vector3(3.3,0.64,0.20),wall,true)
		for dx in [-1.25,1.25]:
			Art.box(n,Vector3(x+dx,1.75,4),Vector3(0.8,1.5,0.2),wall,true)
		Art.box(n,Vector3(x,1.75,4.03),Vector3(1.55,1.35,0.035),Color("#506369"))
		Art.box(n,Vector3(x,1.75,4.06),Vector3(0.06,1.4,0.08),Color("#ddd5b6"))
	Art.box(n,Vector3(0,2.68,4),Vector3(1.4,0.84,0.2),wall,true)
	Art.roof(n,Vector3(0,3.1,0),9.1,9.1,2.6,Color("#905944") if not garage else Color("#645b4b"))
	Art.box(n,Vector3(1.8,4.7,-1.3),Vector3(0.62,2.1,0.58),Color("#baab8c"))
	# Period interior: cupboard, table, CRT television, LPG cylinder.
	Art.box(n,Vector3(-3.4,1,-2.4),Vector3(0.6,2,2.0),Color("#76553a"),true)
	Art.box(n,Vector3(1.1,0.78,-1.0),Vector3(1.6,0.1,0.9),Color("#bba479"),true)
	for x in [0.45,1.75]:
		for z in [-1.35,-0.65]:
			Art.box(n,Vector3(x,0.38,z),Vector3(0.075,0.76,0.075),Color("#796447"))
	Art.box(n,Vector3(2.7,0.52,-3.1),Vector3(1.2,1.04,0.6),Color("#816444"),true)
	Art.box(n,Vector3(2.7,1.31,-3.1),Vector3(0.83,0.53,0.5),Color("#3f443d"))
	Art.box(n,Vector3(2.65,1.33,-2.83),Vector3(0.57,0.39,0.025),Color("#6c7770"))
	Art.cylinder(n,Vector3(-3.4,0.43,2.9),0.25,0.80,Color("#a47858"),0.2)
	Art.box(n,Vector3(-3.4,0.88,2.9),Vector3(0.15,0.15,0.12),Color("#454c42"))
func sign_board(parent:Node3D,p:Vector3,words:String,color:Color) -> void:
	var n:Node3D=Node3D.new()
	parent.add_child(n)
	n.position=p
	Art.box(n,Vector3(0,1.1,0),Vector3(0.08,2.2,0.08),Color("#7a8174"))
	Art.box(n,Vector3(0,2.3,0),Vector3(3.9,0.85,0.12),color)
	Art.text3(n,words,Vector3(0,2.3,0.07),30,Color("#eae2cc") if color.v<0.7 else Color("#34433c"))
func lamp_post(p:Vector3) -> void:
	Art.box(scenery,p+Vector3(0,2.9,0),Vector3(0.14,5.8,0.14),Color("#6d7568"))
	Art.box(scenery,p+Vector3(-0.4,5.78,0),Vector3(1.0,0.12,0.12),Color("#6d7568"))
	Art.box(scenery,p+Vector3(-0.8,5.7,0),Vector3(0.40,0.12,0.28),Color("#dfbd78"),false,1.2)
func bus_stop(p:Vector3) -> void:
	var n:Node3D=Node3D.new()
	scenery.add_child(n)
	n.position=p
	for x in [-1.6,1.6]:
		Art.box(n,Vector3(x,1.2,0),Vector3(0.09,2.4,0.09),Color("#4f685d"),true)
	Art.box(n,Vector3(0,2.5,0),Vector3(3.8,0.18,2),Color("#8c6348"))
	Art.box(n,Vector3(0,0.48,0.2),Vector3(2.8,0.13,0.44),Color("#8c7551"))
	sign_board(n,Vector3(2.4,0,0),"MEGÁLLÓ",Color("#315c77"))
func church(p:Vector3) -> void:
	var n:Node3D=Node3D.new()
	scenery.add_child(n)
	n.position=p
	Art.box(n,Vector3(0,4,0),Vector3(11,8,21),Color("#c8c2ab"),true)
	Art.roof(n,Vector3(0,8,0),12,22,5,Color("#936044"))
	Art.box(n,Vector3(0,10,10),Vector3(5,20,5),Color("#c8c2ab"),true)
	Art.cylinder(n,Vector3(0,23,10),4,7,Color("#4d625c"),0,4).rotation.y=PI/4
	Art.box(n,Vector3(0,27.8,10),Vector3(0.16,2.2,0.16),Color("#3d4c44"))
	Art.box(n,Vector3(0,28.15,10),Vector3(1.0,0.15,0.16),Color("#3d4c44"))
	for y in [13,17]:
		Art.box(n,Vector3(0,y,12.52),Vector3(1.4,2.2,0.04),Color("#4a5854"))
	footprints.append(Rect2(Vector2(p.x-6,p.z-12),Vector2(12,27)))
func panel_block(p:Vector3,floors:int) -> void:
	Art.box(scenery,p+Vector3(0,floors*1.5,0),Vector3(23,floors*3,12),Color("#a8ad9f"),true)
	for y in range(floors):
		for x in range(9):
			Art.box(scenery,p+Vector3(-10+x*2.5,1.7+y*3,6.02),Vector3(1.2,1.5,0.04),Color("#4e6265"))
	footprints.append(Rect2(Vector2(p.x-12,p.z-7),Vector2(24,14)))
func gas_station(p:Vector3) -> void:
	Art.box(scenery,p+Vector3(0,0.012,0),Vector3(28,0.024,28),Color("#999b8d"))
	for x in [-8,8]:
		for z in [-5,5]:
			Art.box(scenery,p+Vector3(x,2.3,z),Vector3(0.22,4.6,0.22),Color("#b1b7a2"),true)
	Art.box(scenery,p+Vector3(0,4.7,0),Vector3(22,0.38,15),Color("#c8c9b5"))
	Art.box(scenery,p+Vector3(0,4.66,7.52),Vector3(22,0.46,0.06),Color("#3e745b"))
	Art.text3(scenery,"NYUGAT ÜZEMANYAG",p+Vector3(0,4.7,7.57),66)
	spawn_thing("pump","pump",p+Vector3(-3,0,0),{"liters":450})
	spawn_thing("pump2","pump",p+Vector3(3,0,0),{"liters":450})
	spawn_thing("station_gen","generator",p+Vector3(8,0,-7),{"fuel":0.0,"on":false})
	spawn_thing("station_loot","loot",p+Vector3(9,0,8),{"pool":"home","name":"Benzinkúti készletek"})
func tent(p:Vector3) -> void:
	Art.roof(scenery,p,5,7,2.7,Color("#5f6949"))
	Art.collider(scenery,p+Vector3(0,1,0),Vector3(4,2,6))
func background_tree(p:Vector3,s:float,variant:int) -> void:
	Art.cylinder(scenery,p+Vector3(0,1.5*s,0),0.16*s,3*s,Color("#716044"),0.10*s,5)
	for i in range(2):
		Art.cylinder(scenery,p+Vector3(0,(3.4+i)*s,0),(2.0-i*0.5)*s,3*s,Color("#536946") if variant%2 else Color("#697344"),0.1,6)
func spawn_thing(id:String,kind:String,p:Vector3,data:Dictionary={},yaw:float=0) -> Node:
	if game.things.has(id):
		return game.things[id]
	var t:Node=Thing.new()
	t.game=game
	t.uid=id
	t.kind=kind
	t.data=data.duplicate(true)
	t.position=p
	t.rotation.y=yaw
	add_child(t)
	game.things[id]=t
	return t
func spawn_car(id:String,p:Vector3,kind:String,yaw:float,gas:float,hp:float,has_battery:bool) -> void:
	var c:Node=Vehicle.new()
	c.game=game
	c.uid=id
	c.kind=kind
	c.position=p
	c.rotation.y=yaw
	c.fuel=gas
	c.condition=hp
	c.battery=has_battery
	add_child(c)
	game.vehicles[id]=c
func spawn_zombie(id:String,p:Vector3,variant:int) -> void:
	var z:Node=Zombie.new()
	z.game=game
	z.uid=id
	z.position=p
	z.variant=variant
	z.health=100+variant*12
	add_child(z)
	game.zombies[id]=z
