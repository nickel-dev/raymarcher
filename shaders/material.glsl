vec3 getMaterial(vec3 p, float id)
{
  vec3 material;
  switch (int(id))
  {
    case 1:
      material = vec3(0.99607843137, 0.19215686274, 0.2862745098);
      break;
    case 2:
      material = vec3(0.72941176332 + 0.2 * mod(floor(p.x) + floor(p.z), 2.0));
      break;
    case 3:
      material = vec3(0.54509803921, 0.49411764705, 0.45490196078);
      break;
    case 4:
      material = vec3(0.0);
      break;
    default:
      material = vec3(1.0, 0.0, 1.0);
      break;
  }
  return material;
}
