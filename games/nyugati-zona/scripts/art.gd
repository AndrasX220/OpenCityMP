extends RefCounted
# Original mesh kit. One shared material per colour, baked static world meshes.
static var materials:Dictionary={}
static func mat(color:Color, glow:float=0.0) -> StandardMaterial3D:
	var key:String=color.to_html()+str(glow)
	if materials.has(key):
		return materials[key]
	var m:StandardMaterial3D=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.88
	if glow>0.0:
		m.emission_enabled=true
		m.emission=color
		m.emission_energy_multiplier=glow
	materials[key]=m
	return m
static func mesh(parent:Node3D, shape:Mesh, pos:Vector3, color:Color, glow:float=0.0) -> MeshInstance3D:
	var m:MeshInstance3D=MeshInstance3D.new()
	m.mesh=shape
	m.material_override=mat(color,glow)
	m.position=pos
	parent.add_child(m)
	return m
static func box(parent:Node3D, pos:Vector3, size:Vector3, color:Color, solid:bool=false, glow:float=0.0) -> MeshInstance3D:
	var s:BoxMesh=BoxMesh.new()
	s.size=size
	var m:MeshInstance3D=mesh(parent,s,pos,color,glow)
	if solid:
		collider(parent,pos,size)
	return m
static func collider(parent:Node3D, pos:Vector3, size:Vector3) -> StaticBody3D:
	var b:StaticBody3D=StaticBody3D.new()
	b.position=pos
	parent.add_child(b)
	var c:CollisionShape3D=CollisionShape3D.new()
	var s:BoxShape3D=BoxShape3D.new()
	s.size=size
	c.shape=s
	b.add_child(c)
	return b
static func cylinder(parent:Node3D,pos:Vector3,radius:float,height:float,color:Color,top:float=-1.0,sides:int=8) -> MeshInstance3D:
	var s:CylinderMesh=CylinderMesh.new()
	s.top_radius=radius if top<0 else top
	s.bottom_radius=radius
	s.height=height
	s.radial_segments=sides
	s.rings=1
	return mesh(parent,s,pos,color)
static func tapered(parent:Node3D,pos:Vector3,size:Vector3,color:Color,top_scale:float=0.8) -> MeshInstance3D:
	# An eight-sided bevelled cuboid, hard normals per face.
	var points:Array[Vector2]=[Vector2(-0.38,-0.5),Vector2(0.38,-0.5),Vector2(0.5,-0.38),Vector2(0.5,0.38),Vector2(0.38,0.5),Vector2(-0.38,0.5),Vector2(-0.5,0.38),Vector2(-0.5,-0.38)]
	var st:SurfaceTool=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var j:int=(i+1)%8
		var a:Vector3=Vector3(points[i].x*size.x,-size.y*0.5,points[i].y*size.z)
		var b:Vector3=Vector3(points[j].x*size.x,-size.y*0.5,points[j].y*size.z)
		var c:Vector3=Vector3(b.x*top_scale,size.y*0.5,b.z*top_scale)
		var d:Vector3=Vector3(a.x*top_scale,size.y*0.5,a.z*top_scale)
		for v in [a,b,c,a,c,d]:
			st.add_vertex(v)
		for v in [Vector3(0,-size.y*0.5,0),b,a,Vector3(0,size.y*0.5,0),d,c]:
			st.add_vertex(v)
	st.generate_normals()
	var m:MeshInstance3D=mesh(parent,st.commit(),pos,color)
	# The generated winding is deliberately double-sided for roof/head silhouettes.
	m.material_override=mat(color)
	m.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
	return m
static func roof(parent:Node3D, pos:Vector3, width:float, depth:float, rise:float,color:Color) -> void:
	var st:SurfaceTool=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a:Vector3=Vector3(-width/2,0,-depth/2)
	var b:Vector3=Vector3(width/2,0,-depth/2)
	var c:Vector3=Vector3(0,rise,-depth/2)
	var d:Vector3=Vector3(-width/2,0,depth/2)
	var e:Vector3=Vector3(width/2,0,depth/2)
	var g:Vector3=Vector3(0,rise,depth/2)
	for v in [a,c,b,d,e,g,a,d,g,a,g,c,b,c,g,b,g,e]:
		st.add_vertex(v)
	st.generate_normals()
	var m:MeshInstance3D=mesh(parent,st.commit(),pos,color)
	m.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
static func text3(parent:Node3D, words:String, pos:Vector3, size:int=48, color:Color=Color("#ede3c8")) -> Label3D:
	var l:Label3D=Label3D.new()
	l.text=words
	l.position=pos
	l.font_size=size
	l.pixel_size=0.008
	l.modulate=color
	l.outline_size=0
	l.no_depth_test=false
	parent.add_child(l)
	return l
