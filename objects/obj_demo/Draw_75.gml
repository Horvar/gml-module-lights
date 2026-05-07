// Draw GUI End — runs after obj_light_manager's Draw_75 (lighting overlay already applied).

// Hold G — show blur guide overlay (magenta = strong blur, black = no blur).
if (keyboard_check(ord("G")) && surface_exists(global.__light_guide)) {
    gpu_set_blendmode_ext(bm_src_alpha, bm_inv_src_alpha);
    draw_surface_ext(global.__light_guide, 0, 0, 1, 1, 0, make_color_rgb(180, 60, 255), 0.7);
    gpu_set_blendmode(bm_normal);
}

// Highlight shadow casters that interact with the mouse light.
var _r2 = mouse_light.radius * mouse_light.radius;
var _nc = array_length(global.__shadow_casters);
for (var _i = 0; _i < _nc; _i++) {
    var _sc = global.__shadow_casters[_i];
    var _nx = clamp(mouse_light.x, _sc.x, _sc.x + _sc.w);
    var _ny = clamp(mouse_light.y, _sc.y, _sc.y + _sc.h);
    var _dx = mouse_light.x - _nx;  var _dy = mouse_light.y - _ny;
    if (_dx * _dx + _dy * _dy < _r2) {
        draw_set_color(make_color_rgb(0, 255, 120));
        draw_rectangle(_sc.x - 2, _sc.y - 2, _sc.x + _sc.w + 2, _sc.y + _sc.h + 2, true);
    }
}
