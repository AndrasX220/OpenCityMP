extends CanvasLayer
const Data=preload("res://scripts/data.gd")
const ItemIcon=preload("res://scripts/item_icon.gd")
var game:Node
var root:Control
var overlay:Control
var hud:Control
var screen:String="main"
var info:Label
var vital:Label
var time_label:Label
var prompt:Label
var quick:Label
var toast_label:Label
var toast_time:float=0
var cross:Label
var hud_timer:float=0
var current_container:String=""
var red_flash:ColorRect
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme=make_theme()
	hud=Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	info=label_at(hud,"NYUGATI ZÓNA",Vector2(30,24),25,Color("#e8dfc5"))
	label_at(hud,"NYUGAT-MAGYARORSZÁG  /  2008",Vector2(31,57),13,Color("#b0b19c"))
	time_label=label_at(hud,"",Vector2(1270,26),17)
	vital=label_at(hud,"",Vector2(30,718),19)
	quick=label_at(hud,"",Vector2(470,821),16)
	prompt=label_at(hud,"",Vector2(460,660),19,Color("#eed5a0"))
	prompt.size=Vector2(850,95)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cross=label_at(hud,"·",Vector2(784,422),32)
	toast_label=label_at(hud,"",Vector2(480,145),21,Color("#e9d89f"))
	toast_label.size=Vector2(700,70)
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	red_flash=ColorRect.new()
	red_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	red_flash.color=Color(0.5,0.02,0,0)
	red_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(red_flash)
	overlay=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	show_main()
func make_theme() -> Theme:
	var t:Theme=Theme.new()
	t.default_font_size=18
	t.set_color("font_color","Label",Color("#d6d5bd"))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var s:StyleBoxFlat=StyleBoxFlat.new()
		s.bg_color=Color("#222c26") if state=="normal" else Color("#3b4738")
		if state=="disabled":
			s.bg_color=Color("#1d241f")
		s.border_color=Color("#5a6650")
		s.set_border_width_all(1)
		s.content_margin_left=16
		s.content_margin_right=16
		s.content_margin_top=12
		s.content_margin_bottom=12
		t.set_stylebox(state,"Button",s)
		t.set_stylebox(state,"OptionButton",s)
	t.set_color("font_color","Button",Color("#e4dfc8"))
	t.set_color("font_disabled_color","Button",Color("#62695c"))
	var p:StyleBoxFlat=StyleBoxFlat.new()
	p.bg_color=Color(0.065,0.09,0.075,0.96)
	p.border_color=Color("#56634f")
	p.set_border_width_all(1)
	p.content_margin_left=22
	p.content_margin_right=22
	p.content_margin_top=20
	p.content_margin_bottom=20
	t.set_stylebox("panel","PanelContainer",p)
	return t
func label_at(parent:Node,words:String,pos:Vector2,font_size:int=18,color:Color=Color("#d6d5bd")) -> Label:
	var l:Label=Label.new()
	l.text=words
	l.position=pos
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
func caption(parent:Node,words:String,font_size:int=18) -> Label:
	var l:Label=Label.new()
	l.text=words
	l.add_theme_font_size_override("font_size",font_size)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l
func button(parent:Node,words:String,action:Callable) -> Button:
	var b:Button=Button.new()
	b.text=words
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y=48
	b.pressed.connect(action)
	parent.add_child(b)
	return b
func panel(pos:Vector2,size:Vector2,title:String) -> VBoxContainer:
	var p:PanelContainer=PanelContainer.new()
	p.position=pos
	p.size=size
	overlay.add_child(p)
	var scroll:ScrollContainer=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var v:VBoxContainer=VBoxContainer.new()
	v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation",12)
	scroll.add_child(v)
	caption(v,title,28)
	return v
