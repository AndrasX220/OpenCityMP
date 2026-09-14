extends Node3D
const Art=preload("res://scripts/art.gd")
const Data=preload("res://scripts/data.gd")
const Player=preload("res://scripts/player.gd")
const World=preload("res://scripts/world.gd")
const Atmosphere=preload("res://scripts/atmosphere.gd")
const Settings=preload("res://scripts/settings.gd")
const Net=preload("res://scripts/network.gd")
const UI=preload("res://scripts/ui.gd")
const Sound=preload("res://scripts/audio.gd")
var world:Node3D
var atmosphere:Node3D
var settings:RefCounted
var net:Node
var ui:CanvasLayer
var audio:Node
var players:Dictionary={}
var things:Dictionary={}
var vehicles:Dictionary={}
var zombies:Dictionary={}
var local_player:Node
var playing:bool=false
var title_camera:Camera3D
var builds:Array=[]
var build_root:Node3D
var build_mode:bool=false
var build_index:int=0
var build_yaw:float=0
var preview:MeshInstance3D
var preview_valid:bool=false
var preview_position:Vector3
var drive_input:Vector2=Vector2.ZERO
var drive_brake:bool=false
var auto_save:float=0
var event_clock:float=0
var initial_state:Dictionary={}
var recent_deaths:Dictionary={}
var death_processed:Dictionary={}
var loading_state:bool=false
func _ready() -> void:
	name="NyugatiZona"
	setup_inputs()
	settings=Settings.new()
	settings.load_settings()
	net=Net.new()
	net.name="Network"
	net.game=self
	add_child(net)
	atmosphere=Atmosphere.new()
	add_child(atmosphere)
	world=World.new()
	world.name="World"
	world.game=self
	add_child(world)
	build_root=Node3D.new()
	build_root.name="Buildings"
	add_child(build_root)
	world.generate()
	for t in things.values():
		if t.kind=="loot":
			var items:Dictionary={}
			for entry in Data.LOOT.get(t.data.get("pool","home"),[]):
				items[entry[0]]=entry[1]
			t.data["items"]=items
	audio=Sound.new()
	add_child(audio)
	title_camera=Camera3D.new()
	title_camera.position=Vector3(26,10,79)
	add_child(title_camera)
	title_camera.look_at(Vector3(0,4,-44))
	title_camera.current=true
	add_player(1,true)
	local_player.camera.current=false
	local_player.visible=false
	ui=UI.new()
	ui.game=self
	add_child(ui)
	settings.apply(self)
	initial_state=pack_world().duplicate(true)
	if "--smoke-test" in OS.get_cmdline_user_args():
		call_deferred("smoke_test")
	elif "--render-test" in OS.get_cmdline_user_args():
		call_deferred("render_test")
	elif "--lan-host-test" in OS.get_cmdline_user_args():
		call_deferred("lan_host_test")
	elif "--lan-client-test" in OS.get_cmdline_user_args():
		call_deferred("lan_client_test")
func authoritative() -> bool:
	return not net.online or multiplayer.is_server()
func setup_inputs() -> void:
	var keys:Dictionary={
		"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,
		"jump":KEY_SPACE,"sprint":KEY_SHIFT,"crouch":KEY_CTRL,"interact":KEY_E,
		"inventory":KEY_TAB,"craft":KEY_C,"map":KEY_M,"pause":KEY_ESCAPE,
		"view":KEY_V,"flashlight":KEY_F,"reload":KEY_R,"build":KEY_B,
		"build_next":KEY_Q,"build_rotate":KEY_T,"drop_log":KEY_G,
		"save":KEY_F5,"equip_1":KEY_1,"equip_2":KEY_2,"equip_3":KEY_3,"equip_4":KEY_4}
	for id in keys:
		if not InputMap.has_action(id):InputMap.add_action(id)
		var e:InputEventKey=InputEventKey.new()
		e.physical_keycode=keys[id]
		InputMap.action_add_event(id,e)
	for pair in [["attack",MOUSE_BUTTON_LEFT],["aim",MOUSE_BUTTON_RIGHT]]:
		if not InputMap.has_action(pair[0]):InputMap.add_action(pair[0])
		var e:InputEventMouseButton=InputEventMouseButton.new()
		e.button_index=pair[1]
		InputMap.action_add_event(pair[0],e)
func add_player(id:int,is_local:bool) -> Node:
	if players.has(id):
		return players[id]
	var p:Node=Player.new()
	p.game=self
	p.peer_id=id
	p.local=is_local
	p.name="Player_"+str(id)
	p.position=Vector3(5+(id%4)*1.2,0.2,57)
	add_child(p)
	players[id]=p
	if is_local:local_player=p
	return p
func reset_world() -> void:
	build_mode=false
	drive_input=Vector2.ZERO
	drive_brake=false
	death_processed.clear()
	recent_deaths.clear()
	apply_world(initial_state.duplicate(true),true)
	for id in players.keys():
		if id!=1:
			players[id].queue_free()
			players.erase(id)
	local_player=players[1]
	local_player.local=true
	local_player.vehicle_id=""
	local_player.position=Vector3(6.2,0.2,57)
	local_player.velocity=Vector3.ZERO
	local_player.health=100
	local_player.hunger=100
	local_player.thirst=100
	local_player.bleeding=0
	local_player.inventory={}
	local_player.magazine=0
	local_player.rifle_magazine=0
	local_player.equipment="hands"
	local_player.update_equipment()
