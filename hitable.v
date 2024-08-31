

struct HitRecord {
mut:
	t			f32 		// hit if this value is in interval t_min and t_max
	p			Point3
	normal	Vec3
	material IMaterial
	front		bool 		// true if outside or front face
}

interface Hitable {
	// Hit if HitRecord.t value is in interval [t_min, t_max]
	hit(r Ray, t_min f32, t_max f32, mut rec HitRecord) bool
}

fn new_hit_record() HitRecord {
	return HitRecord {
		0,
		Point3{0,0,0},
		Vec3{0,0,0},
		&Lambertian{Vec3{0,0,0}}, // TODO ??? Adding this makes it that the code doesn't run so time in prod but work in debug...
		true
	}
}

// Sets the hit record normal vector
// The parameter outward_normal is assumed to have unit length
fn (mut hr HitRecord) set_face_normal(ray Ray, outward_normal Vec3) {
	hr.front = ray.dir.dot(outward_normal) < 0
	if hr.front {
		hr.normal = outward_normal
	} else {
		hr.normal.e0 = -outward_normal.e0
		hr.normal.e1 = -outward_normal.e1
		hr.normal.e2 = -outward_normal.e2
	}
}
