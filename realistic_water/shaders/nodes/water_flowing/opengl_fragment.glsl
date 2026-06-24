// ================================================================
// realistic_water — Fragment Shader
// Physically-based water shading:
//   * Depth-based color (shallow teal → deep blue)
//   * Fresnel reflectivity
//   * Normal-mapped specular highlight
//   * Foam blending at shoreline/crests
//   * Subsurface scattering approximation
//   * Caustic light overlay
// ================================================================

uniform sampler2D baseTexture;       // animated normal/surface texture
uniform sampler2D normalTexture;     // normal map (optional, same as base)

uniform float animationTimer;
uniform vec3  cameraPosition;
uniform vec3  sunPosition;           // approximated; passed from engine

// Depth-blend colors
const vec3 COLOR_SHALLOW = vec3(0.18, 0.62, 0.76);   // #2E9EC2
const vec3 COLOR_DEEP    = vec3(0.024, 0.24, 0.42);  // #063D6B
const vec3 COLOR_FOAM    = vec3(0.87, 0.93, 1.00);   // #DDEEFF
const vec3 SUN_COLOR     = vec3(1.0, 0.97, 0.88);

// Tunable constants
const float ALPHA_BASE      = 0.62;
const float SPECULAR_POWER  = 120.0;
const float SPECULAR_STRENGTH = 0.9;
const float SSS_STRENGTH    = 0.18;
const float FOAM_THRESHOLD  = 0.60;
const float CAUSTIC_SPEED   = 0.7;
const float CAUSTIC_SCALE   = 3.5;

varying vec3  vWorldPos;
varying vec3  vNormal;
varying vec2  vTexCoord;
varying float vFresnel;
varying float vDepth;
varying float vFoam;

// ── Pseudo-random hash ───────────────────────────────────────
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// ── Value noise ──────────────────────────────────────────────
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),            hash(i + vec2(1,0)), f.x),
               mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x), f.y);
}

// ── Caustic pattern (two-octave noise) ───────────────────────
float caustic(vec2 uv, float t) {
    vec2 p = uv * CAUSTIC_SCALE;
    float c1 = noise(p + vec2( t * CAUSTIC_SPEED,  t * CAUSTIC_SPEED * 0.7));
    float c2 = noise(p + vec2(-t * CAUSTIC_SPEED * 0.5, t * CAUSTIC_SPEED));
    // Ridged combination for bright caustic lines
    return pow(abs(c1 - c2), 0.4);
}

// ── Sample normal map with two UV offsets (parallax scroll) ──
vec3 sampleNormal(sampler2D tex, vec2 uv, float t) {
    vec2 uv1 = uv       + vec2( t * 0.04,  t * 0.02);
    vec2 uv2 = uv * 0.7 + vec2(-t * 0.03, -t * 0.05);
    vec4 n1 = texture2D(tex, uv1);
    vec4 n2 = texture2D(tex, uv2);
    // Decode tangent-space normal (packed in [0,1])
    vec3 nm = normalize((n1.rgb + n2.rgb) - 1.0);
    return nm;
}

void main() {
    float t = animationTimer;

    // ── Surface normal (perturbed) ─────────────────────────────
    vec3 texNormal = sampleNormal(baseTexture, vTexCoord, t);
    // Blend geometry normal with texture normal
    vec3 N = normalize(vNormal + texNormal * 0.45);

    // ── View & light vectors ───────────────────────────────────
    vec3 V = normalize(cameraPosition - vWorldPos);
    // Sun direction (approximation; ideally passed as uniform)
    vec3 L = normalize(vec3(0.4, 1.0, 0.3));
    vec3 H = normalize(V + L);               // half-vector

    // ── Diffuse lighting ───────────────────────────────────────
    float NdotL = max(dot(N, L), 0.0);

    // ── Specular (Blinn-Phong) ─────────────────────────────────
    float NdotH = max(dot(N, H), 0.0);
    float spec  = pow(NdotH, SPECULAR_POWER) * SPECULAR_STRENGTH;

    // ── Depth-based color blend ────────────────────────────────
    // vDepth encodes wave height proxy; use also Y-coord for world depth
    float depthFactor = clamp(vDepth + 0.3, 0.0, 1.0);
    vec3 waterColor = mix(COLOR_SHALLOW, COLOR_DEEP, depthFactor);

    // ── Subsurface scattering approximation ───────────────────
    // Light shining through thin water edges glows teal
    float thickness = 1.0 - max(dot(N, V), 0.0);
    vec3 sss = COLOR_SHALLOW * SUN_COLOR * thickness * SSS_STRENGTH;

    // ── Combine base color ─────────────────────────────────────
    vec3 color = waterColor * (0.35 + 0.65 * NdotL) + sss;

    // ── Caustics ───────────────────────────────────────────────
    float caust = caustic(vWorldPos.xz * 0.25, t);
    color += SUN_COLOR * caust * 0.20 * NdotL;

    // ── Specular highlight ─────────────────────────────────────
    color += SUN_COLOR * spec;

    // ── Fresnel: more reflective at grazing angles ─────────────
    // At high Fresnel, darken base (reflection replaces transmission)
    color = mix(color, vec3(0.55, 0.75, 0.85), vFresnel * 0.5);

    // ── Foam blending ──────────────────────────────────────────
    float foamMask = smoothstep(FOAM_THRESHOLD, 1.0, vFoam);
    // Sample texture alpha channel as foam noise
    vec4 baseTex = texture2D(baseTexture, vTexCoord + vec2(t*0.02, 0.0));
    float foamNoise = baseTex.a;
    foamMask *= foamNoise;
    color = mix(color, COLOR_FOAM, foamMask * 0.85);

    // ── Alpha ──────────────────────────────────────────────────
    // More opaque at crests (foam), more transparent in troughs
    float alpha = ALPHA_BASE + 0.15 * vFresnel + 0.20 * foamMask;
    alpha = clamp(alpha, 0.35, 0.97);

    // ── Fog (engine expects gl_FragColor, fog applied externally) ─
    gl_FragColor = vec4(color, alpha);
}