func start_solo(resume:bool) -> void:
	net.stop()
	reset_world()
	if resume:load_game()
	begin_play()
func start_host() -> void:
	net.stop()
	reset_world()
	var err:Error=net.host()
	if err!=OK:
		ui.toast("Nem indítható a szerver: "+error_string(err))
		return
	begin_play()
	ui.toast("A fogadó szerver elindult · UDP 27808")
func join_host(address:String) -> void:
	net.stop()
	var err:Error=net.join(address)
	if err!=OK:
		ui.toast("Csatlakozási hiba: "+error_string(err))
	else:
		ui.toast("Kapcsolódás…")
func begin_client(id:int) -> void:
	for p in players.values():
		p.queue_free()
	players.clear()
	local_player=null
	add_player(id,true)
	begin_play()
func begin_play() -> void:
	playing=true
	local_player.visible=true
	local_player.camera.current=true
	settings.apply(self)
	ui.close()
	auto_save=0
func return_to_menu() -> void:
	get_tree().paused=false
	if authoritative() and playing:save_game()
	net.stop()
	playing=false
	build_mode=false
	if preview:preview.visible=false
	title_camera.current=true
	ui.show_main()
func _process(delta:float) -> void:
	if not playing:return
	if authoritative():
		for p in players.values():
			p.survival_tick(delta)
			if p.health<=0 and not death_processed.has(p.peer_id):
				handle_death(p)
		for t in things.values():
			if t.kind=="generator" and t.data.get("on",false):
				t.data.fuel=maxf(0,float(t.data.get("fuel",0))-delta*0.75/3600.0)
				if t.data.fuel<=0:
					t.data.on=false
					mark_world()
		event_clock+=delta
		if event_clock>1.0:
			event_clock=0
			power_update()
			for car in vehicles.values():
				if car.driver>0:make_noise(car.position,40)
			for t in things.values():
				if t.kind=="generator" and t.data.get("on",false):make_noise(t.position,35)
		auto_save+=delta
		if auto_save>120:
			auto_save=0
			save_game()
	if build_mode and local_player and not ui.is_open():
		update_preview()
func _unhandled_input(event:InputEvent) -> void:
	if not playing or not local_player or ui.is_open():return
	if event.is_action_pressed("interact"):
		if local_player.vehicle_id!="":
			request("exit",{})
			return
		var object:Node=focus()
		if object:
			if object is CharacterBody3D and object.get("uid")!=null and vehicles.has(object.uid):
				ui.show_vehicle(object.uid)
			else:
				request("interact",{"id":object.uid})
	if event.is_action_pressed("attack"):
		if build_mode:
			if preview_valid:
				request("build",{"kind":Data.BUILD.keys()[build_index],"p":vec_pack(preview_position),"yaw":build_yaw})
		elif local_player.vehicle_id=="":
			var hit:Dictionary=local_player.ray(220)
			var at:Vector3=hit.position if not hit.is_empty() else local_player.camera.global_position-local_player.camera.global_basis.z*220
			request("attack",{"target":vec_pack(at)})
	if event.is_action_pressed("reload"):request("reload",{})
	if event.is_action_pressed("build"):toggle_build()
	if event.is_action_pressed("build_next") and build_mode:
		build_index=(build_index+1)%Data.BUILD.size()
	if event.is_action_pressed("build_rotate") and build_mode:
		build_yaw=fposmod(build_yaw+PI/4,TAU)
	if event.is_action_pressed("drop_log"):request("drop_log",{})
	if event.is_action_pressed("save"):save_game()
	for i in range(1,5):
		if event.is_action_pressed("equip_"+str(i)):
			request("equip",{"item":["hands","axe","pistol","rifle"][i-1]})
func focus() -> Node:
	if not local_player:return null
	var hit:Dictionary=local_player.ray(8.5)
	if hit.is_empty():return null
	var n:Node=hit.collider
	while n and n!=world:
		if n.get("uid")!=null:
			if local_player.position.distance_to(n.global_position)<=5:
				return n
		n=n.get_parent()
	return null
func interaction_prompt() -> String:
	if local_player.mounted:return "RÖNK A VÁLLON · [G] LERAKÁS · VIDD A MUNKAPADHOZ"
	var n:Node=focus()
	if n and n.has_method("title"):
		return "[E]  "+str(n.title())
	return ""
func request(action:String,payload:Dictionary) -> void:
	if authoritative():
		execute_action(local_player.peer_id,action,payload)
	else:
		net.action.rpc_id(1,action,payload)
func tell(id:int,message:String,kind:String="toast") -> void:
	if local_player and id==local_player.peer_id:
		receive_feedback(kind,message)
	elif net.online and multiplayer.is_server():
		net.feedback.rpc_id(id,kind,message)
func receive_feedback(kind:String,message:String) -> void:
	match kind:
		"container":ui.show_inventory(message)
		"craft":ui.show_craft()
		_:ui.toast(message)
