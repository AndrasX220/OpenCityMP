extends Control
const Data=preload("res://scripts/data.gd")
var game:Node
var markers:Array[Vector2]=[]
func _draw() -> void:
	var rect:Rect2=Rect2(Vector2.ZERO,size)
	draw_rect(rect,Color("#c7c09a"))
	for i in range(13):
		draw_line(Vector2(i*size.x/12,0),Vector2(i*size.x/12,size.y),Color("#aaa881"),1)
		draw_line(Vector2(0,i*size.y/12),Vector2(size.x,i*size.y/12),Color("#aaa881"),1)
	var center:Vector2=size/2
	var scale:float=size.y/700
	for forest in [Vector2(-175,-80),Vector2(-205,180),Vector2(260,70)]:
		draw_circle(center+forest*scale,72*scale,Color("#8e9e72"))
	draw_circle(center+Vector2(250,-160)*scale,52*scale,Color("#829e9b"))
	draw_line(center+Vector2(0,-320)*scale,center+Vector2(0,320)*scale,Color("#787967"),5)
	for z in [-94,150]:
		draw_line(center+Vector2(-255,z)*scale,center+Vector2(255,z)*scale,Color("#8c8c75"),4)
	var font:Font=ThemeDB.fallback_font
	for place in Data.PLACES:
		var p:Vector2=center+place.p*scale
		draw_rect(Rect2(p-Vector2(4,4),Vector2(8,8)),Color("#5a614d"))
		draw_string(font,p+Vector2(9,-6),str(place.name),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#343e32"))
	for p in markers:
		draw_line(p-Vector2(5,5),p+Vector2(5,5),Color("#9d493b"),2)
		draw_line(p-Vector2(-5,5),p+Vector2(-5,5),Color("#9d493b"),2)
func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		markers.append(event.position)
		queue_redraw()
