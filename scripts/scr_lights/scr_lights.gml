/// @description  Isometric light system with shadow casting
/// -----------------------------------------------------------------------
/// QUICK START — LIGHTS
///   1. Place obj_light_manager in the room.
///   2. light_add(x, y, radius, color, intensity)  → struct
///   3. Modify struct fields at runtime to move/update lights.
///   4. light.flicker = true  for torch effect.
///   5. light_remove(light)  to destroy.
///
/// QUICK START — SHADOWS
///   1. shadow_caster_add(x, y, w, h)  → struct  (axis-aligned box)
///   2. shadow_caster_remove(caster)   to destroy.
///   3. shadow_caster_clear()          removes all casters.
///   Shadow casters are drawn once globally; every light casts shadows through them.
/// -----------------------------------------------------------------------

// ============================================================  LIGHTS  ===

function light_system_init(_ambient_color) {
    global.__light_ambient    = _ambient_color;
    global.__lights           = [];
    global.__shadow_casters   = [];
    global.__light_surf       = -1;
    global.__light_tmp        = -1;  // light render + blur output (reused)
    global.__light_blur       = -1;  // composite shadow mask (accumulate per-caster)
    global.__light_shadow     = -1;  // per-caster shadow (input to blur)
    global.__light_guide      = -1;  // per-caster blur guide disc

    global.__shd_u_pos    = shader_get_uniform(shd_light, "u_lightPos");
    global.__shd_u_radius = shader_get_uniform(shd_light, "u_radius");
    global.__shd_u_color  = shader_get_uniform(shd_light, "u_color");
    global.__shd_u_intens = shader_get_uniform(shd_light, "u_intensity");
    global.__shd_u_soft   = shader_get_uniform(shd_light, "u_softness");

    global.__shd_blur_maxStep = shader_get_uniform(shd_blur,       "u_maxStep");
    global.__shd_blur_guide   = shader_get_sampler_index(shd_blur, "u_guide");
}

function light_system_free() {
    if surface_exists(global.__light_surf)   surface_free(global.__light_surf);
    if surface_exists(global.__light_tmp)    surface_free(global.__light_tmp);
    if surface_exists(global.__light_blur)   surface_free(global.__light_blur);
    if surface_exists(global.__light_shadow) surface_free(global.__light_shadow);
    if surface_exists(global.__light_guide)  surface_free(global.__light_guide);
    global.__lights           = [];
    global.__shadow_casters   = [];
    global.__light_surf       = -1;
    global.__light_tmp        = -1;
    global.__light_blur       = -1;
    global.__light_shadow     = -1;
    global.__light_guide      = -1;
}

/// @func  light_add(x, y, radius, color, intensity) → struct
/// Struct fields: x, y, radius, color, intensity, active,
///               flicker, flicker_speed, flicker_amount
function light_add(_x, _y, _radius, _color, _intensity) {
    var _l = {
        x:              _x,
        y:              _y,
        radius:         _radius,
        color:          _color,
        intensity:      _intensity,
        active:         true,
        flicker:        false,
        flicker_speed:  1.0,
        flicker_amount: 0.15,
        __flicker_seed: random(1000),
    };
    array_push(global.__lights, _l);
    return _l;
}

function light_remove(_light) {
    var _n = array_length(global.__lights);
    for (var _i = 0; _i < _n; _i++) {
        if (global.__lights[_i] == _light) {
            array_delete(global.__lights, _i, 1);
            return;
        }
    }
}

function light_set_ambient(_color) {
    global.__light_ambient = _color;
}

// ============================================================  SHADOWS  ===

/// @func  shadow_caster_add(x, y, w, h) → struct
/// @desc  Add an axis-aligned box shadow caster.
function shadow_caster_add(_x, _y, _w, _h) {
    var _c = { x: _x, y: _y, w: _w, h: _h };
    array_push(global.__shadow_casters, _c);
    return _c;
}

/// @func  shadow_caster_remove(caster)
function shadow_caster_remove(_caster) {
    var _n = array_length(global.__shadow_casters);
    for (var _i = 0; _i < _n; _i++) {
        if (global.__shadow_casters[_i] == _caster) {
            array_delete(global.__shadow_casters, _i, 1);
            return;
        }
    }
}