func mark_world() -> void:
	net.pending_world=true
func valid_near(p:Node,id:String,distance:float=5.0) -> Node:
	var n:Node=things.get(id,vehicles.get(id,null))
	if n and is_instance_valid(n) and p.position.distance_to(n.global_position)<=distance:
		return n
	return null
func near_bench(p:Node) -> bool:
	for t in things.values():
		if t.kind=="bench" and p.position.distance_to(t.global_position)<4:
			return true
	return false
func add_item(p:Node,id:String,amount:int) -> bool:
	if not Data.ITEMS.has(id) or amount<=0:return false
	var copy:Dictionary=p.inventory.duplicate()
	copy[id]=int(copy.get(id,0))+amount
	var limit:float=35 if copy.has("backpack") else 14
	if Data.mass(copy)>limit:return false
	p.inventory=copy
	p.update_equipment()
	return true
func execute_action(id:int,action:String,payload:Dictionary) -> void:
	if not authoritative() or not players.has(id) or not playing:return
	var p:Node=players[id]
	if action=="respawn":
		if p.health<=0:respawn(p)
		return
	if not p.is_alive():return
	var item:String=str(payload.get("item",""))
	var target_id:String=str(payload.get("id",""))
	var target:Node=valid_near(p,target_id)
	match action:
		"equip","use":
			if item in ["hands","axe","pistol","rifle"]:
				if item!="hands" and not p.inventory.has(item):
					tell(id,"Nincs nálad ilyen felszerelés.")
					return
				p.equipment=item
				p.update_equipment()
			elif action=="use" and p.inventory.has(item):
				match item:
					"water":p.thirst=minf(100,p.thirst+40)
					"beans":p.hunger=minf(100,p.hunger+35)
					"bandage":p.health=minf(100,p.health+20); p.bleeding=0
					_:return
				p.inventory=Data.paid(p.inventory,{item:1})
				sound_event("pickup",p.position)
		"interact":
			if not target:return
			match target.kind:
				"loot","crate":
					if target.data.get("taken",false):return
					tell(id,target.uid,"container")
				"door":target.data.open=not target.data.get("open",false); target.refresh()
				"bench":
					if p.mounted:
						if add_item(p,"wood",4):
							p.mounted=false
							update_carried_log(p)
							tell(id,"Rönk felfűrészelve: 4 deszka.")
					else:tell(id,"","craft")
				"log":
					if p.mounted or target.data.get("taken",false):return
					p.mounted=true
					target.data.taken=true
					target.refresh()
					update_carried_log(p)
				"generator":
					if target.data.get("on",false):
						target.data.on=false
					else:
						if float(target.data.get("fuel",0))<=0.05:
							if not p.inventory.has("fuel"):
								tell(id,"Benzin szükséges a generátorhoz.")
								return
							p.inventory=Data.paid(p.inventory,{"fuel":1})
							target.data.fuel=5.0
						target.data.on=true
					power_update()
					tell(id,target.title())
				"pump":
					if not powered(target.position,1.5):
						tell(id,"A pumpához 12 méteren belül járó generátor kell.")
						return
					if int(target.data.get("liters",0))<5:return
					if add_item(p,"fuel",1):
						target.data.liters-=5
						tell(id,"5 liter benzin kannába töltve.")
					else:tell(id,"Nincs elég szabad teherbírás.")
		"take":
			if not target or target.kind not in ["loot","crate"] or target.data.get("taken",false):return
			var contents:Dictionary=target.data.get("items",{})
			var count:int=int(contents.get(item,0))
			if count<=0 or not Data.ITEMS.has(item):return
			var amount:int=count
			while amount>0:
				if add_item(p,item,amount):break
				amount-=1
			if amount==0:
				tell(id,"Túl nehéz. Előbb vegyél fel hátizsákot vagy tegyél le valamit.")
				return
			contents[item]=count-amount
			if int(contents[item])==0:contents.erase(item)
			target.data.items=contents
			mark_world()
			sound_event("pickup",p.position)
			tell(id,target.uid,"container")
		"deposit":
			if not target or target.kind!="crate" or not p.inventory.has(item):return
			var copy:Dictionary=Data.paid(p.inventory,{item:1})
			if item=="backpack" and Data.mass(copy)>14:
				tell(id,"A hátizsák levételéhez csökkentsd a terhet.")
				return
			if not target.data.has("items"):target.data.items={}
			if Data.mass(target.data.items)+float(Data.ITEMS[item].weight)>100:
				tell(id,"A láda megtelt (100 kg).")
				return
			p.inventory=copy
			target.data.items[item]=int(target.data.items.get(item,0))+1
			p.update_equipment()
			tell(id,target.uid,"container")
		"craft":
			var recipe:String=str(payload.get("recipe",""))
			if not Data.RECIPES.has(recipe):return
			var r:Dictionary=Data.RECIPES[recipe]
			if r.station>0 and not near_bench(p):return
			if not Data.can_pay(p.inventory,r.need):return
			var before:Dictionary=p.inventory.duplicate()
			p.inventory=Data.paid(p.inventory,r.need)
			if not add_item(p,r.out,int(r.amount)):
				p.inventory=before
				tell(id,"Nincs hely az elkészülő tárgynak.")
				return
			sound_event("craft",p.position)
			tell(id,"","craft")
		"car_battery":
			if not target or not vehicles.has(target_id) or target.battery:return
			if not p.inventory.has("battery"):
				tell(id,"Akkumulátor kell; nézd meg a garázst.")
				return
			p.inventory=Data.paid(p.inventory,{"battery":1})
			target.battery=true
			tell(id,"Akkumulátor beszerelve.")
		"car_repair":
			if not target or not vehicles.has(target_id) or not p.inventory.has("repair"):return
			p.inventory=Data.paid(p.inventory,{"repair":1})
			target.condition=minf(100,target.condition+35)
			tell(id,"Jármű javítva.")
		"car_fuel":
			if not target or not vehicles.has(target_id) or not p.inventory.has("fuel") or target.fuel>35:return
			p.inventory=Data.paid(p.inventory,{"fuel":1})
			target.fuel+=5
			tell(id,"5 liter betöltve.")
		"enter":
			if not target or not vehicles.has(target_id) or p.mounted:return
			if target.driver!=0 or p.vehicle_id!="":return
			target.driver=id
			p.vehicle_id=target.uid
			p.collision_layer=0
			tell(id,"[WASD] Vezetés · [Space] Fék · [E] Kiszállás")
		"exit":
			if p.vehicle_id!="" and vehicles.has(p.vehicle_id):
				if absf(vehicles[p.vehicle_id].speed)>1:
					tell(id,"Állj meg a kiszálláshoz.")
					return
				release_vehicle(p)
		"attack":attack(p,payload)
		"reload":reload_weapon(p)
		"build":place_build(p,payload)
		"drop_log":
			if not p.mounted:return
			var pos:Vector3=p.position-p.basis.z*1.5
			pos.y=0
			var log_id:String="log_"+str(Time.get_ticks_msec())+"_"+str(id)
			world.spawn_thing(log_id,"log",pos)
			p.mounted=false
			update_carried_log(p)
	p.update_equipment()
	mark_world()

