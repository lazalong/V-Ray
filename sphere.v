import math

struct Sphere {
mut:
	center   Point3
	radius   f32
	material IMaterial
}

// Implements interface Hitable
fn (s Sphere) hit(r Ray, t_min f32, t_max f32, mut rec HitRecord) bool {
	oc := s.center - r.ori
	a := r.dir.length_squared()
	h := r.dir.dot(oc)
	c := oc.length_squared() - s.radius * s.radius

	discriminant := h*h - a*c

	if discriminant < 0 {
		return false
	}

	sqr := math.sqrt(discriminant)

	// Find the nearest root that lies in the acceptable range.
	mut root := (h - sqr) / a
	if root <= t_min || root > t_max {
		root = (h + sqr) / a
		if root <= t_min || root > t_max {
			return false
		}
	}

	rec.t = f32(root)
	rec.p = r.at(rec.t)
	outward_normal := (rec.p - s.center).div(s.radius)
	rec.set_face_normal(r, outward_normal)
	rec.material = s.material
	
	return true
}