func clear(next:String) -> void:
	for c in overlay.get_children():
		c.queue_free()
	screen=next
	overlay.visible=next!=""
	hud.visible=game.playing and next not in ["main","network"]
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if next!="" else Input.MOUSE_MODE_CAPTURED
	# Solo pause/settings are an actual pause. Co-op keeps the server running.
	get_tree().paused=game.playing and not game.net.online and next in ["pause","settings"]
func is_open() -> bool:
	return screen!=""
func close() -> void:
	clear("")
func show_main() -> void:
	clear("main")
	var v:VBoxContainer=panel(Vector2(65,105),Vector2(520,690),"NYUGATI ZÓNA")
	caption(v,"TÚLÉLNI. EGYÜTT. OTTHONT ÚJRA.",18)
	caption(v,"2008. október 12.\nBerekfalva, a nyugati karanténzóna.",21)
	caption(v,"A főút még hazavezet. Csak már nincs, aki várjon.",18)
	button(v,"ÚJ TÚLÉLŐ  →",func():game.start_solo(false))
	button(v,"FOLYTATÁS",func():game.start_solo(true)).disabled=not FileAccess.file_exists("user://survival.json")
	button(v,"BARÁTOKKAL  /  LAN CO-OP",show_network)
	button(v,"GRAFIKA ÉS BEÁLLÍTÁSOK",show_settings)
	button(v,"KILÉPÉS",func():get_tree().quit())
	caption(v,"KORAI PROTOTÍPUS  0.1\nSaját low-poly modellek · 1,2 × 1,2 km",13)
func show_pause() -> void:
	clear("pause")
	var v:VBoxContainer=panel(Vector2(565,160),Vector2(470,570),"PIHENŐ")
	button(v,"VISSZA A ZÓNÁBA",close)
	button(v,"MENTÉS",func():game.save_game())
	button(v,"GRAFIKA ÉS BEÁLLÍTÁSOK",show_settings)
	button(v,"IRÁNYÍTÁS",show_help)
	button(v,"FŐMENÜ",func():game.return_to_menu())
	button(v,"KILÉPÉS",func():game.save_game(); get_tree().quit())
func show_help() -> void:
	clear("help")
	var v:VBoxContainer=panel(Vector2(430,100),Vector2(740,700),"IRÁNYÍTÁS")
	caption(v,"WASD  mozgás / vezetés\nEgér  körbenézés · Shift  sprint · Space  ugrás / fék\nCtrl  guggolás · V  első / harmadik személy\nE  használat / beszállás / kiszállás\nF  zseblámpa · R  újratöltés\nBal egér  ütés / lövés / építés\nJobb egér  célzás\n1  ököl · 2  balta · 3  pisztoly · 4  karabély\nTab  felszerelés · C  craft · M  térkép\nB  építési mód · Q  elemváltás · T  forgatás 45°\nG  rönk lerakása · F5  mentés · Esc  menü",20)
	button(v,"RENDBEN",close)
func show_network() -> void:
	clear("network")
	var v:VBoxContainer=panel(Vector2(500,140),Vector2(600,620),"EGYÜTT TÚLÉLNI")
	caption(v,"Kísérleti helyi hálózatos co-op, 2–8 játékos.\nA fogadó gép szimulálja a közös világot.\nUDP port: 27808. Ugyanaz a projektverzió kell.",18)
	button(v,"ÚJ VILÁG FOGADÁSA",func():game.start_host())
	caption(v,"Fogadó gép IP-címe")
	var address:LineEdit=LineEdit.new()
	address.text="127.0.0.1"
	address.custom_minimum_size.y=46
	v.add_child(address)
	button(v,"CSATLAKOZÁS",func():game.join_host(address.text.strip_edges()))
	button(v,"VISSZA",show_main)
