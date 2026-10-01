shader_type canvas_item;
// Prompt 28: ESTÁGIO DE OBRA com a arte de hoje (no lugar do "fantasma que fica nítido").
// Mostra só a parte de baixo do quadro — fundação (estágio 1), paredes (2), o prédio inteiro
// ainda cru (3) — com a cor de obra e uma beirada escura onde a construção parou.
// No Prompt 29 os desenhos de obra (obra_1/2/3) entram no lugar deste corte.

uniform float visible_frac = 1.0;  // fração da altura do quadro que aparece (de baixo pra cima)
uniform int vframes = 1;           // linhas de quadros da textura
uniform int frame_row = 0;         // linha do quadro desenhado
uniform vec4 tint : source_color = vec4(0.82, 0.72, 0.58, 1.0);  // cor de obra (madeira/terra crua)
uniform float edge_px = 2.0;       // altura da beirada escura (px da textura)

void fragment() {
	float rows = float(max(vframes, 1));
	float v = UV.y * rows - float(frame_row);  // 0..1 dentro do quadro
	float cut = 1.0 - visible_frac;
	if (v < cut) {
		discard;
	}
	vec4 c = COLOR;
	c.rgb *= tint.rgb;
	float px = TEXTURE_PIXEL_SIZE.y * rows;  // 1 px da textura em v
	if (visible_frac < 0.999 && v < cut + edge_px * px) {
		c.rgb *= 0.55;
	}
	COLOR = c;
}
