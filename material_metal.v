
fn reflect(v Vec3, n Vec3) Vec3 {
	return v - n.mul(2.0 * v.dot(n))
}

struct Metal {
	albedo Vec3
//	fuzz f32
}

fn (m Metal) scatter(ray Ray, hit HitRecord, mut attenuation Vec3, mut scattered_ray Ray) bool {
	reflected := reflect(ray.direction().unit_vector(), hit.normal)
	scattered_ray = Ray{hit.p, reflected} // + (random_in_unit_sphere().mul(m.fuzz))}
	attenuation = m.albedo
	return true
}
