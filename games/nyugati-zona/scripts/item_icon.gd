extends Control
# Crisp, original inventory pictograms, drawn as a shared low-poly icon family.
const Data=preload("res://scripts/data.gd")
var item_id:String="wood"
func _draw() -> void:
	var col:Color=Color(Data.ITEMS.get(item_id,{"color":"a99975"}).color)
	var s:Vector2=size/64.0
	var pts:PackedVector2Array=PackedVector2Array()
	for p in [Vector2(10,22),Vector2(36,12),Vector2(55,23),Vector2(29,34)]:
		pts.append(p*s)
	match item_id:
		"axe","pistol","rifle","repair":
			draw_set_transform(Vector2(32,32)*s,-0.6,s)
			draw_rect(Rect2(-3,-22,6,46),Color("#9b7350"))
			draw_rect(Rect2(-3,-21,25,13),col)
			if item_id in ["pistol","rifle"]:
				draw_rect(Rect2(0,-18,4,28),Color("#313d39"))
				draw_rect(Rect2(0,7,14,7),Color("#303d39"))
		"water","fuel","battery","generator":
			draw_rect(Rect2(Vector2(17,20)*s,Vector2(31,32)*s),col.darkened(0.15))
			draw_colored_polygon(PackedVector2Array([Vector2(17,20)*s,Vector2(26,12)*s,Vector2(54,16)*s,Vector2(48,20)*s]),col.lightened(0.24))
			draw_colored_polygon(PackedVector2Array([Vector2(48,20)*s,Vector2(54,16)*s,Vector2(54,46)*s,Vector2(48,52)*s]),col.darkened(0.36))
			draw_rect(Rect2(Vector2(23,31)*s,Vector2(18,6)*s),Color("#d5cab0"))
			draw_rect(Rect2(Vector2(27,8)*s,Vector2(12,6)*s),Color("#3f4740"))
		"bandage","rag","map":
			draw_colored_polygon(pts,col)
			draw_line(Vector2(19,32)*s,Vector2(45,43)*s,col.darkened(0.2),10*s.x)
			if item_id=="bandage":
				draw_rect(Rect2(Vector2(27,21)*s,Vector2(7,21)*s),Color("#b55c44"))
				draw_rect(Rect2(Vector2(20,28)*s,Vector2(21,7)*s),Color("#b55c44"))
		"ammo","rifle_ammo","nails","wire":
			for i in range(3):
				draw_rect(Rect2(Vector2(16+i*12,23-i*3)*s,Vector2(7,29)*s),col)
				draw_colored_polygon(PackedVector2Array([Vector2(16+i*12,23-i*3)*s,Vector2(19.5+i*12,14-i*3)*s,Vector2(23+i*12,23-i*3)*s]),col.lightened(0.22))
		_:
			draw_colored_polygon(pts,col.lightened(0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(10,22)*s,Vector2(29,34)*s,Vector2(29,52)*s,Vector2(10,40)*s]),col.darkened(0.13))
			draw_colored_polygon(PackedVector2Array([Vector2(29,34)*s,Vector2(55,23)*s,Vector2(55,41)*s,Vector2(29,52)*s]),col.darkened(0.3))
			if item_id=="backpack":
				draw_rect(Rect2(Vector2(30,35)*s,Vector2(17,12)*s),col.lightened(0.2))