static func weapon(parent:Node3D, rifle:bool=true) -> Node3D:
	var n:Node3D=Node3D.new()
	parent.add_child(n)
	var metal:Color=Color("#343c3b")
	if rifle:
		box(n,Vector3(0,0,-0.17),Vector3(0.075,0.12,0.38),metal)
		box(n,Vector3(0,-0.035,0.12),Vector3(0.08,0.13,0.22),Color("#805438")).rotation.x=-0.15
		box(n,Vector3(0,-0.11,-0.06),Vector3(0.055,0.15,0.10),metal).rotation.x=0.22
		box(n,Vector3(0,0,-0.39),Vector3(0.065,0.08,0.18),Color("#8e6040"))
		box(n,Vector3(0,0.01,-0.57),Vector3(0.027,0.035,0.25),metal)
		box(n,Vector3(0,0.055,-0.58),Vector3(0.017,0.06,0.02),metal)
	else:
		box(n,Vector3(0,0,-0.10),Vector3(0.065,0.075,0.23),metal)
		box(n,Vector3(0,-0.065,-0.02),Vector3(0.055,0.13,0.07),Color("#5b4437")).rotation.x=-0.2
	return n
static func character(parent:Node3D,zombie:bool=false,variant:int=0) -> Node3D:
	var n:Node3D=Node3D.new()
	n.name="Visual"
	parent.add_child(n)
	var shirt:Color=[Color("#575f45"),Color("#555e6b"),Color("#897751"),Color("#4f6562"),Color("#4c513e")][variant%5]
	var pants:Color=Color("#3a4239")
	var skin:Color=Color("#abbd83") if zombie else Color("#c3956c")
	tapered(n,Vector3(0,1.19,0),Vector3(0.51,0.58,0.3),shirt,1.12)
	box(n,Vector3(0,0.91,0),Vector3(0.48,0.10,0.31),Color("#3c3529"))
	tapered(n,Vector3(0,1.69,-0.012),Vector3(0.34,0.4,0.31),skin,0.87)
	box(n,Vector3(0,1.66,-0.185),Vector3(0.055,0.09,0.08),skin.darkened(0.09))
	for x in [-0.082,0.082]:
		box(n,Vector3(x,1.74,-0.167),Vector3(0.045,0.018,0.015),Color("#202626"))
		box(n,Vector3(x,1.78,-0.166),Vector3(0.065,0.025,0.02),Color("#433d2e"))
	if variant%3!=1:
		tapered(n,Vector3(0,1.89,0),Vector3(0.38,0.14,0.34),Color("#313630"),0.86)
		box(n,Vector3(0,1.85,-0.20),Vector3(0.34,0.035,0.16),Color("#414737"))
	else:
		box(n,Vector3(0,1.89,0.02),Vector3(0.33,0.12,0.29),Color("#62442e"))
	for side in [-1,1]:
		var leg:Node3D=Node3D.new()
		leg.name="LegL" if side<0 else "LegR"
		n.add_child(leg)
		leg.position=Vector3(side*0.13,0.91,0)
		tapered(leg,Vector3(0,-0.35,0),Vector3(0.205,0.66,0.22),pants)
		box(leg,Vector3(0,-0.77,-0.055),Vector3(0.235,0.21,0.37),Color("#35352c"))
		var arm:Node3D=Node3D.new()
		arm.name="ArmL" if side<0 else "ArmR"
		n.add_child(arm)
		arm.position=Vector3(side*0.33,1.44,0)
		tapered(arm,Vector3(0,-0.23,0),Vector3(0.19,0.49,0.21),shirt)
		box(arm,Vector3(0,-0.51,0),Vector3(0.15,0.17,0.17),skin)
		if zombie:
			arm.rotation.x=-0.8
	if zombie:
		box(n,Vector3(0.10,1.17,-0.157),Vector3(0.16,0.18,0.014),Color("#783c32"))
	else:
		var gear:Node3D=Node3D.new()
		gear.name="Gear"
		n.add_child(gear)
		tapered(gear,Vector3(0,1.14,0.32),Vector3(0.48,0.64,0.33),Color("#696f49"))
		box(gear,Vector3(0,1.0,0.51),Vector3(0.34,0.24,0.08),Color("#515a3e"))
		for x in [-0.18,0.18]:
			box(gear,Vector3(x,1.23,-0.175),Vector3(0.07,0.53,0.04),Color("#777751"))
		var roll:MeshInstance3D=cylinder(gear,Vector3(0,0.73,0.34),0.13,0.62,Color("#847756"))
		roll.rotation.z=PI/2
		var gun:Node3D=weapon(gear)
		gun.position=Vector3(0.34,1.40,0.36)
		gun.rotation=Vector3(-1.5,0,-0.20)
		box(gear,Vector3(0.29,0.8,0),Vector3(0.11,0.22,0.13),Color("#574737"))
	return n
