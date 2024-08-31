

// Lambertian material
struct Lambertian {
	albedo Vec3
}

fn (m Lambertian) scatter(ray Ray, hit HitRecord, mut attenuation Vec3, mut scattered_ray Ray) bool {
	mut scatter_direction := hit.normal + random_in_unit_sphere()

	// Catch degenerate scatter direction
	// If the random unit vector we generate is exactly opposite the normal vector,
	// the two will sum to zero, which will result in a zero scatter 
	// direction vector. This leads to bad scenarios later on (infinities and NaNs),
	// so we need to intercept the condition before we pass it on.
	if scatter_direction.is_near_zero() {
		scatter_direction = hit.normal
	}

	scattered_ray = Ray{hit.p, scatter_direction}
	attenuation = m.albedo
	return true
}
