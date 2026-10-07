shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.4, 0.6, 0.3, 1.0);
uniform int surface_kind = 0;
uniform float wind_phase = 0.0;
uniform float animation_amount = 1.0;
varying vec3 local_point;
varying vec3 world_point;

float noise_at(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
    float b = fract(sin(dot(cell + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
    float c = fract(sin(dot(cell + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    float d = fract(sin(dot(cell + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
    local_point = VERTEX;
    world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    if (surface_kind == 1) {
        VERTEX.x += sin(wind_phase * 0.8 + world_point.z * 0.5) * 0.018 * animation_amount * (VERTEX.y + 0.5);
        VERTEX.z += cos(wind_phase * 0.7 + world_point.x * 0.6) * 0.015 * animation_amount;
    }
}

void fragment() {
    vec3 colour = base_color.rgb;
    float detail = noise_at(world_point.xz * 1.8);
    if (surface_kind == 0) {
        float patch = noise_at(world_point.xz * 0.35);
        colour *= 0.90 + 0.13 * patch + 0.07 * detail;
        float fleck = smoothstep(0.84, 0.98, noise_at(world_point.xz * 3.0));
        colour = mix(colour, vec3(0.76, 0.73, 0.46), fleck * 0.22);
    } else if (surface_kind == 1) {
        colour *= 0.88 + 0.20 * noise_at(world_point.xz * 3.0 + world_point.y * 0.35);
    } else if (surface_kind == 2) {
        float bark = noise_at(world_point.xz * 2.0 + vec2(world_point.y * 0.1));
        colour *= 0.89 + 0.08 * bark + 0.08 * detail;
    } else if (surface_kind == 3) {
        float ripple = sin(world_point.x * 7.0 + wind_phase * 1.1) * sin(world_point.z * 6.0 - wind_phase);
        colour *= 0.98 + 0.045 * ripple;
        ROUGHNESS = 0.32;
    }
    ALBEDO = colour;
    if (surface_kind != 3) ROUGHNESS = 0.95;
}
