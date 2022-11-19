#version 330 core
#include hg_sdf.glsl
layout (location = 0) out vec4 fragColor;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform bool u_performance_mode;

const float FOV = 1.0;
const int   MAX_STEPS = 256;
const float MAX_DIST = 500;
const float EPSILON = 0.001;

vec2 fOpUnionID(vec2 res1, vec2 res2)
{
  return (res1.x < res2.x) ? res1 : res2;
}

vec2 fOpDifferenceID(vec2 res1, vec2 res2)
{
  return (res1.x > -res2.x) ? res1 : vec2(-res2.x, res2.y);
}

vec2 fOpDifferenceColumnsID(vec2 res1, vec2 res2, float r, float n)
{
  float dist = fOpDifferenceColumns(res1.x, res2.x, r, n);
  return (res1.x > -res2.x) ? vec2(dist, res1.y) : vec2(dist, res2.y);
}

vec2 fOpUnionStairsID(vec2 res1, vec2 res2, float r, float n)
{
  float dist = fOpUnionStairs(res1.x, res2.x, r, n);
  return (res1.x > res2.x) ? vec2(dist, res2.y) : vec2(dist, res1.y);
}

vec2 fOpUnionChamferID(vec2 res1, vec2 res2, float r)
{
  float dist = fOpUnionChamfer(res1.x, res2.x, r);
  return (res1.x > res2.x) ? vec2(dist, res2.y) : vec2(dist, res1.y);
}

////////////////////////
#include map.glsl
#include material.glsl
////////////////////////

vec2 rayMarch(vec3 ro, vec3 rd)
{
  vec2 hit, object = vec2(0.0);
  for (int i = 0; i < MAX_STEPS; ++i)
  {
    vec3 p = ro + object.x * rd;
    hit = map(p);

    object.x += hit.x;
    object.y  = hit.y;

    if (abs(hit.x) < EPSILON || object.x > MAX_DIST) break;
  }
  return object;
}

vec3 getNormal(vec3 p)
{
  vec2 e = vec2(EPSILON, 0.0);
  vec3 n = vec3(map(p).x) - vec3(map(p - e.xyy).x, map(p - e.yxy).x, map(p - e.yyx).x);
  return normalize(n);
}

float getAmbientOcclusion(vec3 p, vec3 normal)
{
  float occlusion = 0.0;
  float weight = 1.0;
  
  for (int i = 0; i < 8; ++i)
  {
    float len = 0.01 + 0.02 * float(i * i);
    float dist = map(p + normal * len).x;
    occlusion += (len - dist) * weight;
    weight *= 0.85;
  }
  return 1.0 - clamp(0.6 * occlusion, 0.0, 1.0);
}

vec3 getLight(vec3 p, vec3 rd, float id)
{
  vec3 light_position = vec3(20.0, 40.0, -30.0);
  vec3 L = normalize(light_position - p);
  vec3 N = getNormal(p);
  vec3 V = -rd;
  vec3 R = reflect(-L, N);

  vec3 color = getMaterial(p, id);

  vec3 specular_color = vec3(0.5);
  vec3 specular = specular_color * pow(clamp(dot(R, V), 0.0, 1.0), 10.0);
  vec3 diffuse = color * clamp(dot(L, N), 0.0, 1.0);
  vec3 ambient = color * 0.05;
  vec3 fresnel = 0.25 * color * pow(1.0 + dot(rd, N), 3.0);

  // ambient occlusion
  float ambient_occlusion = getAmbientOcclusion(p, N);

  // shadows
  float d = rayMarch(p + N * 0.02, normalize(light_position)).x;
  if (d < length(light_position - p))
    return (ambient + fresnel) * ambient_occlusion;

  return (ambient + fresnel) * ambient_occlusion + (specular * ambient_occlusion + diffuse);
}

mat3 getCamera(vec3 ro, vec3 look_at)
{
  vec3 camera_front = normalize(vec3(look_at - ro));
  vec3 camera_right = normalize(cross(vec3(0.0, 1.0, 0.0), camera_front));
  vec3 camera_up    = cross(camera_front, camera_right);
  return mat3(camera_right, camera_up, camera_front);
}

void mouseControl(inout vec3 ro)
{
  vec2 m = u_mouse / u_resolution;
  pR(ro.yz, m.y * PI - 0.5);
  pR(ro.xz, m.x * TAU);
}

vec3 render(vec2 uv)
{
  vec3 ro = vec3(0.0, 15.0, -15.0);
  vec3 col = vec3(0.0);
  mouseControl(ro);

  vec3 look_at = vec3(0.0);
  vec3 rd = getCamera(ro, look_at) * normalize(vec3(uv, FOV));

  vec2 object = rayMarch(ro, rd);

  vec3 background = vec3(0.22352941176, 0.2431372549, 0.37450980392);
  if (object.x < MAX_DIST)
  {
    vec3 p = ro + object.x * rd;
    col += getLight(p, rd, object.y);

    // fog
    col = mix(col, background, 1.0 - exp(-0.00008 * object.x * object.x));
  }
  else
  {
    col += background;
  }
  return col;
}

vec2 getUV(vec2 offset)
{
  return (2.0 * (gl_FragCoord.xy + offset) - u_resolution.xy) / u_resolution.y;
}

vec3 renderAAx4()
{
  vec4 e = vec4(0.125, -0.125, 0.375, -0.375);
  vec3 color_AA = render(getUV(e.xz)) + render(getUV(e.yw)) + render(getUV(e.wx)) + render(getUV(e.zy));
  return color_AA /= 4.0;
}

void main()
{
  vec3 col = vec3(0.0);
  
  if (!u_performance_mode)
    col = renderAAx4();
  else
    col = render(getUV(vec2(0.0)));
  
  col = pow(col, vec3(0.4545)); // gamma correction
  fragColor = vec4(col, 1.0);
}
