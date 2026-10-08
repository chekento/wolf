shader_type sky;
uniform vec3 top_color : source_color = vec3(0.36, 0.57, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.77, 0.83, 0.77);
uniform vec3 sun_direction = vec3(-0.35, 0.70, 0.50);
uniform float daylight = 1.0;
uniform float cloud_cover = 0.35;
uniform float wind_phase = 0.0;
float hash_at(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
float noise_at(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash_at(c), hash_at(c + vec2(1.0, 0.0)), f.x),
               mix(hash_at(c + vec2(0.0, 1.0)), hash_at(c + vec2(1.0, 1.0)), f.x), f.y);
}
void sky() {
    float elevation = clamp(EYEDIR.y, 0.0, 1.0);
    vec3 colour = mix(horizon_color, top_color, pow(elevation, 0.55));
    vec2 cloud_point = EYEDIR.xz / max(0.18, EYEDIR.y) * 2.6 + vec2(wind_phase * 0.007, 0.0);
    float clouds = noise_at(cloud_point) * 0.72 + noise_at(cloud_point * 2.1) * 0.28;
    float cloud = smoothstep(0.75 - cloud_cover * 0.5, 0.90 - cloud_cover * 0.34, clouds);
    cloud *= smoothstep(0.02, 0.22, EYEDIR.y);
    vec3 cloud_colour = mix(vec3(0.15, 0.20, 0.29), vec3(0.89, 0.89, 0.79), daylight);
    colour = mix(colour, cloud_colour, cloud * (0.3 + daylight * 0.45));
    float sun_alignment = dot(EYEDIR, normalize(sun_direction));
    float halo = pow(max(sun_alignment, 0.0), 60.0);
    colour += vec3(0.25, 0.18, 0.06) * halo * daylight * (1.0 - cloud * 0.8);
    float sun = smoothstep(0.9981, 0.9987, sun_alignment);
    colour = mix(colour, vec3(1.0, 0.93, 0.67), sun * daylight * (1.0 - cloud));
    float night = 1.0 - smoothstep(0.06, 0.42, daylight);
    vec3 moon_direction = normalize(vec3(-0.48, 0.53, -0.65));
    float moon_alignment = dot(EYEDIR, moon_direction);
    float moon = smoothstep(0.9981, 0.9986, moon_alignment);
    float moon_detail = noise_at(EYEDIR.xz * 380.0);
    colour = mix(colour, vec3(0.86, 0.89, 0.75) * (0.88 + moon_detail * 0.12), moon * night * (1.0 - cloud));
    vec2 star_grid = EYEDIR.xz / (abs(EYEDIR.y) + 0.20) * 85.0;
    float star = pow(max(0.0, 1.0 - length(fract(star_grid) - vec2(0.5)) * 2.0), 18.0);
    star *= step(0.989, hash_at(floor(star_grid))) * smoothstep(0.1, 0.3, EYEDIR.y);
    colour += vec3(0.8, 0.83, 0.75) * star * night * (1.0 - cloud);
    COLOR = colour;
}
