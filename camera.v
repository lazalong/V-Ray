import math
import gx

struct Camera {
pub mut:
	aspect_ratio f32 = 16.0 / 9.0   // Ratio of image width over height
	pwidth  int      = 800          // Rendered image width in pixel count
mut:
	pheight int      = int(800.0 * 9.0 / 16.0)
	center Vec3      = Vec3{0,0,0}
	pixel00_loc Vec3 		= Vec3{0,0,0}
	pixel_delta_u Vec3 	= Vec3{0,0,0}
	pixel_delta_v Vec3 	= Vec3{0,0,0}
}

fn new_camera(aspect_ratio f32, pwidth int) Camera {

	mut pheight := int(pwidth / aspect_ratio)
	if pheight < 1 {
		pheight = 1
	}

	center := Vec3{0,0,0} // TODO pass as paramter?

	// Determine viewport dimensions
	focal_length := f32(1.0)
	viewport_height := f32(2.0)
	viewport_width := viewport_height * f32(pwidth) / f32(pheight)

	// Calculate the vectors across the horizontal and down the vertical viewport edges.
	viewport_u := Vec3{viewport_width, 0, 0}
	viewport_v := Vec3{0, -viewport_height, 0}

	// Calculate the horizontal and vertical delta vectors from pixel to pixel.
	pixel_delta_u := viewport_u.div(pwidth)
	pixel_delta_v := viewport_v.div(pheight)

	// Calculate the location of the upper left pixel.
	viewport_upper_left := center - Vec3{0.0, 0.0, focal_length} - viewport_u.div(2) - viewport_v.div(2)
	pixel00_loc := viewport_upper_left + (pixel_delta_u + pixel_delta_v).mul(0.5)

	return Camera {
		aspect_ratio,
		pwidth,
		pheight,
		center,
		pixel00_loc,
		pixel_delta_u,
		pixel_delta_v
	}
}

fn (c Camera) ray_color(r Ray, world HitableList) u32 {
	mut hit := new_hit_record()
	if world.hit(r, 0.001, math.max_f32, mut hit) {

		return u32(gx.rgb(
			u8(255.0*(hit.normal.e0 + 1) * 0.5),
			u8(255.0*(hit.normal.e1 + 1) * 0.5),
			u8(255.0*(hit.normal.e2 + 1) * 0.5),
		).abgr8())
	}

	unit_direction := r.dir.unit_vector()
	a := 0.5 * (unit_direction.y() + 1.0)
	mut a1 := gx.rgb(u8(255.0* (1.0 - a)), u8(255.0* (1.0 - a)), u8(255.0* (1.0 - a))) 
	a1 += gx.rgb(u8(127.0 * a), u8(200.0 * a), u8(255.0 * a))
	return u32(a1.abgr8())
//	return u32(gx.rgb(50,60,0).abgr8())
}

