import math
import rand

struct Vec3 {
mut:
	e0 f32
	e1 f32
	e2 f32
}

type Point3 = Vec3
type Color = Vec3

fn (v Vec3) x() f32 { return v.e0 }
fn (v Vec3) y() f32 { return v.e1 }
fn (v Vec3) z() f32 { return v.e2 }
fn (v Vec3) r() f32 { return v.e0 }
fn (v Vec3) g() f32 { return v.e1 }
fn (v Vec3) b() f32 { return v.e2 }

fn (a Vec3) str() string {
	return '{${a.e0}, ${a.e1}, ${a.e2}}'
}

fn (a Vec3) + (b Vec3) Vec3 {
	return Vec3{a.e0 + b.e0, a.e1 + b.e1, a.e2 + b.e2}
}

fn (a Vec3) - (b Vec3) Vec3 {
	return Vec3{a.e0 - b.e0, a.e1 - b.e1, a.e2 - b.e2}
}

fn (a Vec3) min (b f32) Vec3 {
	return Vec3{a.e0 - b, a.e1 - b, a.e2 - b}
}

fn (a Vec3) * (b Vec3) Vec3 {
	return Vec3{a.e0 * b.e0, a.e1 * b.e1, a.e2 * b.e2}
}

fn (a Vec3) mul(b f32) Vec3 {
	return Vec3{a.e0 * b, a.e1 * b, a.e2 * b}
}

fn (a Vec3) / (b Vec3) Vec3 {
	return Vec3{a.e0 / b.e0, a.e1 / b.e1, a.e2 / b.e2}
}

fn (a Vec3) div (b f32) Vec3 {
	return Vec3{a.e0 / b, a.e1 / b, a.e2 / b}
}

fn (v Vec3) length() f32 {
	return math.sqrtf(v.dot(v))
}

fn (v Vec3) length_squared() f32 {
	return v.e0 * v.e0 + v.e1 * v.e1 + v.e2 * v.e2
}

fn (v Vec3) invert() Vec3 {
	return Vec3{-v.e0, -v.e1, -v.e2}
}

fn (v1 Vec3) dot(v2 Vec3) f32 {
	return v1.e0*v2.e0 + v1.e1*v2.e1 + v1.e2*v2.e2
}

fn (v1 Vec3) cross(v2 Vec3) Vec3 {
	return Vec3 {
		v1.y()*v2.z() - v1.z()*v2.y(),
		-(v1.x()*v2.z() - v1.z()*v2.x()),
		v1.x()*v2.y() - v1.y()*v2.x()
	}
}

fn (v Vec3) unit_vector() Vec3 {
	return v.div(v.length())
}

// [0,1]
fn random_vec3() Vec3 {
	return Vec3{rand.f32(), rand.f32(), rand.f32()}
}

// [min,max]
fn random_vec3_min_max(min f32, max f32) Vec3 {
	return Vec3{rand_min_max(min, max), rand_min_max(min, max), rand_min_max(min, max)}
}

fn random_in_unit_sphere() Vec3 {
	mut v := Vec3{}
	for {
		v = random_vec3_min_max(-1,1)
		if v.length_squared() < 1.0 {
			break
		}
	}
	return v
}

fn random_unit_vector() Vec3 {
	return random_in_unit_sphere().unit_vector()
}

// Return a vector in the same hemishpere as the normal
fn random_on_hemisphere(normal Vec3) Vec3 {
	mut on_unit_sphere := random_unit_vector()
	if on_unit_sphere.dot(normal) > 0.0 { 
		// In same hemishpere as normal
		return on_unit_sphere
	} else {
		return on_unit_sphere.mul(-1.0) // invert
	}
}

// Returns a Vec3 to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
fn sample_square() Vec3 {
	return Vec3{rand_min_max(-0.5, 0.5), rand_min_max(-0.5, 0.5), 0}
}

fn (mut v Vec3) clamp(min f32, max f32) {
	if v.e0 < min { v.e0 = min }
	else if v.e0 > max { v.e0 = max }
	if v.e1 < min { v.e1 = min }
	else if v.e1 > max { v.e1 = max }
	if v.e2 < min { v.e2 = min }
	else if v.e2 > max { v.e2 = max }
}

fn (v Vec3) is_near_zero() bool {
	return (math.abs(v.e0) < 0.00000001)
		&& (math.abs(v.e1) < 0.00000001)
		&& (math.abs(v.e2) < 0.00000001)
}
