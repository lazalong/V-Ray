import math
import gx

// From https://raytracing.github.io/books/RayTracingInOneWeekend.html
//
// Note: Defocus blur in raytracing is called by photographers as depth of field!
//
// The reason we have defocus blur in real cameras is because they need a big hole
// (rather than just a pinhole) through which to gather light. A large hole would defocus 
// everything, but if we stick a lens in front of the film/sensor, there will be a certain 
// distance at which everything is in focus. Objects placed at that distance will appear 
// in focus and will linearly appear blurrier the further they are from that distance. 
// You can think of a lens this way: all light rays coming from a specific point 
// at the focus distance — and that hit the lens — will be bent back to a single point 
// on the image sensor.
// The “aperture” is a hole to control how big the lens is effectively. 
// For a real camera, if you need more light you make the aperture bigger, 
// and will get more blur for objects away from the focus distance. 
// For our virtual camera, we can have a perfect sensor and never need more light, 
// so we only use an aperture when we want defocus blur.

struct Camera {
pub mut:
	aspect_ratio f32        = 16.0 / 9.0     // Ratio of image width over height
	pwidth  int             = 800            // Rendered image width in pixel count
	samples_per_pixel f32   = 10             // Count of random samples for each pixel
	max_depth int           = 10             // Maximum nb of ray bounces into scene
	vfov f32                = 90             // Field of view [degree convereted in radian] - visual angle from edge to edge of rendered image. Since our image is not square, the fov is different horizontally and vertically.

	look_from Point3        = Point3{}       // Point camera is looking from
	look_at   Point3        = Point3{0,0,-1} // Point camera is looking at
	vup       Vec3          = Vec3{0,1,0}    // Camera-relative 'up' direction
	defocus_angle f32                        // Variation angle of rays through each pixel
	focus_distance f32      = 10             // Distance from camera lookfrom point to plane of perfect focus

mut:
	pheight int             = int(800.0 * 9.0 / 16.0)
	center Vec3             = Vec3{0,0,0}
	pixel00_loc Vec3        = Vec3{0,0,0}
	pixel_delta_u Vec3      = Vec3{0,0,0}
	pixel_delta_v Vec3      = Vec3{0,0,0}
	pixel_samples_scale f32 = f32(1.0 / samples_per_pixel)
	u Vec3                  = Vec3{}         // Camera frame basis vectors
	v Vec3                  = Vec3{}
	w Vec3                  = Vec3{}
	defocus_disk_u Vec3     = Vec3{}         // Defocus disk horizontal radius
   defocus_disk_v Vec3     = Vec3{}         // Defocus disk vertical radius
}

fn new_camera(aspect_ratio f32, pwidth int, samples_per_pixel f32,
	max_depth int, vfov f32, look_from Vec3, look_at Vec3, vup Vec3,
	defocus_angle f32, focus_distance f32) Camera {

	mut pheight := int(pwidth / aspect_ratio)
	if pheight < 1 {
		pheight = 1
	}

	// Determine viewport dimensions
	// The focal length is the distance between the camera center and the image plane.
	//  (aka focal_length := (look_from - look_at).length())
	// The focal distance is the distance between the center and the plane where everything is in perfect focus
	// For this camera, we will put the pixel grid right on the focus plane (at focal distance)
	theta := vfov * math.pi/180.0
	half_height := math.tan(theta/2.0)

	viewport_height := f32(2.0 * half_height * focus_distance)
	viewport_width := viewport_height * f32(pwidth) / f32(pheight)

	// Calculate the u,v,w unit basis vectors for the camera coordinate frame.
	w := (look_from - look_at).unit_vector()
	u := vup.cross(w).unit_vector()
	v := w.cross(u)

	// Calculate the vectors across the horizontal and down the vertical viewport edges.
	viewport_u := u.mul(viewport_width)   // Vector across viewport horizontal edge
	viewport_v := v.mul(-viewport_height) // Vector down viewport vertical edge

	// Calculate the horizontal and vertical delta vectors from pixel to pixel.
	pixel_delta_u := viewport_u.div(pwidth)
	pixel_delta_v := viewport_v.div(pheight)

	// Calculate the location of the upper left pixel.
	viewport_upper_left := look_from - w.mul(focus_distance) - viewport_u.div(2) - viewport_v.div(2)
	pixel00_loc := viewport_upper_left + (pixel_delta_u + pixel_delta_v).mul(0.5)

	// Calculate the camera defocus disk basis vectors
	defocus_radius := f32(focus_distance * math.tan(angle_to_radian(defocus_angle * 0.5)))
	defocus_disk_u := u.mul(defocus_radius)
	defocus_disk_v := v.mul(defocus_radius)

	return Camera {
		aspect_ratio,
		pwidth,
		samples_per_pixel,
		max_depth,
		vfov,
		look_from,
		look_at,
		vup,
		defocus_angle, 
		focus_distance

		pheight,
		look_from,
		pixel00_loc,
		pixel_delta_u,
		pixel_delta_v,
		1.0 / samples_per_pixel,
		u,
		v,
		w,
		defocus_disk_u,
		defocus_disk_v
	}
}

