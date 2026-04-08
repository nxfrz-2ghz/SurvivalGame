shader_type spatial;
render_mode cull_disabled;

// Параметры цвета и шума
uniform vec3 color : source_color = vec3(0.1, 0.4, 0.1);
uniform vec3 color2 : source_color = vec3(0.2, 0.6, 0.2);
uniform sampler2D noise;
uniform float noiseScale = 20.0;

// Параметры ветра
uniform vec3 wind_direction = vec3(1.0, 0.0, 1.0);
uniform float wind_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.2;
uniform float wind_frequency : hint_range(0.0, 10.0) = 2.0;

varying vec3 worldPos;

void vertex() {
	// 1. Рассчитываем позицию в мировых координатах для фрагментного шейдера
	worldPos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// 2. Логика ветра
	// Используем UV.y как маску: внизу (UV.y=1) сила 0, вверху (UV.y=0) сила максимальна
	float mask = UV.y;
	float strength = mask * wind_strength;
	
	// Создаем волну. Используем мировые координаты из MODEL_MATRIX для вариативности
	float world_offset = MODEL_MATRIX[3].x + MODEL_MATRIX[3].z;
	float sway = sin(TIME * wind_speed + world_offset + VERTEX.x * wind_frequency);
	
	// Применяем смещение к вершине
	VERTEX.xz += wind_direction.xz * sway * strength;
}

void fragment() {
	// Сэмплируем шум по мировым координатам XZ
	vec3 noiseLevel = texture(noise, worldPos.xz / noiseScale).rgb;
	
	// Смешиваем цвета по вертикали (UV.y) и по маске шума
	vec3 base_color = mix(color, color2, 1.0 - UV.y);
	ALBEDO = base_color * mix(color, color2, noiseLevel.r);
	
	// Корректируем нормали для двустороннего отображения
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