static func animate_character(n:Node3D,phase:float,amount:float,zombie:bool=false) -> void:
	for entry in [["LegL",1],["LegR",-1],["ArmL",-1],["ArmR",1]]:
		var joint:Node3D=n.get_node_or_null(entry[0])
		if joint:
			joint.rotation.x=sin(phase)*amount*float(entry[1]) + (-0.75 if zombie and str(entry[0]).begins_with("Arm") else 0.0)
static func car(parent:Node3D,kind:String="hatch",color:Color=Color("#ac3e32")) -> Node3D:
	var n:Node3D=Node3D.new()
	parent.add_child(n)
	n.name="BodyVisual"
	var bus:bool=kind=="bus"
	var tractor:bool=kind=="tractor"
	var w:float=2.45 if bus else 1.62
	var length:float=9.4 if bus else 3.7
	var body_y:float=0.87
	var steel:Color=Color("#384240")
	var glass:Color=Color("#526970")
	box(n,Vector3(0,body_y,0),Vector3(w,0.66,length),color)
	box(n,Vector3(0,0.51,0),Vector3(w*0.93,0.16,length),steel)
	if bus:
		box(n,Vector3(0,2.04,0),Vector3(w,1.57,length),Color("#c9c7b3"))
		box(n,Vector3(0,2.9,0),Vector3(w+0.08,0.17,length+0.10),Color("#2f465b"))
		for side in [-1,1]:
			for i in range(7):
				box(n,Vector3(side*(w/2+0.01),2.17,-3.7+i*1.23),Vector3(0.025,0.96,1.06),glass)
		box(n,Vector3(0,2.15,-length/2-0.012),Vector3(2.16,1.00,0.025),glass)
		text3(n,"PANNÓNIA  /  BEREKFALVA",Vector3(0,2.72,-4.73),30).rotation.y=PI
	elif tractor:
		box(n,Vector3(0,1.17,-0.8),Vector3(1.05,0.70,1.80),Color("#4d784c"))
		box(n,Vector3(0,1.70,0.62),Vector3(1.25,1.2,1.34),glass)
		box(n,Vector3(0,2.37,0.62),Vector3(1.50,0.12,1.62),Color("#637b52"))
		box(n,Vector3(0.44,1.95,-0.90),Vector3(0.12,1.2,0.12),steel)
	else:
		# Separate glass, roof, pillars and hood preserve the 1990s hatchback silhouette.
		tapered(n,Vector3(0,1.48,0.12),Vector3(1.48,0.76,2.14),glass,0.84)
		box(n,Vector3(0,1.88,0.20),Vector3(1.32,0.09,1.89),color)
		for side in [-1,1]:
			for z in [-0.81,0.10,1.08]:
				box(n,Vector3(side*0.69,1.49,z),Vector3(0.065,0.72,0.075),color)
			box(n,Vector3(side*0.815,1.16,0.17),Vector3(0.03,0.11,2.07),color)
			for z in [-0.45,0.70]:
				box(n,Vector3(side*0.83,1.07,z),Vector3(0.035,0.045,0.17),steel)
			box(n,Vector3(side*0.91,1.36,-0.75),Vector3(0.22,0.12,0.17),color)
		box(n,Vector3(0,1.21,-1.33),Vector3(1.61,0.11,0.94),color.lightened(0.04))
		for x in [-0.4,0.4]:
			box(n,Vector3(x,1.10,0.21),Vector3(0.41,0.59,0.43),Color("#393d39"))
		if kind=="sedan":
			box(n,Vector3(0,1.26,1.56),Vector3(1.61,0.2,0.66),color)
	for side in [-1,1]:
		for axle in [-1,1]:
			var wheel:Node3D=Node3D.new()
			wheel.name="Wheel"+str(side)+"_"+str(axle)
			n.add_child(wheel)
			var radius:float=0.49 if bus else (0.66 if tractor and axle>0 else 0.32)
			wheel.position=Vector3(side*w*0.5,radius+0.02,axle*(3.05 if bus else 1.16))
			var tire:MeshInstance3D=cylinder(wheel,Vector3.ZERO,radius,0.22,Color("#282d2b"),-1,12)
			tire.rotation.z=PI/2
			var rim:MeshInstance3D=cylinder(wheel,Vector3(side*0.13,0,0),radius*0.52,0.04,Color("#a4a79c"),-1,8)
			rim.rotation.z=PI/2
	for side in [-1,1]:
		box(n,Vector3(side*w*0.33,0.97,-length/2-0.016),Vector3(w*0.22,0.20,0.04),Color("#ead7a0"),false,0.3)
		box(n,Vector3(side*w*0.39,1.00,length/2+0.016),Vector3(0.22,0.29,0.045),Color("#b7412a"))
	box(n,Vector3(0,0.62,-length/2-0.035),Vector3(w+0.03,0.14,0.12),steel)
	box(n,Vector3(0,0.71,length/2+0.035),Vector3(w,0.17,0.12),steel)
	text3(n,"NZ • 008",Vector3(0,0.85,length/2+0.11),21)
	if kind=="hatch":
		# Visible roof cargo.
		for x in [-0.55,0.55]:
			box(n,Vector3(x,1.97,0.2),Vector3(0.045,0.1,1.6),steel)
		for z in [-0.50,0.90]:
			box(n,Vector3(0,1.96,z),Vector3(1.23,0.04,0.045),steel)
		box(n,Vector3(-0.30,2.18,0.43),Vector3(0.55,0.4,0.63),Color("#8b7150"))
		box(n,Vector3(0.35,2.21,0.26),Vector3(0.22,0.43,0.33),Color("#b04731"))
	return n
