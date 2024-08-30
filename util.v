import rand
//import gx

// TODO: Use fully random or pseudo-random which is faster (with seed)?
fn rand_min_max(min f32, max f32) f32 {
	return min + rand.f32() * (max - min)
}

/*
fn (mut c gx.Color) clamp(min u8, max u8) {
	if c.r < min c.r = min
	else if c.r > max c.r = max
	if c.g < min c.g = min
	else if c.g > max c.g = max
	if c.b < min c.b = min
	else if c.b > max c.b = max
}
*/
