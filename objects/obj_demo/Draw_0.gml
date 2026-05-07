// Пол — тёмные каменные плитки
var _tw = 96, _th = 48;
var _cols = ceil(room_width  / _tw) + 1;
var _rows = ceil(room_height / _th) + 1;
var _ca = make_color_rgb(65, 52, 40);
var _cb = make_color_rgb(55, 44, 34);
for (var _r = 0; _r < _rows; _r++) {
    for (var _c = 0; _c < _cols; _c++) {
        draw_set_color(((_r + _c) & 1) ? _ca : _cb);
        draw_rectangle(_c * _tw, _r * _th, _c * _tw + _tw - 1, _r * _th + _th - 1, false);
    }
}

// Колонны (серые блоки)
draw_set_color(make_color_rgb(90, 78, 64));
with (col_a)  draw_rectangle(x, y, x + w, y + h, false);
with (col_b)  draw_rectangle(x, y, x + w, y + h, false);
with (col_c)  draw_rectangle(x, y, x + w, y + h, false);
with (col_d)  draw_rectangle(x, y, x + w, y + h, false);

// Стена
draw_set_color(make_color_rgb(100, 85, 68));
with (wall) draw_rectangle(x, y, x + w, y + h, false);

// Маркеры факелов
draw_set_color(make_color_rgb(255, 200, 60));
draw_circle(torch_a.x, torch_a.y, 5, false);
draw_circle(torch_b.x, torch_b.y, 5, false);
draw_circle(torch_c.x, torch_c.y, 5, false);
