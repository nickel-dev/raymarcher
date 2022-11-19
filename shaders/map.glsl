vec2 map(vec3 p)
{
  // plane
  float plane_distance = fPlane(p, vec3(0.0, 1.0, 0.0), 14.0);
  float plane_id = 2.0;
  vec2 plane = vec2(plane_distance, plane_id);

  // sphere
  float sphere_distance = fSphere(p, 9.0);
  float spere_id = 1.0;
  vec2 sphere = vec2(sphere_distance, spere_id);

  // cube
  float cube_distance = fBox(p, vec3(6.0));
  float cube_id = 1.0;
  vec2 cube = vec2(cube_distance, cube_id);

  // manipulation operators
  pMirrorOctant(p.xz, vec2(50.0, 50.0));
  p.x = -abs(p.x) + 20.0;
  pMod1(p.z, 15.0);

  // roof
  vec3 roof_position = p;
  roof_position.y -= 16.0;
  pR(roof_position.xy, 0.6);
  roof_position.x -= 18.0;
  float roof_distance = fBox2(roof_position.xy, vec2(20.0, 0.3));
  float roof_id = 4.0;
  vec2 roof = vec2(roof_distance, roof_id);

  // pillar
  vec3 pillar_box_position = p;
  pillar_box_position.y += 2.0;
  float pillar_box_distance = fBox(p, vec3(3.0, 9.0, 4.0));
  float pillar_box_id= 3.0;
  vec2 pillar_box = vec2(pillar_box_distance, pillar_box_id);
  vec3 pillar_cylinder_position = p;
  pillar_cylinder_position.y -= 8.0;
  float pillar_cylinder_distance = fCylinder(pillar_cylinder_position.yxz, 4.0, 3.0);
  float pillar_cylinder_id = 3.0;
  vec2 pillar_cylinder = vec2(pillar_cylinder_distance, pillar_cylinder_id);

  // wall
  float wall_distance = fBox2(p.xy, vec2(1, 15));
  float wall_id = 3.0;
  vec2 wall = vec2(wall_distance, wall_id);

  // result
  vec2 result = vec2(0.0);
  result = fOpUnionID(pillar_box, pillar_cylinder);
  result = fOpDifferenceColumnsID(wall, result, 0.6, 3.0);
  result = fOpUnionChamferID(result, roof, 0.9);
  result = fOpUnionStairsID(result, plane, 4.0, 5.0);
  result = fOpUnionID(result, cube);
  return result;
}