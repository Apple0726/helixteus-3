shader_type canvas_item;

uniform vec2 position;
uniform float time;

uniform int iterations:hint_range(1, 20, 1) = 12;
uniform float formuparam2 = 0.79;
uniform int volsteps:hint_range(0, 10, 1) = 7;
uniform float stepsize = 0.290;
uniform float zoom = 1.0;
uniform float tile:hint_range(0.8, 1.5, 0.01) = 0.850;
uniform float speed2 = 0.2;
 
uniform float brightness:hint_range(0.0, 0.01, 0.0001) = 0.0015;
//uniform float darkmatter = 0.100;
uniform float distfading = 0.560;
uniform float saturation = 0.90;


uniform float transverseSpeed = 1.0; //zoom;
uniform float cloud = 0.17;
uniform vec4 color:source_color = vec4(1.0);
uniform float max_alpha:hint_range(0.0, 1.0, 0.01) = 1.0;
 
float triangle(float x, float a) { 
	float output2 = 2.0*abs(  3.0*  ( (x/a) - floor( (x/a) + 0.5) ) ) - 1.0;
	return output2;
}
 
float field(in vec3 p) {	
	float strength = 7. + .03 * log(1.e-6 + fract(sin(time) * 373.11));
	float accum = 0.;
	float prev = 0.;
	float tw = 0.;	

	for (int i = 0; i < 6; ++i) {
		float mag = dot(p, p);
		p = abs(p) / mag + vec3(-.5, -.8 + 0.1*sin(-time*0.1 + 2.0), -1.1+0.3*cos(time*0.3));
		float w = exp(-float(i) / 7.);
		accum += w * exp(-strength * pow(abs(mag - prev), 2.3));
		tw += w;
		prev = mag;
	}
	return max(0., 5. * accum / tw - .7);
}

void fragment() {
    vec2 uv2 = 2. * FRAGCOORD.xy * zoom / vec2(512) - 1.;
	vec2 uvs = uv2 * vec2(512)  / 512.;
	
	//float time = TIME;
	float time2 = time;               
    float speed = -speed2;
    speed = .005 * cos(time2*0.02 + 3.1415926/4.0);          
	//speed = 0.0;	
    float formuparam = formuparam2;
	
    	//get coords and direction	
	vec2 uv = uvs;		       
	//mouse rotation
	float a_xz = 0.9;
	float a_yz = -.6;
	float a_xy = 0.9 + time*0.08;	
	
	mat2 rot_xz = mat2(vec2(cos(a_xz),sin(a_xz)),vec2(-sin(a_xz),cos(a_xz)));	
	mat2 rot_yz = mat2(vec2(cos(a_yz),sin(a_yz)),vec2(-sin(a_yz),cos(a_yz)));		
	mat2 rot_xy = mat2(vec2(cos(a_xy),sin(a_xy)),vec2(-sin(a_xy),cos(a_xy)));
	
	float v2 =1.0;	
	vec3 dir=vec3(uv,1.); 
	vec3 from=vec3(0.0, 0.0,0.0);                               
        from.x -= 2.0*(position.x-0.5);
        from.y -= 2.0*(position.y-0.5);

	vec3 forward = vec3(0.,0.,1.);   
	from.x += transverseSpeed*(1.0)*cos(0.01*time) + 0.001*time;
	from.y += transverseSpeed*(1.0)*sin(0.01*time) +0.001*time;
	from.z += 0.003*time;	
	
	dir.xy*=rot_xy;
	forward.xy *= rot_xy;
	dir.xz*=rot_xz;
	forward.xz *= rot_xz;	
	dir.yz*= rot_yz;
	forward.yz *= rot_yz;
	
	from.xy*=-1.0*rot_xy;
	from.xz*=rot_xz;
	from.yz*= rot_yz;
	 
	//zoom
	float zooom = (time2-3311.)*speed;
	from += forward* zooom;
	float sampleShift = mod( zooom, stepsize );
	 
	float zoffset = -sampleShift;
	sampleShift /= stepsize; // make from 0 to 1
	
	//volumetric rendering
	float s=0.24;
	float s3 = s + stepsize/2.0;
	vec3 v=vec3(0.);
	float t3 = 0.0;	
	
	vec3 backCol2 = vec3(0.);
	for (float r=0.0; r<float(volsteps); r++) {
		vec3 p2=from+(s+zoffset)*dir;// + vec3(0.,0.,zoffset);
		vec3 p3=from+(s3+zoffset)*dir;// + vec3(0.,0.,zoffset);
		
		p2 = abs(vec3(tile)-mod(p2,vec3(tile*2.))); // tiling fold
		p3 = abs(vec3(tile)-mod(p3,vec3(tile*2.))); // tiling fold		
		// #ifdef cloud
		t3 = field(p3);
		
		float pa,a=pa=0.;
		for (int i=0; i<iterations; i++) {
			p2=abs(p2)/dot(p2,p2)-formuparam; // the magic formula
			//p=abs(p)/max(dot(p,p),0.005)-formuparam; // another interesting way to reduce noise
			float D = abs(length(p2)-pa); // absolute sum of average change
			a += i > 7 ? min( 12., D) : D;
			pa=length(p2);
		}
		
		
		//float dm=max(0.,darkmatter-a*a*.001); //dark matter
		a*=a*a; // add contrast
		// brightens stuff up a bit
		float s1 = s+zoffset;
		// need closed form expression for this, now that we shift samples
		float fade = pow(distfading,max(0.,float(r)-sampleShift));		
		//if (r>3.0) fade*=1.-dm; // dark matter, don't render near
		//t3 += fade;		
		v+=fade;
	       	//backCol2 -= fade;

		// fade out samples as they approach the camera
		if( r == 0.0 )
			fade *= (1. - (sampleShift));
		// fade in samples as they approach from the distance
		if( r == float(volsteps)-1.0 )
			fade *= sampleShift;
		v+=vec3(s1,s1*s1,s1*s1*s1*s1)*a*brightness*fade; // coloring based on distance
		
		backCol2 += mix(.4, 1., v2) * vec3(1.8 * t3 * t3 * t3, 1.4 * t3 * t3, t3) * fade;

		
		s+=stepsize;
		s3 += stepsize;		
	}
		       
	v = mix(vec3(length(v)),v,saturation); //color adjust	

	vec4 forCol2 = vec4(v*.01,1.);	
	backCol2 *= cloud;	
	//backCol2.b *= 1.8;
	backCol2.b *= color.b * 2.0;
	//backCol2.r *= 0.05;	
	backCol2.r *= color.r;	
	backCol2.g *= color.g;	
	
	backCol2.b = 0.5*mix(backCol2.g, backCol2.b, 0.8);
	//backCol2.g = 0.0;
	backCol2.bg = mix(backCol2.gb, backCol2.bg, 0.5*(cos(time*0.01) + 1.0));	
	COLOR = forCol2 + vec4(backCol2, 1.0);
	COLOR.a = min(max_alpha, COLOR.a);
}