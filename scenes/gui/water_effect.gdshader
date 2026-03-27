shader_type canvas_item;

// Ссылка на то, что сейчас отрисовано на экране
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.6, 0.3); // Цвет воды
uniform float speed : hint_range(0.1, 5.0) = 1.5;                  // Скорость волн
uniform float distortion : hint_range(0.01, 0.1) = 0.02;          // Сила искажения
uniform float wave_count : hint_range(1.0, 20.0) = 10.0;          // Частота волн

void fragment() {
    // Получаем UV координаты экрана
    vec2 uv = SCREEN_UV;
    
    // Создаем искажение на основе синусоид и времени
    float wave = sin(uv.y * wave_count + TIME * speed) * distortion;
    float wave2 = cos(uv.x * wave_count * 0.8 + TIME * speed * 1.2) * distortion;
    
    // Смещаем UV для эффекта "плавания"
    vec2 distorted_uv = uv + vec2(wave, wave2);
    
    // Берем цвет из искаженных координат экрана
    vec4 screen_col = texture(SCREEN_TEXTURE, distorted_uv);
    
    // Смешиваем цвет экрана с цветом воды
    COLOR = mix(screen_col, water_color, water_color.a);
}
