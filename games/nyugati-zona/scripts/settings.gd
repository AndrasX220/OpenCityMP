extends RefCounted
const PATH:String="user://settings.cfg"
var values:Dictionary={"quality":2,"shadows":true,"fog":true,"msaa":2,"scale":1.0,"distance":750,"fov":78,"sensitivity":0.0022,"fullscreen":false,"vsync":true,"fps":120,"volume":0.65,"hour":17.4,"cycle":true,"clouds":0.52}
func load_settings() -> void:
	var c:ConfigFile=ConfigFile.new()
	if c.load(PATH)!=OK:
		return
	for k in values:
		values[k]=c.get_value("settings",k,values[k])
	values.quality=clampi(int(values.quality),0,3)
	values.msaa=clampi(int(values.msaa),0,3)
	values.scale=clampf(float(values.scale),0.5,1.5)
	values.fov=clampf(float(values.fov),60,110)
	values.sensitivity=clampf(float(values.sensitivity),0.0005,0.006)
	values.distance=clampi(int(values.distance),200,1600)
func save_settings() -> Error:
	var c:ConfigFile=ConfigFile.new()
	for k in values:
		c.set_value("settings",k,values[k])
	return c.save(PATH)
func apply(game:Node) -> void:
	game.atmosphere.apply_quality(int(values.quality),bool(values.shadows),bool(values.fog))
	game.atmosphere.hour=float(values.hour)
	game.atmosphere.cycle=bool(values.cycle)
	game.atmosphere.cloud_cover=float(values.clouds)
	var v:Viewport=game.get_viewport()
	v.msaa_3d=int(values.msaa)
	v.scaling_3d_scale=float(values.scale)
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=int(values.fps)
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.001,float(values.volume))))
	if game.local_player:
		game.local_player.camera.fov=float(values.fov)
		game.local_player.camera.far=float(values.distance)
