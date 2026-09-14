extends Node
# Small original synthesized cues; no third-party recordings.
var clips:Dictionary={}
func _ready() -> void:
	for id in ["shot","hit","pickup","hurt","craft","engine"]:
		clips[id]=make_clip(id)
func make_clip(id:String) -> AudioStreamWAV:
	var rate:int=22050
	var duration:float=0.26 if id in ["shot","hurt"] else 0.13
	var samples:int=int(duration*rate)
	var bytes:PackedByteArray=PackedByteArray()
	bytes.resize(samples*2)
	var rng:RandomNumberGenerator=RandomNumberGenerator.new()
	rng.seed=abs(id.hash())
	for i in range(samples):
		var t:float=float(i)/rate
		var envelope:float=pow(1.0-float(i)/samples,3)
		var value:float=0
		match id:
			"shot":value=(rng.randf_range(-1,1)*0.75+sin(t*TAU*65)*0.25)*envelope
			"hit","hurt":value=(rng.randf_range(-1,1)*0.3+sin(t*TAU*110)*0.4)*envelope
			"engine":value=(sin(t*TAU*65)+sin(t*TAU*130)*0.4)*envelope*0.3
			_:value=sin(t*TAU*(620 if id=="pickup" else 380))*envelope*0.3
		var sample:int=clampi(int(value*23000),-32768,32767)
		bytes.encode_s16(i*2,sample)
	var wav:AudioStreamWAV=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=rate
	wav.data=bytes
	return wav
func play(id:String,at:Vector3) -> void:
	if not clips.has(id) or DisplayServer.get_name()=="headless":return
	var p:AudioStreamPlayer3D=AudioStreamPlayer3D.new()
	p.stream=clips[id]
	p.max_distance=150 if id=="shot" else 25
	p.unit_size=5
	add_child(p)
	p.global_position=at
	p.finished.connect(p.queue_free)
	p.play()