/// @func  shadow_caster_clear()
function shadow_caster_clear() {
    global.__shadow_casters = [];
}

// ============================================================  INTERNAL  ===

/// @func  __shadow_render(lx, ly, light_radius, rx, ry, rw, rh)
/// @desc  Draws a hard shadow cast by one AABB caster from one light.
///        Shadow is fully opaque black — no blur, no penumbra.
function __shadow_render(_lx, _ly, _light_radius, _rx, _ry, _rw, _rh) {
    // Caster body — fully opaque.
    draw_set_alpha(1);
    draw_rectangle(_rx, _ry, _rx + _rw, _ry + _rh, false);

    var _cx = [_rx,        _rx + _rw,  _rx + _rw,  _rx       ];
    var _cy = [_ry,        _ry,        _ry + _rh,  _ry + _rh ];
    var _nx = [0,  1,  0, -1];
    var _ny = [-1, 0,  1,  0];
    var _ea = [0, 1, 2, 3];
    var _eb = [1, 2, 3, 0];

    for (var _e = 0; _e < 4; _e++) {
        var _i0 = _ea[_e];
        var _i1 = _eb[_e];

        var _ecx = (_cx[_i0] + _cx[_i1]) * 0.5;
        var _ecy = (_cy[_i0] + _cy[_i1]) * 0.5;
        var _dot = _nx[_e] * (_lx - _ecx) + _ny[_e] * (_ly - _ecy);
        if (_dot >= 0) continue;

        var _dx0 = _cx[_i0] - _lx;  var _dy0 = _cy[_i0] - _ly;
        var _d0  = sqrt(_dx0*_dx0 + _dy0*_dy0);
        if (_d0 < 1 || _d0 >= _light_radius) continue;

        var _dx1 = _cx[_i1] - _lx;  var _dy1 = _cy[_i1] - _ly;
        var _d1  = sqrt(_dx1*_dx1 + _dy1*_dy1);
        if (_d1 < 1 || _d1 >= _light_radius) continue;

        var _x0f = _lx + (_dx0 / _d0) * _light_radius;
        var _y0f = _ly + (_dy0 / _d0) * _light_radius;
        var _x1f = _lx + (_dx1 / _d1) * _light_radius;
        var _y1f = _ly + (_dy1 / _d1) * _light_radius;

        // Shadow quad — opaque at caster corners (alpha=1), transparent at far tips (alpha=0).
        draw_primitive_begin(pr_trianglelist);
        draw_vertex_color(_cx[_i0], _cy[_i0], c_black, 1.0);
        draw_vertex_color(_x0f,     _y0f,     c_black, 0.0);
        draw_vertex_color(_x1f,     _y1f,     c_black, 0.0);
        draw_vertex_color(_cx[_i0], _cy[_i0], c_black, 1.0);
        draw_vertex_color(_x1f,     _y1f,     c_black, 0.0);
        draw_vertex_color(_cx[_i1], _cy[_i1], c_black, 1.0);
        draw_primitive_end();
    }
}

/// @func  __blur_guide_render(cx, cy, radius)
/// @desc  Circular disc centred on the shadow caster.
///        Centre = black (no blur), edge = white (max blur).
///        radius = light_radius − dist(light, caster_centre).
function __blur_guide_render(_cx, _cy, _radius) {
    var _segs = 24;
    draw_primitive_begin(pr_trianglefan);
    draw_vertex_color(_cx, _cy, c_black, 1.0);   // centre: no blur
    for (var _s = 0; _s <= _segs; _s++) {
        var _a = (_s / _segs) * (2.0 * pi);
        draw_vertex_color(
            _cx + cos(_a) * _radius,
            _cy + sin(_a) * _radius,
            c_white, 1.0                          // edge: max blur
        );
    }
    draw_primitive_end();
}