func reload_weapon(p:Node) -> void:
	if p.action_cooldown>0:return
	var rifle:bool=p.equipment=="rifle"
	if p.equipment not in ["pistol","rifle"]:return
	var ammo:String="rifle_ammo" if rifle else "ammo"
	var current:int=p.rifle_magazine if rifle else p.magazine
	var needed:int=mini((30 if rifle else 7)-current,int(p.inventory.get(ammo,0)))
	if needed<=0:return
	p.inventory=Data.paid(p.inventory,{ammo:needed})
	if rifle:p.rifle_magazine+=needed
	else:p.magazine+=needed
	p.action_cooldown=1.4
	tell(p.peer_id,"Újratöltve.")
func attack(p:Node,payload:Dictionary) -> void:
	if p.action_cooldown>0 or p.mounted or p.vehicle_id!="":return
	var target:Vector3=vec_unpack(payload.get("target",[]),p.position)
	var origin:Vector3=p.position+Vector3.UP*1.4
	var dir:Vector3=(target-origin).normalized()
	if not dir.is_finite():return
	var gun:bool=p.equipment in ["pistol","rifle"]
	var rifle:bool=p.equipment=="rifle"
	if gun:
		if (p.rifle_magazine if rifle else p.magazine)<=0:
			tell(p.peer_id,"Üres tár. [R] Újratöltés.")
			return
		if rifle:p.rifle_magazine-=1
		else:p.magazine-=1
	p.action_cooldown=0.16 if rifle else (0.3 if gun else 0.55)
	var reach:float=200 if gun else 2.9
	var q:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(origin,origin+dir*reach,1|4)
	q.exclude=[p.get_rid()]
	var hit:Dictionary=get_world_3d().direct_space_state.intersect_ray(q)
	make_noise(p.position,160 if gun else 20)
	sound_event("shot" if gun else "hit",p.position)
	if hit.is_empty():return
	var collider:Node=hit.collider
	if collider.get("uid")!=null and zombies.has(collider.uid):
		var damage:float=60 if rifle else (36 if gun else (38 if p.equipment=="axe" else 12))
		if float(hit.position.y)-collider.position.y>1.5:damage*=1.6
		collider.hit(damage)
	elif collider.get("kind")=="tree" and p.equipment=="axe":
		if int(collider.data.get("hp",0))<=0:return
		collider.data.hp=maxi(0,int(collider.data.hp)-32)
		collider.refresh()
		if collider.data.hp<=0:
			world.spawn_thing(collider.uid+"_log","log",collider.position+Vector3(1.4,0,0))
			tell(p.peer_id,"Fa kivágva. [E] Vedd vállra a rönköt, majd vidd a munkapadhoz.")
func make_noise(at:Vector3,radius:float) -> void:
	for z in zombies.values():z.hear(at,radius)
func sound_event(id:String,at:Vector3) -> void:
	audio.play(id,at)
