// shd_light — fragment shader
// Renders a smooth radial point light onto the light surface.
// Uses additive blending: output is (color * attenuation * intensity).
// The light surface is later multiplied onto the game screen.

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vRoomPos;

uniform vec2  u_lightPos;   // light center in room coordinates
uniform float u_radius;     // light radius in room pixels
uniform vec3  u_color;      // light color (0..1 per channel)
uniform float u_intensity;  // brightness multiplier
uniform float u_softness;   // inner glow fraction (0 = hard center, 0.3 = soft)

void main() {
    float dist  = length(v_vRoomPos - u_lightPos);
    float inner = u_radius * (1.0 - u_softness);

    // Smooth falloff: full brightness inside inner zone, fade to edge
    float atten = 1.0 - smoothstep(inner, u_radius, dist);

    // Diablo-style curve: quadratic falloff, natural point-light feel
    atten = atten * atten;

    // With bm_add, alpha multiplies the RGB output
    float alpha = atten * u_intensity;
    gl_FragColor = vec4(u_color, alpha);
}
