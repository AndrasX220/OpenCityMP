shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
varying vec3 wp;
float hash21(vec2 p){return fract(sin(dot(p,vec2(13.7,91.3)))*43758.54);}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 tile=floor(wp.xz*0.35);
	float n=hash21(tile);
	float broad=hash21(floor(wp.xz/14.0));
	vec3 grass=mix(vec3(0.20,0.25,0.105),vec3(0.32,0.33,0.16),broad);
	ALBEDO=grass*(0.90+n*0.15);
	ROUGHNESS=1.0;
}