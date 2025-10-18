shader_type spatial;
render_mode cull_disabled;

// Character position in world space
uniform vec3 character_position;

// Pass world-space vertex position
varying vec3 world_vertex;

uniform float dither_grain : hint_range(0.0,1.0) = 1.0;

// Distance fade settings
uniform float fade_start : hint_range(0.0,50.0) = 5.0;   // fade starts at this distance
uniform float fade_end   : hint_range(0.0,50.0) = 15.0;  // fade fully at this distance
uniform sampler2D grass_texture : filter_nearest, source_color;

void vertex(){
	world_vertex = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = vec3(0.0, 1.0, 0.0);
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * ( 1.0 - UV.y) * 0.15;
}

void fragment(){
	SPECULAR = 0.0;
	
	
	// Distance from fragment to character
    float dist = length(world_vertex - character_position);

    // Fade factor: 0 = solid (near), 1 = far → fades out
    float fade = clamp((dist - fade_start) / max(0.0001, fade_end - fade_start), 0.0, 1.0);

    // Interleaved gradient noise for dithering
    const vec3 magic = vec3(0.06711056,0.00583715,52.9829189);
    float noise = fract(magic.z * fract(dot(FRAGCOORD.xy * dither_grain, magic.xy)));

    // Apply dither + smooth fade
    float alpha = fade > noise ? 0.0 : 1.0;

    // Apply color and alpha
	vec4 albedo_tex = texture(grass_texture, UV);
	ALBEDO = albedo_tex.rgb;
    ALPHA = mix(alpha,albedo_tex.a,alpha);

    // Alpha scissor threshold preserves shadows
    ALPHA_SCISSOR_THRESHOLD = 0.5;
	
}
//
//
//
