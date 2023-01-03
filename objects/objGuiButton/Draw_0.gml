/// @description Draw the button

draw_self();
draw_set_halign(textHAlign);
draw_set_valign(textVAlign);
draw_set_color(textColor);
draw_set_alpha(textAlpha);
draw_text(x + sprite_width / 2, y + sprite_height / 2, text);


if (!is_undefined(onUpdate)) {
	onUpdate(id);
}
