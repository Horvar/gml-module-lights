/// @desc  Initialise the light system with a near-black ambient color.
///        Tweak the rgb values to change how dark the unlit areas feel.
///        make_color_rgb(0,0,0)    = pitch black
///        make_color_rgb(12,8,6)   = very dark dungeon (warm tint)
///        make_color_rgb(30,30,50) = dark night (cool tint)
light_system_init(make_color_rgb(10, 10, 10));
