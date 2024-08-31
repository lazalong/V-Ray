import rand
import math
//import gx

// TODO: Use fully random or pseudo-random which is faster (with seed)?
fn rand_min_max(min f32, max f32) f32 {
	return min + rand.f32() * (max - min)
}

// Used for simple gamma correction.
// Almost all computer programs assume that an image is “gamma corrected”
// before being written into an image file. This means that the 0 to 1 
// values have some transform applied before being stored as a byte. 
// Images with data that are written without being transformed are said
// to be in linear space, whereas images that are transformed are said 
// to be in gamma space. It is likely that the image viewer you are 
// using is expecting an image in gamma space, but we are giving it 
// an image in linear space. Without it the image appears 
// inaccurately dark.
fn linear_to_gamma(linear_component f32) f32 {
	if linear_component > 0 {
		return math.sqrtf(linear_component)
	}
	return 0
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
