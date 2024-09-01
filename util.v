import rand
import math

// TODO: Use fully random or pseudo-random which is faster (with seed)?
fn rand_min_max(min f32, max f32) f32 {
	return min + rand.f32() * (max - min)
}

fn hit_shpere(center Point3, radius f32, r Ray) f32 {
	oc := center - r.ori
	a := r.dir.length_squared()
	h := r.dir.dot(oc)
	c := oc.length_squared() - radius*radius

	discriminant := h*h - a*c

	if discriminant < 0 {
		return -1.0
	} else {
		return (h - math.sqrtf(discriminant)) / a
	}
}

fn angle_to_radian(degree f32) f32 {
	return f32(degree * math.pi / 180.0)
}
