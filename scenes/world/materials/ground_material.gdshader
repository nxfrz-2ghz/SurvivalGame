shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Текстуры биомов
uniform sampler2D tex_grass   : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_sand    : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_snow    : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_stone   : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_clay    : source_color, filter_linear_mipmap, repeat_enable;

uniform float texture_scale   : hint_range(0.01, 1.0) = 0.1;
uniform float blend_sharpness : hint_range(1.0, 16.0) = 4.0;

// Пороги переходов
uniform float stone_threshold : hint_range(0.0, 1.0) = 0.45;  // крутизна → камень
uniform float cold_threshold  : hint_range(0.0, 1.0) = 0.3;   // холод → снег
uniform float hot_threshold   : hint_range(0.0, 1.0) = 0.7;   // жара → песок

void fragment() {
    // Читаем данные из вертексного цвета
    float steepness = COLOR.r;
    float temperature = COLOR.g;
    float clay_mask = COLOR.b;
    
    // Мировые координаты для triplanar mapping
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec3 world_normal = abs(normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz));
    
    // Triplanar веса
    vec3 tri_blend = pow(world_normal, vec3(blend_sharpness));
    tri_blend /= (tri_blend.x + tri_blend.y + tri_blend.z);
    
    // Triplanar сэмплинг для каждой текстуры
    #define TRIPLANAR(tex) ( \
        texture(tex, world_pos.zy * texture_scale) * tri_blend.x + \
        texture(tex, world_pos.xz * texture_scale) * tri_blend.y + \
        texture(tex, world_pos.xy * texture_scale) * tri_blend.z  \
    )
    
    vec4 c_grass  = TRIPLANAR(tex_grass);
    vec4 c_sand   = TRIPLANAR(tex_sand);
    vec4 c_snow   = TRIPLANAR(tex_snow);
    vec4 c_stone  = TRIPLANAR(tex_stone);
    vec4 c_clay   = TRIPLANAR(tex_clay);
    
    // --- Смешивание ---
    // 1. Базовый биом по температуре
    float cold_blend = smoothstep(cold_threshold + 0.1, cold_threshold - 0.1, temperature);
    float hot_blend  = smoothstep(hot_threshold  - 0.1, hot_threshold  + 0.1, temperature);
    float norm_blend = 1.0 - cold_blend - hot_blend;
    
    vec4 biome_color = c_grass * norm_blend + c_snow * cold_blend + c_sand * hot_blend;
    
    // 2. Камень по крутизне поверх биома
    float stone_blend = smoothstep(stone_threshold - 0.1, stone_threshold + 0.1, steepness);
    vec4 terrain_color = mix(biome_color, c_stone, stone_blend);
    
    // 3. Глина под водой
    vec4 final_color = mix(terrain_color, c_clay, clay_mask);
    
    ALBEDO = final_color.rgb;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}