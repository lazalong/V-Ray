struct Ray {
	ori 	Vec3
	dir	Vec3
}

fn (r Ray) origin() Vec3 { return r.ori }
fn (r Ray) direction() Vec3 { return r.dir }

// Return the point along the ray at a distance of t * ray.direction from the origin
fn (r Ray) at(t f32) Point3 { return r.ori + r.dir.mul(t) }
