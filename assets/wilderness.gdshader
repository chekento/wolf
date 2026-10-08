shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(0.4, 0.6, 0.3, 1.0);
uniform int surface_kind = 0;
uniform float wind_phase = 0.0;
uniform float animation_amount = 1.0;
varying vec3 world_point;

// Polynomial hashing avoids the precision bands produced by large sine hashes
// on mobile GL. Fine detail fades with derivatives instead of shimmering.
float hash_at(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
float noise_at(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash_at(cell), hash_at(cell + vec2(1.0, 0.0)), f.x),
               mix(hash_at(cell + vec2(0.0, 1.0)), hash_at(cell + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
    world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    if (surface_kind == 1 || surface_kind == 4) {
        float tip = surface_kind == 4 ? max(VERTEX.y, 0.0) : (VERTEX.y + 0.5);
        VERTEX.x += sin(wind_phase * 0.8 + world_point.z * 0.45) * 0.024 * animation_amount * tip;
        VERTEX.z += cos(wind_phase * 0.65 + world_point.x * 0.4) * 0.014 * animation_amount * tip;
    }
}
void fragment() {
    vec3 colour = base_color.rgb * COLOR.rgb;
    float patch = noise_at(world_point.xz * 0.27);
    float fine = 1.0 - smoothstep(0.04, 0.35, length(fwidth(world_point.xz)));
    float detail = noise_at(world_point.xz * 1.4);
    ROUGHNESS = 0.96;
    SPECULAR = 0.18;
    if (surface_kind == 0) {
        colour *= 0.92 + 0.12 * patch + 0.035 * detail * fine;
        colour = mix(colour, colour * vec3(1.08, 1.02, 0.93), noise_at(world_point.xz * 0.08) * 0.27);
    } else if (surface_kind == 1 || surface_kind == 4) {
        colour *= 0.91 + 0.11 * noise_at(world_point.xz * 1.7 + world_point.y * 0.23);
        ROUGHNESS = 0.88;
    } else if (surface_kind == 2) {
        float bark = noise_at(world_point.xz * 4.0 + vec2(world_point.y * 0.18));
        colour *= 0.91 + 0.13 * bark * fine;
    } else if (surface_kind == 3) {
        float ripple = sin(world_point.x * 3.6 + wind_phase * 0.85) * sin(world_point.z * 3.0 - wind_phase * 0.7);
        float crest = pow(max(0.0, ripple), 4.0) * fine;
        colour = mix(colour, vec3(0.75, 0.86, 0.79), crest * 0.20);
        ROUGHNESS = 0.30;
        SPECULAR = 0.48;
    } else if (surface_kind == 6) {
        colour *= 0.95 + patch * 0.06 + detail * fine * 0.025;
    }
    ALBEDO = colour;
}
