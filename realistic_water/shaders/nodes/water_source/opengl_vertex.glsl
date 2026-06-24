// ================================================================
// realistic_water — Vertex Shader
// Generates Gerstner-wave displacement on water surface geometry.
// Compatible with Luanti (Minetest) GLSL pipeline.
// ================================================================

uniform mat4 mWorldViewProj;
uniform mat4 mWorld;
uniform mat4 mInvWorld;
uniform mat4 mTransWorld;

uniform float animationTimer;    // global time in seconds
uniform vec3  cameraPosition;

// Wave parameters (tuned for realism)
#define WAVE_COUNT   4
#define PI           3.14159265

// Gerstner wave parameters: [amplitude, wavelength, speed, direction_angle]
const vec4 WAVES[WAVE_COUNT] = vec4[](
    vec4(0.10, 8.0,  1.20, 0.00),   // long swell, x-axis
    vec4(0.06, 5.0,  0.90, 0.78),   // medium, diagonal
    vec4(0.04, 3.0,  1.50, 1.57),   // chop, z-axis
    vec4(0.025,2.0,  2.10, 2.36)    // fine ripple, diagonal
);

varying vec3  vWorldPos;
varying vec3  vNormal;
varying vec2  vTexCoord;
varying float vFresnel;
varying float vDepth;       // pseudo-depth for color blend
varying float vFoam;        // foam intensity

// ── Gerstner wave contribution ───────────────────────────────
vec3 gerstner(vec3 pos, float amp, float wavelength, float speed, float angle) {
    float k   = 2.0 * PI / wavelength;
    float w   = sqrt(9.81 * k);          // deep-water dispersion
    vec2  dir = vec2(cos(angle), sin(angle));
    float phi = k * dot(dir, pos.xz) - w * animationTimer * speed;

    // Horizontal (orbital) displacement
    float horizontal = amp * sin(phi);
    float vertical   = amp * cos(phi);

    return vec3(dir.x * horizontal, vertical, dir.y * horizontal);
}

void main() {
    vec4 worldPos4 = mWorld * gl_Vertex;
    vec3 pos = worldPos4.xyz;

    // Accumulate Gerstner displacements
    vec3 disp = vec3(0.0);
    for (int i = 0; i < WAVE_COUNT; i++) {
        disp += gerstner(pos,
                         WAVES[i].x,
                         WAVES[i].y,
                         WAVES[i].z,
                         WAVES[i].w);
    }

    // Apply vertical displacement only to top face (normal.y > 0.5)
    float topFace = step(0.5, gl_Normal.y);
    pos.y  += disp.y * topFace;
    pos.xz += disp.xz * topFace * 0.4;

    // Recompute approximate normal from finite differences
    float eps = 0.2;
    vec3 dpx = vec3(eps, 0.0, 0.0);
    vec3 dpz = vec3(0.0, 0.0, eps);
    // Central-difference gradient of vertical displacement field
    float dydx = (gerstner(pos + dpx, WAVES[0].x, WAVES[0].y, WAVES[0].z, WAVES[0].w).y
                + gerstner(pos + dpx, WAVES[1].x, WAVES[1].y, WAVES[1].z, WAVES[1].w).y
                + gerstner(pos + dpx, WAVES[2].x, WAVES[2].y, WAVES[2].z, WAVES[2].w).y
                + gerstner(pos + dpx, WAVES[3].x, WAVES[3].y, WAVES[3].z, WAVES[3].w).y
                - disp.y * 4.0) / eps;
    float dydz = (gerstner(pos + dpz, WAVES[0].x, WAVES[0].y, WAVES[0].z, WAVES[0].w).y
                + gerstner(pos + dpz, WAVES[1].x, WAVES[1].y, WAVES[1].z, WAVES[1].w).y
                + gerstner(pos + dpz, WAVES[2].x, WAVES[2].y, WAVES[2].z, WAVES[2].w).y
                + gerstner(pos + dpz, WAVES[3].x, WAVES[3].y, WAVES[3].z, WAVES[3].w).y
                - disp.y * 4.0) / eps;
    vec3 normal = normalize(vec3(-dydx, 1.0, -dydz));

    // Fresnel term (Schlick approximation)
    vec3 viewDir = normalize(cameraPosition - pos);
    float cosTheta = max(dot(normal, viewDir), 0.0);
    float F0 = 0.02;
    vFresnel = F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);

    // Pass varyings
    vWorldPos = pos;
    vNormal   = normal;
    vTexCoord = gl_MultiTexCoord0.xy;
    vDepth    = clamp(abs(disp.y) * 8.0, 0.0, 1.0);  // wave height → depth hint
    vFoam     = clamp(length(disp.xz) * 6.0, 0.0, 1.0);

    // Final clip position
    gl_Position    = mWorldViewProj * vec4(pos, 1.0);
    gl_FogFragCoord = gl_Position.z;
}
