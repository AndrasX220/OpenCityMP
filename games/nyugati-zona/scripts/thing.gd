extends StaticBody3D
const Art=preload("res://scripts/art.gd")
var game:Node
var uid:String=""
var kind:String="loot"
var data:Dictionary={}
var visual:Node3D
var shape:CollisionShape3D
var light:OmniLight3D
var already_fallen:bool=false
func _ready() -> void:
	collision_layer=1
	collision_mask=0
	visual=Node3D.new()
	add_child(visual)
	var size:Vector3=Vector3(0.92,0.64,0.64)
	match kind:
		"tree":
			var variant:int=int(data.get("variant",0))
			Art.cylinder(visual,Vector3(0,1.8,0),0.22,3.6,Color("#68533b"),0.14,7)
			if variant%3==0:
				for i in range(3):
					Art.cylinder(visual,Vector3(0,3.8+i*1.25,0),2.4-i*0.55,2.5,Color("#3d5843").lightened(i*0.025),0.1,6)
			else:
				for p in [Vector3(0,4.6,0),Vector3(-1,4.0,0.5),Vector3(1.1,4.2,-0.3)]:
					Art.tapered(visual,p,Vector3(3.1,2.8,2.9),Color("#747c43") if variant%2 else Color("#59683c"),0.6)
			size=Vector3(0.5,3.6,0.5)
		"door":
			Art.box(visual,Vector3(0,1.05,0),Vector3(0.94,2.1,0.13),Color("#736347"))
			Art.box(visual,Vector3(-0.32,1.05,0.09),Vector3(0.12,0.04,0.045),Color("#b7aa7c"))
			size=Vector3(0.94,2.1,0.15)
		"log":
			var m:MeshInstance3D=Art.cylinder(visual,Vector3(0,0.24,0),0.21,2.1,Color("#846343"))
			m.rotation.z=PI/2
			size=Vector3(2.1,0.42,0.44)
		"pump":
			Art.prop(visual,kind)
			size=Vector3(0.85,1.85,0.78)
		"bench":
			Art.prop(visual,kind)
			size=Vector3(1.5,1,0.7)
		"generator","lamp","campfire":
			Art.prop(visual,kind)
			size=Vector3(0.85,0.8,0.65) if kind=="generator" else Vector3(0.5,0.4,0.5)
			if kind!="generator":
				light=OmniLight3D.new()
				light.position.y=2.1 if kind=="lamp" else 0.8
				light.light_color=Color("#ffcd83")
				light.light_energy=3.0
				light.omni_range=13 if kind=="lamp" else 7
				add_child(light)
		_:
			Art.prop(visual,"crate")
	shape=CollisionShape3D.new()
	var s:BoxShape3D=BoxShape3D.new()
	s.size=size
	shape.shape=s
	shape.position.y=size.y*0.5
	add_child(shape)
	refresh()
func title() -> String:
	match kind:
		"tree":return "Fa · %d állapot  /  balta szükséges" % int(data.get("hp",120))
		"loot":return str(data.get("name","Készletek"))+" · átvizsgálás"
		"crate":return "Tárolóláda · készletek"
		"bench":return "Munkapad I · barkácsolás / rönk fűrészelése"
		"pump":return "Benzinkút · %d L  /  működő generátor szükséges" % int(data.get("liters",400))
		"generator":return "Generátor · "+("JÁR" if data.get("on",false) else "ÁLL")+" · %.1f L" % float(data.get("fuel",0))
		"door":return "Ajtó · "+("becsukás" if data.get("open",false) else "kinyitás")
		"lamp":return "Műhelylámpa · "+("világít" if data.get("powered",false) else "nincs áram")
		"campfire":return "Tábortűz · melegedés"
		"log":return "Rönk · vállra vétel"
	return kind
func refresh() -> void:
	if not visual:
		return
	var used:bool=bool(data.get("taken",false))
	visible=not used
	shape.set_deferred("disabled",used or (kind=="tree" and int(data.get("hp",120))<=0) or (kind=="door" and bool(data.get("open",false))))
	if kind=="door":
		visual.rotation.y=PI/2 if data.get("open",false) else 0.0
	if kind=="tree" and int(data.get("hp",120))<=0 and not already_fallen:
		already_fallen=true
		var tween:Tween=create_tween()
		tween.tween_property(visual,"rotation:z",-1.47,1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if light:
		light.visible=bool(data.get("powered",false)) if kind=="lamp" else true
func pack_state() -> Dictionary:
	return {"id":uid,"kind":kind,"p":[position.x,position.y,position.z],"yaw":rotation.y,"data":data.duplicate(true)}
