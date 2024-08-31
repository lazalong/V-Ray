import math
import gx

struct Camera {
pub mut:
	aspect_ratio f32        = 16.0 / 9.0   // Ratio of image width over height
	pwidth  int             = 800          // Rendered image width in pixel count
	samples_per_pixel f32   = 10           // Count of random samples for each pixel
	max_depth int           = 10           // Maximum nb of ray bounces into scene
mut:
	pheight int             = int(800.0 * 9.0 / 16.0)
	center Vec3             = Vec3{0,0,0}
	pixel00_loc Vec3        = Vec3{0,0,0}
	pixel_delta_u Vec3      = Vec3{0,0,0}
	pixel_delta_v Vec3      = Vec3{0,0,0}
	pixel_samples_scale f32 = f32(1.0 / samples_per_pixel)
}

fn new_camera(aspect_ratio f32, pwidth int, samples_per_pixel f32,
	max_depth int) Camera {

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
		samples_per_pixel,
		max_depth,
		pheight,
		center,
		pixel00_loc,
		pixel_delta_u,
		pixel_delta_v,
		1.0 / samples_per_pixel 
	}
}

// Use .abgr8() to get the u32 color
// TODO Return a Vec3/Color and only convert into gx.rgb at last moment
fn (c Camera) ray_color(r Ray, world HitableList, depth int) gx.Color {
	// Exceeding ray bounce limit, no more light is gathered
	if depth <= 0 {
		return gx.rgb(0,0,0)
	}

	mut hit := new_hit_record()
	if world.hit(r, shadow_acne_problem, math.max_f32, mut hit) {

		/*
		// Returns simply a color depending on the normal
		return gx.rgb(
			u8(255.0*(hit.normal.e0 + 1) * 0.5),
			u8(255.0*(hit.normal.e1 + 1) * 0.5),
			u8(255.0*(hit.normal.e2 + 1) * 0.5),
		)
		*/

		// Returns a gray diffuse sphere (ch. 9.1)
		// Simple scattering
		// direction := random_on_hemisphere(hit.normal)
		// Lambertian Reflection
		direction := hit.normal + random_unit_vector()

		mut rc := c.ray_color(Ray{hit.p, direction}, world, depth - 1)
		// TODO: Better way to divide a rgb by 2 ??
		rc.r -= rc.r / 2
		rc.g -= rc.g / 2
		rc.b -= rc.b / 2
		return rc
	}

	unit_direction := r.dir.unit_vector()
	a := 0.5 * (unit_direction.y() + 1.0)
	mut a1 := gx.rgb(u8(255.0* (1.0 - a)), u8(255.0* (1.0 - a)), u8(255.0* (1.0 - a))) 
	a1 += gx.rgb(u8(127.0 * a), u8(200.0 * a), u8(255.0 * a))
	return a1
//	return gx.rgb(50,60,0)
}

fn (c Camera) render_pixel(px f32, py f32, world HitableList) u32 {
	pixel_center := c.pixel00_loc + 
		c.pixel_delta_u.mul(f32(px)) + c.pixel_delta_v.mul(f32(py))
	ray_direction := pixel_center - c.center
	r := Ray {
		ori: c.center
		dir: ray_direction
	}

	// Get the color of the ray
   return u32(c.ray_color(r, world, c.max_depth).abgr8())
}

fn (c Camera) render_pixel_antialiased(px f32, py f32, world HitableList) u32 {
	mut color := Vec3{0,0,0}

	for sample := 0; sample < c.samples_per_pixel; sample++ {
		offset := sample_square()
		pixel_center := c.pixel00_loc + 
			c.pixel_delta_u.mul(f32(px) + offset.x()) + c.pixel_delta_v.mul(f32(py) + offset.y())
		
		ray_direction := pixel_center - c.center
		r := Ray {
			ori: c.center
			dir: ray_direction
		}
		
		rc := c.ray_color(r, world, c.max_depth)
		color.e0 = color.x() + f32(rc.r)
		color.e1 = color.y() + f32(rc.g)
		color.e2 = color.z() + f32(rc.b)
	}

	color = color.mul(c.pixel_samples_scale) // aka  divide by nb samples of pixels

	// Get the color of the ray
   return u32(gx.rgb(u8(color.x()), u8(color.y()), u8(color.z())).abgr8())
}
