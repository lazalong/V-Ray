import math

struct Vec3 {
mut:
	e0 f32
	e1 f32
	e2 f32
}

type Point3 = Vec3

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
