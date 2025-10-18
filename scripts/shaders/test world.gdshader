shader_type spatial;
uniform vec4 color : source_color = vec4(0.94, 0.54, 0.15, 1.0);
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	 ALBEDO = color.rgb;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