/// @func  __light_render_to_surface()
function __light_render_to_surface() {
    var _W = surface_get_width(application_surface);
    var _H = surface_get_height(application_surface);

    // Recreate surfaces if needed
    if (!surface_exists(global.__light_surf)
    ||   surface_get_width(global.__light_surf) != _W
    ||   surface_get_height(global.__light_surf) != _H) {
        if surface_exists(global.__light_surf) surface_free(global.__light_surf);
        global.__light_surf = surface_create(_W, _H);
    }

    var _has_casters = (array_length(global.__shadow_casters) > 0);

    if (_has_casters) {
        if (!surface_exists(global.__light_tmp)
        ||   surface_get_width(global.__light_tmp) != _W
        ||   surface_get_height(global.__light_tmp) != _H) {
            if surface_exists(global.__light_tmp) surface_free(global.__light_tmp);
            global.__light_tmp = surface_create(_W, _H);
        }
        if (!surface_exists(global.__light_blur)
        ||   surface_get_width(global.__light_blur) != _W
        ||   surface_get_height(global.__light_blur) != _H) {
            if surface_exists(global.__light_blur) surface_free(global.__light_blur);
            global.__light_blur = surface_create(_W, _H);
        }
        if (!surface_exists(global.__light_shadow)
        ||   surface_get_width(global.__light_shadow) != _W
        ||   surface_get_height(global.__light_shadow) != _H) {
            if surface_exists(global.__light_shadow) surface_free(global.__light_shadow);
            global.__light_shadow = surface_create(_W, _H);
        }
        if (!surface_exists(global.__light_guide)
        ||   surface_get_width(global.__light_guide) != _W
        ||   surface_get_height(global.__light_guide) != _H) {
            if surface_exists(global.__light_guide) surface_free(global.__light_guide);
            global.__light_guide = surface_create(_W, _H);
        }
    }

    // Fill main surface with ambient
    surface_set_target(global.__light_surf);
    draw_clear_alpha(global.__light_ambient, 1);
    surface_reset_target();

    var _n = array_length(global.__lights);
    for (var _i = 0; _i < _n; _i++) {
        var _l = global.__lights[_i];
        if (!_l.active) continue;

        // Flicker
        var _intens = _l.intensity;
        if (_l.flicker) {
            var _t = (current_time * 0.001) * _l.flicker_speed + _l.__flicker_seed;
            _intens += sin(_t * 7.3)  * _l.flicker_amount * 0.5
                     + sin(_t * 13.7) * _l.flicker_amount * 0.3
                     + sin(_t * 23.1) * _l.flicker_amount * 0.2;
            _intens = max(0.0, _intens);
        }

        if (_has_casters) {
            // Pipeline per light:
            //  __light_blur  = composite shadow mask (start white, multiply each caster in)
            //  Per-caster loop:
            //    a. one caster shadow  → __light_shadow
            //    b. one caster guide   → __light_guide
            //    c. blur pass          → __light_tmp   (reads shadow+guide)
            //    d. multiply __light_tmp into __light_blur
            //  Light render            → __light_tmp
            //  Multiply shadow×light   → __light_tmp
            //  Merge                   → __light_surf

            var _r2 = _l.radius * _l.radius;

            // Cull and collect active casters.
            var _active = [];
            var _nc = array_length(global.__shadow_casters);
            for (var _j = 0; _j < _nc; _j++) {
                var _sc = global.__shadow_casters[_j];
                var _nx = clamp(_l.x, _sc.x, _sc.x + _sc.w);
                var _ny = clamp(_l.y, _sc.y, _sc.y + _sc.h);
                var _ddx = _l.x - _nx;  var _ddy = _l.y - _ny;
                if (_ddx * _ddx + _ddy * _ddy >= _r2) continue;
                var _ccx = _sc.x + _sc.w * 0.5;
                var _ccy = _sc.y + _sc.h * 0.5;
                var _disc_r = max(0, _l.radius - point_distance(_l.x, _l.y, _ccx, _ccy));
                array_push(_active, { sc: _sc, ccx: _ccx, ccy: _ccy, disc_r: _disc_r });
            }
            var _na = array_length(_active);

            // Composite shadow mask — start fully lit (white).
            surface_set_target(global.__light_blur);
            draw_clear_alpha(c_white, 1);
            surface_reset_target();

            if (_intens >= 0.25) {
                for (var _j = 0; _j < _na; _j++) {
                    var _entry = _active[_j];
                    var _sc    = _entry.sc;

                    // a. This caster's shadow → __light_shadow.
                    surface_set_target(global.__light_shadow);
                    draw_clear_alpha(c_white, 1);
                    gpu_set_blendmode(bm_normal);
                    draw_set_color(c_black);
                    draw_set_alpha(1);
                    __shadow_render(_l.x, _l.y, _l.radius, _sc.x, _sc.y, _sc.w, _sc.h);
                    surface_reset_target();

                    // b. This caster's guide disc → __light_guide.
                    surface_set_target(global.__light_guide);
                    draw_clear_alpha(c_black, 1);
                    gpu_set_blendmode(bm_normal);
                    if (_entry.disc_r > 0)
                        __blur_guide_render(_entry.ccx, _entry.ccy, _entry.disc_r);
                    surface_reset_target();

                    // c. Blur: __light_shadow (mask) + __light_guide → __light_tmp.
                    surface_set_target(global.__light_tmp);
                    shader_set(shd_blur);
                    shader_set_uniform_f(global.__shd_blur_maxStep, 20.0 / _W, 20.0 / _H);
                    texture_set_stage(global.__shd_blur_guide, surface_get_texture(global.__light_guide));
                    gpu_set_blendmode(bm_normal);
                    draw_surface(global.__light_shadow, 0, 0);
                    shader_reset();
                    surface_reset_target();

                    // d. Multiply this caster's blurred shadow into the composite.
                    surface_set_target(global.__light_blur);
                    gpu_set_blendmode_ext(bm_dest_color, bm_zero);
                    draw_surface(global.__light_tmp, 0, 0);
                    gpu_set_blendmode(bm_normal);
                    surface_reset_target();
                }
            }

            // Light render → __light_tmp.
            surface_set_target(global.__light_tmp);
            draw_clear_alpha(c_black, 1);
            gpu_set_blendmode(bm_add);
            shader_set(shd_light);
            shader_set_uniform_f(global.__shd_u_pos,    _l.x, _l.y);
            shader_set_uniform_f(global.__shd_u_radius, _l.radius);
            shader_set_uniform_f(global.__shd_u_color,
                color_get_red(_l.color)   / 255.0,
                color_get_green(_l.color) / 255.0,
                color_get_blue(_l.color)  / 255.0);
            shader_set_uniform_f(global.__shd_u_intens, _intens);
            shader_set_uniform_f(global.__shd_u_soft,   0.7);
            draw_rectangle(_l.x - _l.radius, _l.y - _l.radius,
                           _l.x + _l.radius, _l.y + _l.radius, false);
            shader_reset();
            gpu_set_blendmode(bm_normal);
            surface_reset_target();

            // Multiply composite shadow × light → __light_tmp.
            surface_set_target(global.__light_tmp);
            gpu_set_blendmode_ext(bm_dest_color, bm_zero);
            draw_surface(global.__light_blur, 0, 0);
            gpu_set_blendmode(bm_normal);
            surface_reset_target();

            // Merge into main surface.
            surface_set_target(global.__light_surf);
            gpu_set_blendmode(bm_add);
            draw_surface(global.__light_tmp, 0, 0);
            gpu_set_blendmode(bm_normal);
            surface_reset_target();

        } else {
            // No casters — draw directly onto main surface
            surface_set_target(global.__light_surf);
            gpu_set_blendmode(bm_add);
            shader_set(shd_light);
            shader_set_uniform_f(global.__shd_u_pos,    _l.x, _l.y);
            shader_set_uniform_f(global.__shd_u_radius, _l.radius);
            shader_set_uniform_f(global.__shd_u_color,
                color_get_red(_l.color)   / 255.0,
                color_get_green(_l.color) / 255.0,
                color_get_blue(_l.color)  / 255.0);
            shader_set_uniform_f(global.__shd_u_intens, _intens);
            shader_set_uniform_f(global.__shd_u_soft,   0.7);
            draw_rectangle(_l.x - _l.radius, _l.y - _l.radius,
                           _l.x + _l.radius, _l.y + _l.radius, false);
            shader_reset();
            gpu_set_blendmode(bm_normal);
            surface_reset_target();
        }
    }

    draw_set_alpha(1);
}

/// @func  __light_apply_surface()
function __light_apply_surface() {
    if (!surface_exists(global.__light_surf)) return;
    gpu_set_blendmode_ext(bm_dest_color, bm_zero);
    draw_surface(global.__light_surf, 0, 0);
    gpu_set_blendmode(bm_normal);
}