func show_settings() -> void:
	clear("settings")
	var v:VBoxContainer=panel(Vector2(450,65),Vector2(720,775),"KÉP ÉS HANG")
	var values:Dictionary=game.settings.values
	option(v,"Minőségi profil",["Alacsony","Közepes","Magas","Ultra"],int(values.quality),func(i):
		values.quality=i
		values.msaa=[0,1,2,3][i]
		values.distance=[350,550,850,1200][i]
		game.settings.apply(game))
	toggle(v,"Dinamikus napárnyék",bool(values.shadows),func(b):values.shadows=b; game.settings.apply(game))
	toggle(v,"Távolsági köd",bool(values.fog),func(b):values.fog=b; game.settings.apply(game))
	option(v,"Élsimítás",["Ki","MSAA 2×","MSAA 4×","MSAA 8×"],int(values.msaa),func(i):values.msaa=i; game.settings.apply(game))
	slider(v,"3D felbontásskála",0.5,1.5,0.05,float(values.scale),func(n):values.scale=n; game.settings.apply(game))
	slider(v,"Látótávolság (m)",200,1600,50,float(values.distance),func(n):values.distance=n; game.settings.apply(game))
	slider(v,"Látómező",60,110,1,float(values.fov),func(n):values.fov=n; game.settings.apply(game))
	slider(v,"Egér érzékenysége",0.0005,0.006,0.0001,float(values.sensitivity),func(n):values.sensitivity=n)
	toggle(v,"Teljes képernyő",bool(values.fullscreen),func(b):values.fullscreen=b; game.settings.apply(game))
	toggle(v,"V-Sync",bool(values.vsync),func(b):values.vsync=b; game.settings.apply(game))
	option(v,"FPS limit",["60","120","144","Korlátlan"],[60,120,144,0].find(int(values.fps)),func(i):values.fps=[60,120,144,0][i]; game.settings.apply(game))
	slider(v,"Hangerő",0,1,0.05,float(values.volume),func(n):values.volume=n; game.settings.apply(game))
	if game.authoritative():
		slider(v,"Napszak (óra)",0,23.9,0.1,game.atmosphere.hour,func(n):values.hour=n; game.atmosphere.hour=n)
		toggle(v,"Nappal és éjszaka változása",bool(values.cycle),func(b):values.cycle=b; game.atmosphere.cycle=b)
		slider(v,"Felhőzet",0.15,0.8,0.05,float(values.clouds),func(n):values.clouds=n; game.atmosphere.cloud_cover=n)
	caption(v,"Renderelő: "+RenderingServer.get_current_rendering_method()+"\nForward+ alatt a Magas profil SSAO-t, az Ultra térfogati ködöt is használ. A renderelőváltás újraindítással lehetséges; lásd az indítófájlokat.",14)
	button(v,"MENTÉS ÉS VISSZA",func():
		var err:Error=game.settings.save_settings()
		if err!=OK:toast("A beállítás mentése nem sikerült.")
		if game.playing:show_pause()
		else:show_main())
func toggle(v:Node,title:String,value:bool,changed:Callable) -> void:
	var c:CheckButton=CheckButton.new()
	c.text=title
	c.button_pressed=value
	c.toggled.connect(changed)
	v.add_child(c)
func option(v:Node,title:String,items:Array,selected:int,changed:Callable) -> void:
	caption(v,title,16)
	var o:OptionButton=OptionButton.new()
	for item in items:o.add_item(str(item))
	o.select(maxi(0,selected))
	o.item_selected.connect(changed)
	v.add_child(o)
func slider(v:Node,title:String,a:float,b:float,step:float,value:float,changed:Callable) -> void:
	var l:Label=caption(v,title+"  ·  "+str(snappedf(value,step)),16)
	var s:HSlider=HSlider.new()
	s.min_value=a
	s.max_value=b
	s.step=step
	s.value=value
	s.custom_minimum_size.y=24
	s.value_changed.connect(func(n):l.text=title+"  ·  "+str(snappedf(n,step)); changed.call(n))
	v.add_child(s)