static func prop(parent:Node3D,kind:String) -> void:
	match kind:
		"crate","loot":
			box(parent,Vector3(0,0.32,0),Vector3(0.92,0.63,0.63),Color("#846241"))
			for y in [0.13,0.49]:
				box(parent,Vector3(0,y,-0.33),Vector3(0.96,0.07,0.055),Color("#b28b5b"))
			for x in [-0.30,0.30]:
				box(parent,Vector3(x,0.32,-0.36),Vector3(0.07,0.6,0.055),Color("#4c5147"))
		"generator":
			box(parent,Vector3(0,0.28,0),Vector3(0.72,0.45,0.48),Color("#383f3b"))
			box(parent,Vector3(0,0.59,0),Vector3(0.74,0.22,0.49),Color("#b55238"))
			for x in [-0.42,0.42]:
				for z in [-0.31,0.31]:
					box(parent,Vector3(x,0.38,z),Vector3(0.045,0.76,0.045),Color("#292f2d"))
			for i in range(6):
				box(parent,Vector3(-0.24+i*0.085,0.32,-0.255),Vector3(0.027,0.27,0.03),Color("#8b938b"))
		"bench":
			box(parent,Vector3(0,0.92,0),Vector3(1.5,0.16,0.70),Color("#8e714b"))
			for x in [-0.61,0.61]:
				for z in [-0.23,0.23]:
					box(parent,Vector3(x,0.44,z),Vector3(0.1,0.88,0.1),Color("#556155"))
			box(parent,Vector3(0.42,1.10,0),Vector3(0.23,0.23,0.22),Color("#60756c"))
		"pump":
			box(parent,Vector3(0,0.60,0),Vector3(0.7,1.2,0.65),Color("#487b6a"))
			box(parent,Vector3(0,1.53,0),Vector3(0.76,0.65,0.67),Color("#d1cebb"))
			box(parent,Vector3(0,1.62,-0.34),Vector3(0.5,0.2,0.02),Color("#232e29"))
			text3(parent,"BENZIN 95",Vector3(0,1.23,-0.35),24).rotation.y=PI
			box(parent,Vector3(0.48,0.94,0),Vector3(0.055,1.1,0.06),Color("#2d342f"))
		"lamp":
			box(parent,Vector3(0,1.1,0),Vector3(0.06,2.2,0.06),Color("#4e5954"))
			box(parent,Vector3(0,2.2,0),Vector3(0.44,0.20,0.24),Color("#edc37b"),false,1.5)
		"campfire":
			for i in range(5):
				var b:MeshInstance3D=box(parent,Vector3(0,0.1,0),Vector3(0.12,0.12,0.75),Color("#674a32"))
				b.rotation.y=i*PI/5
			cylinder(parent,Vector3(0,0.23,0),0.23,0.4,Color("#ed9a41"),0.05,5)
static func bake_static(root:Node3D) -> void:
	var buckets:Dictionary={}
	var all:Array[MeshInstance3D]=[]
	_collect(root,all)
	for mi in all:
		if mi.mesh==null or mi.material_override==null:
			continue
		var id:int=mi.material_override.get_instance_id()
		if not buckets.has(id):
			var st:SurfaceTool=SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_material(mi.material_override)
			buckets[id]=st
		buckets[id].append_from(mi.mesh,0,root.global_transform.affine_inverse()*mi.global_transform)
		mi.queue_free()
	for st in buckets.values():
		var out:MeshInstance3D=MeshInstance3D.new()
		out.mesh=st.commit()
		root.add_child(out)
static func _collect(n:Node,result:Array[MeshInstance3D]) -> void:
	for child in n.get_children():
		if child is MeshInstance3D:
			result.append(child)
		else:
			_collect(child,result)
