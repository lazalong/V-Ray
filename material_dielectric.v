import math
import rand

struct Dialectric {
	refraction_index f32
}

fn (d Dialectric) scatter(ray Ray, hit HitRecord, mut attenuation Vec3, mut scattered_ray Ray) bool {

/*	mut outward_normal := Vec3{}
	reflected := reflect(r_in.direction(), rec.normal)
	mut ni_over_nt := f32(0.0)
	attenuation = Vec3{1.0, 1.0, 1.0}
	mut refracted := Vec3{0, 0, 0}
	mut reflect_prob := f32(0.0)
	mut cosine := f32(0.0)
	if r_in.direction().dot(rec.normal) > 0 {
		outward_normal = rec.normal.scalar_mul(-1)
		ni_over_nt = d.ref_idx
		cosine = d.ref_idx * r_in.direction().dot(rec.normal) / r_in.direction().length()
	} else {
		outward_normal = rec.normal
		ni_over_nt = 1.0 / d.ref_idx
		cosine = -r_in.direction().dot(rec.normal)/r_in.direction().length()
	}
	if refract(r_in.direction(), outward_normal, ni_over_nt, mut refracted) {
		reflect_prob = schlick(cosine, d.ref_idx)
	} else {
		scattered = Ray{rec.p, reflected}
		reflect_prob = 1.0
	}
	if rand.f32() < reflect_prob {
		scattered = Ray{rec.p, reflected}
	} else {
		scattered = Ray{rec.p, refracted}
	}
*/
	attenuation = Color{1.0, 1.0, 1.0}
	mut ri := d.refraction_index
	if hit.front {
		ri = 1.0 / d.refraction_index
	}

	unit_direction := ray.direction().unit_vector()
	cos_theta := math.min(unit_direction.invert().dot(hit.normal), 1.0)
	sin_theta := math.sqrtf(1.0 - cos_theta * cos_theta)

	mut direction := Vec3{}

	// check if can reflect or refract
	if (ri * sin_theta > 1.0) || (reflectance(cos_theta, ri) > rand.f32()) { 
		direction = reflect(unit_direction, hit.normal)
	} else {
		refract(unit_direction, hit.normal, ri, mut direction)
	}
	
	scattered_ray = Ray{hit.p, direction}
	return true
}

// Uses the Snell lay: eta1 * sin(gamma1) = eta2 * sin(gamma2)
// with gamma being the angles from the normal
// eta are the refractive indices
fn refract(v Vec3, n Vec3, eta1_over_eta2 f32, mut refracted Vec3) bool {
	uv := v.unit_vector()
	dt := uv.dot(n)
	discriminant := 1.0 - eta1_over_eta2*eta1_over_eta2*(1-dt*dt)
	if discriminant > 0 {
		refracted = (uv - (n.mul(dt))).mul(eta1_over_eta2) - (n.mul(math.sqrtf(discriminant)))
		return true
	}
	return false
}

// Schlick Approximation 
// real glass has reflectivity that varies with angle 
// — look at a window at a steep angle and it becomes a mirror. 
// There is a big ugly equation for that, but almost everybody 
// uses a cheap and surprisingly accurate polynomial approximation 
// by Christophe Schlick.
fn reflectance(cosine f32, refraction_index f32) f32 {
	mut r0 := (1.0 - refraction_index) / (1.0 + refraction_index)
	r0 = r0 * r0
	return r0 + (1.0 - r0) * f32(math.pow((1 - cosine), 5))
}
