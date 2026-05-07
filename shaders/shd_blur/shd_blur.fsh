// Radial (disc-shaped) blur of the shadow mask (gm_BaseTexture).
// Kernel: 5x5 grid minus 4 diagonal corners = 21 samples within circle radius ~2.24.
// u_guide: R=0 → no blur, R=1 → max blur (step = u_maxStep).
// u_maxStep: UV distance per unit step, set so that step*2*W = desired blur radius in pixels.
varying vec2 v_vTexcoord;

uniform sampler2D u_guide;
uniform vec2      u_maxStep;

void main() {
    float b = texture2D(u_guide, v_vTexcoord).r;
    vec2  s = u_maxStep * b;

    vec4 col = vec4(0.0);
    //           row -2 (no corners ±2)
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-1.0, -2.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 0.0, -2.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 1.0, -2.0));
    //           row -1 (full)
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-2.0, -1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-1.0, -1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 0.0, -1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 1.0, -1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 2.0, -1.0));
    //           row 0 (full)
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-2.0,  0.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-1.0,  0.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 0.0,  0.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 1.0,  0.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 2.0,  0.0));
    //           row +1 (full)
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-2.0,  1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-1.0,  1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 0.0,  1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 1.0,  1.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 2.0,  1.0));
    //           row +2 (no corners ±2)
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2(-1.0,  2.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 0.0,  2.0));
    col += texture2D(gm_BaseTexture, v_vTexcoord + s * vec2( 1.0,  2.0));

    gl_FragColor = col / 21.0;
}
