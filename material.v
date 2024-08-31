
interface IMaterial {
	scatter(ray Ray, hit HitRecord, mut attenuation Vec3, mut scattered_ray Ray) bool
}

fn reflect(v Vec3, n Vec3) Vec3 {
	return v - n.mul(2.0 * v.dot(n))
}