func show_inventory(container_id:String="") -> void:
	clear("inventory")
	current_container=container_id
	var p:Node=game.local_player
	var left:VBoxContainer=panel(Vector2(110,95),Vector2(580,710),"FELSZERELÉS")
	caption(left,"%.1f / %.0f kg  ·  %s" % [Data.mass(p.inventory),p.capacity(),"HÁTIZSÁK" if p.inventory.has("backpack") else "ZSEBEK"],17)
	var grid:GridContainer=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	left.add_child(grid)
	for id in p.inventory:
		if not Data.ITEMS.has(id):continue
		item_card(grid,id,int(p.inventory[id]),func():game.request("use",{"item":id}))
	button(left,"TÉRKÉP",show_map)
	button(left,"BARKÁCSOLÁS",show_craft)
	button(left,"VISSZA",close)
	var right:VBoxContainer=panel(Vector2(740,95),Vector2(710,710),"KÖZELBEN")
	if container_id!="" and game.things.has(container_id):
		var t:Node=game.things[container_id]
		caption(right,t.title())
		var contents:Dictionary=t.data.get("items",{})
		for id in contents:
			button(right,"%s × %d  → FELVESZ" % [Data.ITEMS[id].name,int(contents[id])],func():game.request("take",{"id":container_id,"item":id}))
		if t.kind=="crate":
			caption(right,"ELHELYEZÉS A LÁDÁBAN",16)
			for id in p.inventory:
				button(right,"←  "+str(Data.ITEMS[id].name)+" × 1",func():game.request("deposit",{"id":container_id,"item":id}))
	else:
		caption(right,"Készletekhez nézz egy ládára, majd E.\n\nKattints az ételre, vízre vagy kötésre a használathoz. A fegyverre kattintva felszereled.\n\nJavítás és tankolás: nézz az autóra, majd E.\n\nAz induló túraláda a buszmegállónál van. A balta a közeli erdészládában található.",19)
func item_card(parent:Node,id:String,count:int,action:Callable) -> void:
	var b:Button=Button.new()
	b.custom_minimum_size=Vector2(124,120)
	b.tooltip_text=str(Data.ITEMS[id].name)
	b.pressed.connect(action)
	parent.add_child(b)
	var icon:Control=ItemIcon.new()
	icon.item_id=id
	icon.position=Vector2(30,8)
	icon.size=Vector2(64,64)
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var l:Label=label_at(b,str(Data.ITEMS[id].name)+"\n× "+str(count),Vector2(5,76),12)
	l.size=Vector2(114,40)
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func show_craft() -> void:
	clear("craft")
	var v:VBoxContainer=panel(Vector2(400,75),Vector2(820,750),"BARKÁCSOLÁS")
	caption(v,"Munkapad I: "+("ELÉRHETŐ" if game.near_bench(game.local_player) else "menj 4 méteren belül egy munkapadhoz"),17)
	for id in Data.RECIPES:
		var r:Dictionary=Data.RECIPES[id]
		var text:String=str(r.name)+"  ·  "
		for material in r.need:
			text+=str(Data.ITEMS[material].name)+" "+str(r.need[material])+"  "
		var b:Button=button(v,text,func():game.request("craft",{"recipe":id}))
		b.disabled=not Data.can_pay(game.local_player.inventory,r.need) or (r.station>0 and not game.near_bench(game.local_player))
	button(v,"ÉPÍTÉSI MÓD  [B]",func():close(); game.toggle_build())
	button(v,"VISSZA",close)
func show_map() -> void:
	clear("map")
	var v:VBoxContainer=panel(Vector2(340,60),Vector2(930,785),"BEREKFALVA ÉS KÖRNYÉKE")
	if not game.local_player.inventory.has("map"):
		caption(v,"Nincs nálad térkép. Keress a buszmegálló túrafelszerelésében.")
	else:
		var map:Control=load("res://scripts/map_ui.gd").new()
		map.game=game
		map.custom_minimum_size=Vector2(820,565)
		v.add_child(map)
		caption(v,"Turistatérkép · kézzel jelölt helyek · kattintással saját jelölő.\nA térkép nem mutat élő GPS-pozíciót.",14)
	button(v,"VISSZA",close)
