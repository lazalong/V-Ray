import rand

// TODO: Use fully random or pseudo-random which is faster (with seed)?
fn rand_min_max(min f32, max f32) f32 {
	return min + rand.f32() * (max - min)
}