func release_vehicle(p:Node) -> void:
	if p.vehicle_id!="" and vehicles.has(p.vehicle_id):
		var car:Node=vehicles[p.vehicle_id]
		car.driver=0
		car.drive_input=Vector2.ZERO
		car.brake=true
		var exit_pos:Vector3=car.position+car.basis.x*2.4+Vector3.UP*0.3
		var q:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(car.position+Vector3.UP,exit_pos+Vector3.UP,1)
		q.exclude=[car.get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			exit_pos=car.position-car.basis.x*2.4+Vector3.UP*0.3
		p.position=exit_pos
		p.remote_target=exit_pos
		if net.online and p.peer_id!=multiplayer.get_unique_id():
			net.correct_position.rpc_id(p.peer_id,vec_pack(exit_pos))
	p.vehicle_id=""
	p.collision_layer=2
	p.visual.visible=true
func set_drive_input(value:Vector2,brake:bool) -> void:
	drive_input=value
	drive_brake=brake
	if authoritative() and local_player.vehicle_id!="" and vehicles.has(local_player.vehicle_id):
		var c:Node=vehicles[local_player.vehicle_id]
		c.drive_input=value
		c.brake=brake
func update_carried_log(p:Node) -> void:
	var old:Node=p.get_node_or_null("CarriedLog")
	if old:
		p.remove_child(old)
		old.queue_free()
	if p.mounted:
		var root:Node3D=Node3D.new()
		root.name="CarriedLog"
		p.add_child(root)
		var m:MeshInstance3D=Art.cylinder(root,Vector3(0.43,1.48,0),0.2,2,Color("#876947"))
		m.rotation.x=PI/2
func powered(at:Vector3,load_kw:float=0.06) -> bool:
	for t in things.values():
		if t.kind=="generator" and t.data.get("on",false) and float(t.data.get("fuel",0))>0:
			if t.position.distance_to(at)<=12 and load_kw<=3.5:return true
	return false
func power_update() -> void:
	var loads:Dictionary={}
	var assignments:Dictionary={}
	for t in things.values():
		if t.kind not in ["lamp","pump"]:continue
		for generator in things.values():
			if generator.kind=="generator" and generator.data.get("on",false) and generator.position.distance_to(t.position)<=12:
				var demand:float=1.5 if t.kind=="pump" else 0.06
				loads[generator.uid]=float(loads.get(generator.uid,0))+demand
				assignments[t.uid]=generator.uid
				break
	for t in things.values():
		if t.kind=="generator" and float(loads.get(t.uid,0))>3.5:
			t.data.on=false
			t.data.overloaded=true
			mark_world()
	for t in things.values():
		if t.kind=="lamp":
			var on:bool=assignments.has(t.uid) and float(loads.get(assignments[t.uid],0))<=3.5 and things[assignments[t.uid]].data.get("on",false)
			if bool(t.data.get("powered",false))!=on:
				t.data.powered=on
				t.refresh()
				mark_world()
func toggle_build() -> void:
	if local_player.vehicle_id!="":return
	build_mode=not build_mode
	if not preview:
		preview=MeshInstance3D.new()
		var m:StandardMaterial3D=StandardMaterial3D.new()
		m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode=BaseMaterial3D.CULL_DISABLED
		preview.material_override=m
		preview.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(preview)
	preview.visible=build_mode
func build_prompt() -> String:
	var key:String=Data.BUILD.keys()[build_index]
	var spec:Dictionary=Data.BUILD[key]
	var cost:String=""
	for id in spec.need:cost+=str(Data.ITEMS[id].name)+" ×"+str(spec.need[id])+"  "
	return "%s  ·  %s\n[Q] ELEM   [T] 45° FORGATÁS   [BAL EGÉR] LERAKÁS   [B] KILÉPÉS" % [spec.name,cost]
func update_preview() -> void:
	var hit:Dictionary=local_player.ray(12)
	if hit.is_empty():
		preview.visible=false
		preview_valid=false
		return
	var kind:String=Data.BUILD.keys()[build_index]
	preview_position=Vector3(snappedf(hit.position.x,0.5),0,snappedf(hit.position.z,0.5))
	if kind in ["wall","window","door"]:
		preview_position.y=0.25
	elif kind=="roof":
		preview_position.y=2.65
	else:
		preview_position.y=0.0
	var s:Vector3=Data.BUILD[kind].size
	var box:BoxMesh=BoxMesh.new()
	box.size=s
	preview.mesh=box
	preview.position=preview_position+Vector3.UP*s.y/2
	preview.rotation.y=build_yaw
	preview_valid=can_build(local_player,kind,preview_position,build_yaw)
	preview.material_override.albedo_color=Color(0.44,0.77,0.55,0.45) if preview_valid else Color(0.87,0.25,0.18,0.45)
	preview.visible=true
func can_build(p:Node,kind:String,pos:Vector3,yaw:float) -> bool:
	if not Data.BUILD.has(kind) or not pos.is_finite() or not is_finite(yaw):return false
	if p.position.distance_to(pos)>6 or absf(pos.x)>580 or absf(pos.z)>580:return false
	if not Data.can_pay(p.inventory,Data.BUILD[kind].need):return false
	if absf(pos.x)<7:return false
	if world.occupied(pos,1):return false
	# The base is intentionally outside the village's claimed public buildings.
	var support:bool=kind not in ["wall","window","door","roof"]
	for existing in builds:
		var at:Vector3=vec_unpack(existing.p)
		if kind in ["wall","window","door"] and existing.kind=="foundation" and Vector2(pos.x-at.x,pos.z-at.z).length()<=1.5:
			support=true
		if kind=="roof" and existing.kind in ["wall","door","window"] and Vector2(pos.x-at.x,pos.z-at.z).length()<=2:
			support=true
	if not support:return false
	if absf(pos.y-(2.65 if kind=="roof" else (0.25 if kind in ["wall","window","door"] else 0.0)))>0.02:return false
	var query:PhysicsShapeQueryParameters3D=PhysicsShapeQueryParameters3D.new()
	var shape:BoxShape3D=BoxShape3D.new()
	shape.size=Data.BUILD[kind].size*0.90
	query.shape=shape
	query.transform=Transform3D(Basis(Vector3.UP,yaw),pos+Vector3.UP*(Data.BUILD[kind].size.y/2+0.04))
	query.collision_mask=1|2|4
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
func place_build(p:Node,payload:Dictionary) -> void:
	var kind:String=str(payload.get("kind",""))
	var pos:Vector3=vec_unpack(payload.get("p",[]),Vector3.INF)
	var yaw:float=float(payload.get("yaw",0))
	if builds.size()>=300:
		tell(p.peer_id,"A prototípus építési korlátja: 300 elem.")
		return
	if not can_build(p,kind,pos,yaw):
		tell(p.peer_id,"Ide nem építhető: költség, ütközés, távolság vagy támasz hiányzik.")
		return
	p.inventory=Data.paid(p.inventory,Data.BUILD[kind].need)
	var entry:Dictionary={"id":"build_"+str(builds.size()),"kind":kind,"p":vec_pack(pos),"yaw":yaw,"owner":p.peer_id}
	builds.append(entry)
	instantiate_build(entry)
	tell(p.peer_id,str(Data.BUILD[kind].name)+" elkészült.")
func instantiate_build(entry:Dictionary) -> void:
	if build_root.has_node(str(entry.id)):return
	var n:Node3D=Node3D.new()
	n.name=str(entry.id)
	build_root.add_child(n)
	n.position=vec_unpack(entry.p)
	n.rotation.y=float(entry.yaw)
	var kind:String=str(entry.kind)
	var timber:Color=Color("#96754d")
	if kind in ["bench","crate","generator","lamp","campfire"]:
		var data:Dictionary={"fuel":0.0,"on":false} if kind=="generator" else {}
		world.spawn_thing(str(entry.id)+"_thing",kind,n.position,data,n.rotation.y)
	elif kind=="door":
		for x in [-0.76,0.76]:
			Art.box(n,Vector3(x,1.2,0),Vector3(0.48,2.4,0.16),timber,true)
		Art.box(n,Vector3(0,2.25,0),Vector3(1.1,0.3,0.16),timber,true)
		world.spawn_thing(str(entry.id)+"_door","door",n.position,{"open":false},n.rotation.y)
	elif kind=="window":
		Art.box(n,Vector3(0,0.43,0),Vector3(2,0.86,0.16),timber,true)
		Art.box(n,Vector3(0,2.15,0),Vector3(2,0.5,0.16),timber,true)
		for x in [-0.76,0.76]:
			Art.box(n,Vector3(x,1.38,0),Vector3(0.48,1.04,0.16),timber,true)
	else:
		var size:Vector3=Data.BUILD[kind].size
		Art.box(n,Vector3.UP*size.y/2,size,timber,true)
		if kind=="wall":
			for i in range(7):
				Art.box(n,Vector3(-0.9+i*0.3,1.2,0.09),Vector3(0.025,2.4,0.02),Color("#604f37"))
func handle_death(p:Node) -> void:
	death_processed[p.peer_id]=true
	release_vehicle(p)
	var id:String="body_"+str(p.peer_id)+"_"+str(Time.get_ticks_msec())
	var pos:Vector3=p.position
	pos.y=0
	world.spawn_thing(id,"crate",pos,{"items":p.inventory.duplicate(),"name":"Elhunyt túlélő"})
	p.inventory={}
	p.magazine=0
	p.rifle_magazine=0
	p.mounted=false
	p.equipment="hands"
	update_carried_log(p)
	p.update_equipment()
	mark_world()
func respawn(p:Node) -> void:
	p.position=Vector3(6+(p.peer_id%4),0.2,57)
	p.velocity=Vector3.ZERO
	p.health=100
	p.hunger=100
	p.thirst=100
	p.stamina=100
	p.bleeding=0
	p.deaths+=1
	death_processed.erase(p.peer_id)
	if net.online and p.peer_id!=multiplayer.get_unique_id():
		net.correct_position.rpc_id(p.peer_id,vec_pack(p.position))
	mark_world()
static func vec_pack(v:Vector3) -> Array:
	return [v.x,v.y,v.z]
static func vec_unpack(a:Variant,fallback:Vector3=Vector3.ZERO) -> Vector3:
	if not a is Array or a.size()!=3:return fallback
	for value in a:
		if not (value is int or value is float) or not is_finite(float(value)):return fallback
	return Vector3(float(a[0]),float(a[1]),float(a[2]))
func pack_snapshot() -> Dictionary:
	var ps:Array=[]
	var vs:Array=[]
	var zs:Array=[]
	for p in players.values():
		var entry:Dictionary=p.pack_state()
		entry["mounted"]=p.mounted
		ps.append(entry)
	for v in vehicles.values():vs.append(v.pack_state())
	for z in zombies.values():zs.append(z.pack_state())
	return {"players":ps,"vehicles":vs,"zombies":zs,"hour":atmosphere.hour}
func pack_world() -> Dictionary:
	var state:Dictionary=pack_snapshot()
	var ts:Array=[]
	for t in things.values():ts.append(t.pack_state())
	state["things"]=ts
	state["builds"]=builds.duplicate(true)
	state["version"]=1
	return state
func apply_snapshot(state:Dictionary,restore_position:bool=false) -> void:
	atmosphere.hour=float(state.get("hour",17.4))
	for d in state.get("players",[]):
		var id:int=int(d.id)
		if not players.has(id):add_player(id,id==multiplayer.get_unique_id())
		var p:Node=players[id]
		var pos:Vector3=vec_unpack(d.p,p.position)
		if not p.local or restore_position:
			p.remote_target=pos
			if authoritative() or restore_position:p.position=pos
			p.rotation.y=float(d.yaw)
		for key in ["health","hunger","thirst","bleeding","magazine","rifle_magazine","deaths"]:
			if d.has(key):p.set(key,d[key])
		p.inventory=d.get("inventory",{}).duplicate()
		p.equipment=str(d.get("equipment","hands"))
		p.vehicle_id=str(d.get("vehicle",""))
		if p.mounted!=bool(d.get("mounted",false)):
			p.mounted=bool(d.get("mounted",false))
			update_carried_log(p)
		p.update_equipment()
	for d in state.get("vehicles",[]):
		if not vehicles.has(d.id):continue
		var c:Node=vehicles[d.id]
		c.network_position=vec_unpack(d.p,c.position)
		c.network_yaw=float(d.yaw)
		if authoritative() or restore_position:
			c.position=c.network_position
			c.rotation.y=c.network_yaw
		for key in ["fuel","condition","battery","driver","speed"]:
			c.set(key,d[key])
		c.cargo=d.get("cargo",{}).duplicate()
	for d in state.get("zombies",[]):
		if not zombies.has(d.id):continue
		var z:Node=zombies[d.id]
		z.remote_target=vec_unpack(d.p,z.position)
		if authoritative() or restore_position:z.position=z.remote_target
		z.rotation.y=float(d.yaw)
		z.health=float(d.health)
		if z.health>0:
			z.dead_shown=false
			z.collision_layer=4
			z.visual.rotation=Vector3.ZERO
func apply_world(state:Dictionary,restore_position:bool=false) -> void:
	loading_state=true
	var incoming_ids:Dictionary={}
	for d in state.get("things",[]):
		incoming_ids[d.id]=true
	for id in things.keys():
		if not incoming_ids.has(id):
			things[id].queue_free()
			things.erase(id)
	var desired_builds:Array=state.get("builds",[])
	var build_ids:Dictionary={}
	for entry in desired_builds:build_ids[entry.id]=true
	for child in build_root.get_children():
		if not build_ids.has(str(child.name)):
			build_root.remove_child(child)
			child.queue_free()
	builds=desired_builds.duplicate(true)
	for entry in builds:instantiate_build(entry)
	for d in state.get("things",[]):
		var t:Node=world.spawn_thing(str(d.id),str(d.kind),vec_unpack(d.p),d.data,float(d.yaw))
		t.data=d.data.duplicate(true)
		if t.kind=="tree" and int(t.data.get("hp",0))>0:
			t.already_fallen=false
			t.visual.rotation=Vector3.ZERO
		t.refresh()
	apply_snapshot(state,restore_position)
	loading_state=false
func save_game() -> bool:
	if not authoritative() or not playing:
		if ui:ui.toast("A közös világot a fogadó gép menti.")
		return false
	var save:Dictionary=pack_world()
	var file:FileAccess=FileAccess.open("user://survival.json.tmp",FileAccess.WRITE)
	if not file:
		ui.toast("Nem sikerült megnyitni a mentést.")
		return false
	file.store_string(JSON.stringify(save))
	file.flush()
	var err:Error=file.get_error()
	file.close()
	if err!=OK:
		ui.toast("Hiba a mentés írásakor.")
		return false
	if FileAccess.file_exists("user://survival.json"):
		DirAccess.copy_absolute("user://survival.json","user://survival.backup.json")
	var result:Error=DirAccess.rename_absolute("user://survival.json.tmp","user://survival.json")
	ui.toast("Világ elmentve." if result==OK else "A mentés véglegesítése nem sikerült.")
	return result==OK
func load_game() -> bool:
	var path:String="user://survival.json"
	if not FileAccess.file_exists(path):return false
	var file:FileAccess=FileAccess.open(path,FileAccess.READ)
	if not file:return false
	var state:Variant=JSON.parse_string(file.get_as_text())
	if not state is Dictionary or int(state.get("version",0))!=1:
		ui.toast("Érvénytelen vagy más verziójú mentés.")
		return false
	apply_world(state,true)
	for c in vehicles.values():c.driver=0; c.speed=0
	for p in players.values():p.vehicle_id=""
	return true
func smoke_test() -> void:
	# Run by the headless integration workflow. Tests the production action handlers.
	await get_tree().physics_frame
	start_solo(false)
	var p:Node=local_player
	p.inventory={"backpack":1,"wood":8,"nails":4,"scrap":8,"parts":6,"wire":6,"rag":4,"battery":1,"fuel":2,"axe":1,"pistol":1,"ammo":14}
	execute_action(1,"craft",{"recipe":"bandage"})
	assert(int(p.inventory.get("bandage",0))==1,"Craft should produce a bandage.")
	assert(int(p.inventory.get("rag",0))==2,"Craft should consume exact resources.")
	p.health=60
	execute_action(1,"use",{"item":"bandage"})
	assert(p.health==80,"Medical item should heal.")
	p.position=vehicles.duna.position+Vector3(2,0,0)
	execute_action(1,"car_battery",{"id":"duna"})
	assert(vehicles.duna.battery,"Battery installation failed.")
	var before:float=vehicles.duna.fuel
	execute_action(1,"car_fuel",{"id":"duna"})
	assert(vehicles.duna.fuel==before+5,"Refuel should add five liters.")
	execute_action(1,"equip",{"item":"pistol"})
	execute_action(1,"reload",{})
	assert(p.magazine==7 and p.inventory.ammo==7,"Reload conservation failed.")
	assert(not can_build(p,"wall",Vector3(90,0.25,90),0),"Unsupported wall should be denied.")
	var saved:Dictionary=pack_world().duplicate(true)
	assert(saved.things.size()>40 and saved.zombies.size()==40,"World content missing.")
	assert(world.path_to(Vector3(0,0,30),Vector3(0,0,-50)).size()>0,"Road path missing.")
	var first:Dictionary=p.inventory.duplicate()
	p.inventory={}
	apply_world(saved,true)
	assert(p.inventory==first,"World roundtrip lost inventory.")
	for preset in range(4):
		atmosphere.apply_quality(preset,true,true)
	await get_tree().process_frame
	print("NYUGATI_ZONA_SMOKE_OK")
	get_tree().quit(0)

func capture_preview(label:String) -> void:
	for i in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img:Image=get_viewport().get_texture().get_image()
	assert(img!=null and img.get_width()>0,"Rendered viewport is empty.")
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var err:Error=img.save_png("res://artifacts/"+label+".png")
	assert(err==OK,"Could not save rendered preview.")
	img.resize(960,540,Image.INTERPOLATE_LANCZOS)
	var encoded:String=Marshalls.raw_to_base64(img.save_jpg_to_buffer(0.83))
	for offset in range(0,encoded.length(),3000):
		print("NZIMG|"+label+"|"+str(offset)+"|"+encoded.substr(offset,3000))
func render_test() -> void:
	atmosphere.cycle=false
	atmosphere.hour=17.35
	await capture_preview("menu")
	start_solo(false)
	atmosphere.cycle=false
	atmosphere.hour=17.35
	local_player.inventory={"backpack":1,"axe":1,"pistol":1,"water":2,"beans":2,"bandage":2,"wood":8,"scrap":4,"fuel":1,"ammo":14}
	local_player.equipment="axe"
	local_player.update_equipment()
	local_player.position=Vector3(10,0.2,42)
	local_player.rotation.y=-0.06
	local_player.pitch=-0.12
	await capture_preview("gameplay")
	ui.show_inventory()
	await capture_preview("inventory")
	ui.show_settings()
	await capture_preview("graphics")
	get_tree().paused=false
	print("NYUGATI_ZONA_RENDER_OK")
	get_tree().quit()
func lan_host_test() -> void:
	start_host()
	assert(net.online,"Host start failed.")
	var elapsed:float=0
	while elapsed<25:
		await get_tree().create_timer(0.1).timeout
		elapsed+=0.1
		for id in players:
			if id==1:continue
			if int(players[id].inventory.get("water",0))>0 and int(things.start.data.items.get("water",0))==0:
				print("NYUGATI_ZONA_LAN_HOST_OK")
				await get_tree().create_timer(1.0).timeout
				get_tree().quit(0)
				return
	push_error("LAN host did not observe authoritative loot transfer.")
	get_tree().quit(1)
func lan_client_test() -> void:
	join_host("127.0.0.1")
	var elapsed:float=0
	while not playing and elapsed<12:
		await get_tree().create_timer(0.1).timeout
		elapsed+=0.1
	assert(playing and net.online,"LAN client did not join.")
	await get_tree().create_timer(1.2).timeout
	request("take",{"id":"start","item":"water"})
	elapsed=0
	while elapsed<8:
		await get_tree().create_timer(0.1).timeout
		elapsed+=0.1
		if local_player and int(local_player.inventory.get("water",0))>0:
			assert(players.size()==2,"Client roster was not replicated.")
			print("NYUGATI_ZONA_LAN_CLIENT_OK")
			get_tree().quit(0)
			return
	push_error("LAN client did not receive inventory transfer.")
	get_tree().quit(1)
