// Факелы
torch_a = light_add(220, 200, 260, make_color_rgb(255, 150, 40), 0.90);
torch_a.flicker = true; torch_a.flicker_speed = 1.1; torch_a.flicker_amount = 0.18;

torch_b = light_add(800, 180, 280, make_color_rgb(255, 130, 35), 0.85);
torch_b.flicker = true; torch_b.flicker_speed = 0.9; torch_b.flicker_amount = 0.20;

torch_c = light_add(520, 540, 240, make_color_rgb(255, 160, 50), 0.88);
torch_c.flicker = true; torch_c.flicker_speed = 1.3; torch_c.flicker_amount = 0.15;

// Свет на курсоре
mouse_light = light_add(mouse_x, mouse_y, 600, make_color_rgb(220, 200, 160), 0.60);

// Тени — колонны и стена
col_a  = shadow_caster_add(340,  150, 40, 40);
col_b  = shadow_caster_add(650,  220, 40, 40);
col_c  = shadow_caster_add(310,  450, 40, 40);
col_d  = shadow_caster_add(750,  430, 40, 40);
wall   = shadow_caster_add(480,  290, 200, 25);
