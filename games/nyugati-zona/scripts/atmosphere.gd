extends Node3D
var environment:Environment
var sun:DirectionalLight3D
var moon:DirectionalLight3D
var sky_material:ShaderMaterial
var hour:float=17.4
var day_seconds:float=2400.0
var cycle:bool=true
var cloud_cover:float=0.52
var clock:float=0.0
var quality:int=2
var fog_on:bool=true
var shadows_on:bool=true
var wind_time:float=0.0
func _ready() -> void:
	environment=Environment.new()
	environment.background_mode=Environment.BG_SKY
	var sky:Sky=Sky.new()
	sky_material=ShaderMaterial.new()
	sky_material.shader=load("res://shaders/sky.gdshader")
	sky.sky_material=sky_material
	sky.radiance_size=Sky.RADIANCE_SIZE_128
	sky.process_mode=Sky.PROCESS_MODE_REALTIME
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_sky_contribution=0.3
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled=true
	environment.fog_density=0.0018
	environment.fog_sky_affect=0.18
	environment.adjustment_enabled=true
	environment.adjustment_saturation=0.92
	environment.adjustment_contrast=1.04
	var we:WorldEnvironment=WorldEnvironment.new()
	we.environment=environment
	add_child(we)
	sun=DirectionalLight3D.new()
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits=true
	sun.shadow_normal_bias=1.4
	sun.directional_shadow_max_distance=160.0
	sun.shadow_enabled=true
	add_child(sun)
	moon=DirectionalLight3D.new()
	moon.light_color=Color("#7488ba")
	moon.shadow_enabled=false
	add_child(moon)
	refresh()
func _process(delta:float) -> void:
	wind_time+=delta
	if cycle:
		hour=fposmod(hour+delta*24.0/day_seconds,24.0)
	clock+=delta
	if clock>0.15:
		clock=0
		refresh()
func refresh() -> void:
	var angle:float=(hour-6.0)/24.0*TAU
	var height:float=sin(angle)
	var daylight:float=clampf((height+0.10)*2.1,0.0,1.0)
	var dusk:float=1.0-clampf(absf(height)*2.8,0.0,1.0)
	var dir:Vector3=Vector3(cos(angle)*0.82,height,-0.45).normalized()
	sun.rotation=Vector3(-asin(dir.y),atan2(dir.x,dir.z),0)
	sun.light_energy=maxf(0.0,height)*1.35+0.10*daylight
	sun.light_color=Color("#fff0cc").lerp(Color("#ff9c54"),dusk)
	sun.visible=height>-0.08
	moon.rotation_degrees=Vector3(-44,-30,0)
	moon.light_energy=0.18*(1.0-daylight)
	environment.ambient_light_color=Color("#6b7891").lerp(Color("#b7bdc9"),daylight)
	environment.ambient_light_energy=lerpf(0.25,0.67,daylight)
	environment.fog_light_color=Color("#252f48").lerp(Color("#a89b83").lerp(Color("#c9916f"),dusk),daylight)
	sky_material.set_shader_parameter("zenith",Color("#0b162e").lerp(Color("#48759b").lerp(Color("#454c76"),dusk),daylight))
	sky_material.set_shader_parameter("horizon",Color("#232c45").lerp(Color("#c3c7b4").lerp(Color("#ed9863"),dusk),daylight))
	sky_material.set_shader_parameter("cloud_light",Color("#2b344e").lerp(Color("#e2ded0").lerp(Color("#eba775"),dusk),daylight))
	sky_material.set_shader_parameter("cloud_shadow",Color("#161e30").lerp(Color("#8497a5").lerp(Color("#706072"),dusk),daylight))
	sky_material.set_shader_parameter("sun_dir",dir)
	sky_material.set_shader_parameter("daylight",daylight)
	sky_material.set_shader_parameter("cloud_cover",cloud_cover)
	sky_material.set_shader_parameter("wind_time",wind_time)
func apply_quality(level:int,shadow:bool,fog:bool) -> void:
	quality=level
	shadows_on=shadow
	fog_on=fog
	sun.shadow_enabled=shadow
	sun.directional_shadow_max_distance=[55.0,95.0,160.0,250.0][level]
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL if level==0 else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	RenderingServer.directional_shadow_atlas_set_size([1024,2048,4096,8192][level],true)
	environment.fog_enabled=fog
	var forward:bool=RenderingServer.get_current_rendering_method()=="forward_plus"
	environment.ssao_enabled=forward and level>=2
	environment.ssao_radius=1.6
	environment.ssao_intensity=1.3
	environment.glow_enabled=level>=2
	environment.glow_intensity=0.5
	environment.volumetric_fog_enabled=forward and fog and level==3
	environment.volumetric_fog_density=0.008
