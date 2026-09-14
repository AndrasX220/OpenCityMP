shader_type sky;
uniform vec3 zenith : source_color = vec3(0.18,0.27,0.43);
uniform vec3 horizon : source_color = vec3(0.94,0.48,0.24);
uniform vec3 cloud_light : source_color = vec3(1.0,0.65,0.36);
uniform vec3 cloud_shadow : source_color = vec3(0.30,0.28,0.40);
uniform vec3 sun_dir = vec3(-0.6,0.2,-0.7);
uniform float cloud_cover = 0.5;
uniform float daylight = 1.0;
uniform float wind_time = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void sky(){
	float h=max(EYEDIR.y,0.0);
	vec3 c=mix(horizon,zenith,pow(h,0.45));
	float sd=dot(EYEDIR,normalize(sun_dir));
	c+=vec3(1.0,0.56,0.24)*pow(max(sd,0.0),24.0)*0.35*daylight;
	c+=vec3(2.0,1.5,0.85)*smoothstep(0.9995,0.9998,sd)*daylight;
	if(h>0.03){
		vec2 p=EYEDIR.xz/max(h,0.12)*3.0+vec2(wind_time*0.008,0.0);
		p=floor(p*7.0)/7.0;
		float n=noise(p*0.65)*0.64+noise(p*1.5)*0.25+noise(p*3.0)*0.11;
		float a=step(1.0-cloud_cover,n)*smoothstep(0.03,0.17,h);
		float bands=floor(n*5.0)/5.0;
		c=mix(c,mix(cloud_shadow,cloud_light,bands),a*0.94);
	}
	float stars=step(0.9992,hash(floor(SKY_COORDS*vec2(1500.0,800.0))));
	c+=stars*vec3(0.75,0.82,1.0)*(1.0-daylight)*smoothstep(0.1,0.4,h);
	COLOR=c;
}