// Use .abgr8() to get the u32 color
// TODO Return a Vec3/Color and only convert into gx.rgb at last moment
fn (c Camera) ray_color(r Ray, world HitableList, depth int) Color {
	// Exceeding ray bounce limit, no more light is gathered
	if depth <= 0 {
		return Color{0,0,0}
	}

	mut hit := new_hit_record()
	if world.hit(r, shadow_acne_problem, math.max_f32, mut hit) {

		// return gx.rgb(50,60,0)

		/*
		// Returns simply a color depending on the normal
		return gx.rgb(
			u8(255.0*(hit.normal.e0 + 1) * 0.5),
			u8(255.0*(hit.normal.e1 + 1) * 0.5),
			u8(255.0*(hit.normal.e2 + 1) * 0.5),
		)
		*/

		/*
		// Returns a gray diffuse sphere (ch. 9.1)
		// Simple scattering
		// direction := random_on_hemisphere(hit.normal)
		// Lambertian Reflection
		direction := hit.normal + random_unit_vector()

		//mut rc := c.ray_color(Ray{hit.p, direction}, world, depth - 1)
		//rc = rc.div(2.0)

		return rc
		*/

		// Material scattering
		mut scattered := Ray{}
		mut attenuation := Vec3{}
		if hit.material.scatter(r, hit, mut attenuation, mut scattered) {
			return attenuation * c.ray_color(scattered, world, depth - 1)
		}
		return Color{0,0,0}
	}

	unit_direction := r.dir.unit_vector()
	a := 0.5 * (unit_direction.y() + 1.0)

	mut a1 := Color{1.0 - a, 1.0 - a, 1.0 - a}
	a1 = a1 + Color{a*0.5, a*0.8, a} // TODO param bluish color. 
	return a1
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
	//   return u32(c.ray_color(r, world, c.max_depth).abgr8())
	mut cc := c.ray_color(r, world, c.max_depth)
	cc.clamp(0.0, 0.9999)
   return u32(gx.rgb(u8(256.0* cc.r()), u8(256.0* cc.g()), u8(256.0* cc.b())).abgr8())
}

fn (c Camera) render_pixel_antialiased(px f32, py f32, world HitableList) u32 {
	mut color := Vec3{0,0,0}

	for sample := 0; sample < c.samples_per_pixel; sample++ {
		offset := sample_square()
		pixel_center := c.pixel00_loc + 
			c.pixel_delta_u.mul(f32(px) + offset.x()) + c.pixel_delta_v.mul(f32(py) + offset.y())
		
		mut ray_origin := if c.defocus_angle <= 0 { c.center } else { c.defocus_disk_sample()	}

		ray_direction := pixel_center - ray_origin
		r := Ray {
			ori: ray_origin
			dir: ray_direction
		}
		
		color = color + c.ray_color(r, world, c.max_depth)
	}

	color = color.mul(c.pixel_samples_scale) // aka  divide by nb samples of pixels

	// Apply a linear to gamma transform for gamma 2
	color.linear_to_gamma()

	color.clamp(0.0, 0.9999)

	// Get the color of the ray 
	// TODO: Should we do this later so we can choose the format?
   return u32(gx.rgb(u8(256.0* color.r()), u8(256.0* color.g()), u8(256.0* color.b())).abgr8())
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

fn (mut v Vec3) linear_to_gamma() {
	v.e0 = linear_to_gamma(v.e0)
	v.e1 = linear_to_gamma(v.e1)
	v.e2 = linear_to_gamma(v.e2)
}

fn (c Camera) defocus_disk_sample() Point3 {
	p := random_in_unit_disk()
	return c.center + c.defocus_disk_u.mul(p.e0) + c.defocus_disk_v.mul(p.e1)
}