func show_vehicle(id:String) -> void:
	clear("vehicle")
	var c:Node=game.vehicles[id]
	var v:VBoxContainer=panel(Vector2(475,145),Vector2(650,620),"JÁRMŰ")
	caption(v,c.title(),20)
	button(v,"BESZÁLLÁS",func():game.request("enter",{"id":id}); close())
	button(v,"AKKUMULÁTOR BESZERELÉSE",func():game.request("car_battery",{"id":id}))
	button(v,"JAVÍTÓKÉSZLET HASZNÁLATA",func():game.request("car_repair",{"id":id}))
	button(v,"TANKOLÁS · 5 L BENZIN",func():game.request("car_fuel",{"id":id}))
	button(v,"VISSZA",close)
func show_death() -> void:
	clear("dead")
	var v:VBoxContainer=panel(Vector2(480,205),Vector2(640,400),"A ZÓNA ELVETTE A RÉSZÉT.")
	caption(v,"A felszerelésed a halálod helyén maradt.\nA következő túlélő a buszmegállónál indul.")
	button(v,"ÚJ TÚLÉLŐ",func():game.request("respawn",{}); close())
func toast(message:String) -> void:
	toast_label.text=message
	toast_time=4
func _process(delta:float) -> void:
	toast_time=maxf(0,toast_time-delta)
	toast_label.visible=toast_time>0
	if not game.playing or not game.local_player:return
	hud_timer+=delta
	if hud_timer<0.12:return
	hud_timer=0
	var p:Node=game.local_player
	if p.health<=0 and screen!="dead":show_death()
	vital.text="ÉLETERŐ   %03d     ÁLLÓKÉPESSÉG   %03d\nÉHSÉG      %03d     SZOMJÚSÁG          %03d\nTEHER       %.1f / %.0f kg%s" % [p.health,p.stamina,p.hunger,p.thirst,Data.mass(p.inventory),p.capacity(),"   VÉRZÉS!" if p.bleeding>0 else ""]
	var hour:int=int(game.atmosphere.hour)
	time_label.text="OKT 12.   %02d:%02d\n%d FPS   %s" % [hour,int((game.atmosphere.hour-hour)*60),Engine.get_frames_per_second(),"CO-OP" if game.net.online else "SOLO"]
	quick.text="[1] ÖKÖL   [2] BALTA   [3] PISZTOLY   [4] KARABÉLY\n[TAB] FELSZERELÉS   [C] CRAFT   [B] ÉPÍTÉS   [M] TÉRKÉP"
	if p.equipment in ["pistol","rifle"]:
		quick.text+="\nTÁR: %d   [R] ÚJRATÖLTÉS" % (p.magazine if p.equipment=="pistol" else p.rifle_magazine)
	prompt.text=game.interaction_prompt() if screen=="" else ""
	if game.build_mode:
		prompt.text=game.build_prompt()
	if p.vehicle_id!="" and game.vehicles.has(p.vehicle_id):
		var c:Node=game.vehicles[p.vehicle_id]
		prompt.text="%.0f KM/H   ·   %.1f L   ·   %d%%   [E] KISZÁLLÁS" % [absf(c.speed)*3.6,c.fuel,c.condition]
	cross.visible=screen=="" and p.vehicle_id==""
	red_flash.color.a=maxf(0,(35-p.health)/150.0)
func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if screen=="":show_pause()
		elif game.playing:close()
		else:show_main()
		get_viewport().set_input_as_handled()
		return
	if not game.playing:return
	if event.is_action_pressed("inventory"):
		if screen=="inventory":close()
		else:show_inventory()
	elif event.is_action_pressed("craft"):
		if screen=="craft":close()
		else:show_craft()
	elif event.is_action_pressed("map"):
		if screen=="map":close()
		else:show_map()
