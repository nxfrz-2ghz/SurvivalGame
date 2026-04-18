shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_color : source_color = vec4(0.1, 0.4, 0.8, 0.6);
uniform float wave_speed = 1.0;
uniform float wave_strength = 0.05;
uniform float tiling = 5.0;

void fragment() {
    vec2 uv_scroll = UV * tiling + vec2(TIME * wave_speed * 0.05);
    // Простая анимация через синус
    float wave = sin(uv_scroll.x * 10.0 + TIME * wave_speed) * wave_strength
               + cos(uv_scroll.y * 8.0 + TIME * wave_speed * 0.7) * wave_strength;
    
    ALBEDO = water_color.rgb;
    ALPHA = water_color.a + wave * 0.1;
    ROUGHNESS = 0.05;
    METALLIC = 0.3;
    NORMAL = vec3(wave * 2.0, 1.0, wave * 2.0);
}