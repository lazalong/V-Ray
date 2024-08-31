import gg
import gx
import runtime
import time

const chunk_height = 10 // the image is recalculated in chunks, each chunk processed in a separate thread

const zoom_factor = 1.1

const max_iterations = 255

const samples_per_pixel = 10 // count of random samples for each pixel

const shadow_acne_problem = 0.0001

struct ViewRect {
mut:
	x_min f64
	x_max f64
	y_min f64
	y_max f64
}

fn (v &ViewRect) width() f64 {
	return v.x_max - v.x_min
}

fn (v &ViewRect) height() f64 {
	return v.y_max - v.y_min
}

struct AppState {
mut:
	gg      &gg.Context = unsafe { nil }
	iidx    int
	pixels  &u32     = unsafe { nil } //= unsafe { vcalloc(pwidth * pheight * sizeof(u32)) }
	npixels &u32     = unsafe { nil } //= unsafe { vcalloc(pwidth * pheight * sizeof(u32)) } // all drawing happens here, results are swapped at the end
	view    ViewRect = ViewRect{-100.0, 100.0, -100.0, 100.0}
	scale   int      = 1
	ntasks  int      = runtime.nr_jobs()

	world HitableList  = HitableList{}

	camera Camera = Camera{}
}

const colors = [gx.black, gx.blue, gx.red, gx.green, gx.yellow, gx.orange, gx.purple, gx.white,
	gx.indigo, gx.violet, gx.black, gx.blue, gx.orange, gx.yellow, gx.green].map(u32(it.abgr8()))

struct ImageChunk {
	cview ViewRect
	ymin  f64
	ymax  f64
}

//------------------------------------------------------

fn main() {

	// Camera
	camera := new_camera(16.0 / 9.0, 800, 10.0, 50)

	// State
	mut state := &AppState{}
	state.camera = camera

	state.pixels     	= unsafe { vcalloc(camera.pwidth * camera.pheight * sizeof(u32)) }
	state.npixels     = unsafe { vcalloc(camera.pwidth * camera.pheight * sizeof(u32)) } // all drawing happens here, results are swapped at the end

	// World
	mut list := []Hitable{}
//	mat1 := &Lambertian{Vec3{0.5, 0.5, 0.5}}
//	list << &Sphere{Vec3{0,0,-1}, 0.5, mat1}
//	list << &Sphere{Vec3{0,-100.5,-1}, 100, mat1}
//	mat1 := &Lambertian{Vec3{0.5, 0.5, 0.5}}

	list << &Sphere{Vec3{ 0.0,-100.5, -1.0}, 100.0, &Lambertian{Vec3{0.8, 0.8, 0.0}}}
	list << &Sphere{Vec3{ 0.0,   0.0, -1.2},   0.5, &Lambertian{Vec3{0.1, 0.2, 0.5}}}
	list << &Sphere{Vec3{-1.0,   0.0, -1.0},   0.5, &Metal{Vec3{0.8, 0.8, 0.8}}}
	list << &Sphere{Vec3{ 1.0,   0.0, -1.0},   0.5, &Metal{Vec3{0.8, 0.6, 0.2}}}
	state.world.list = list

	state.gg = gg.new_context(
		width:         800 // TODO 
		height:        int(800 / state.camera.aspect_ratio) // TODO configurable
		create_window: true
		window_title:  'V-Ray'
		init_fn:       graphics_init
		frame_fn:      graphics_frame
		click_fn:      graphics_click
		move_fn:       graphics_move
		keydown_fn:    graphics_keydown
		scroll_fn:     graphics_scroll
		user_data:     state
	)

	println('Nb jobs: ${state.ntasks}')

	spawn state.update()
	state.gg.run()

	// clean
	state.gg.remove_cached_image_by_idx(state.iidx)
}

fn (mut state AppState) draw() {
	mut istream_image := state.gg.get_cached_image_by_idx(state.iidx)
	istream_image.update_pixel_data(unsafe { &u8(state.pixels) })
	size := gg.window_size()
	state.gg.draw_image(0, 0, size.width, size.height, istream_image)
}

fn (mut state AppState) update() {

	mut chunk_channel := chan ImageChunk{cap: state.ntasks}
	mut chunk_ready_channel := chan bool{cap: 1000}
	mut threads := []thread{cap: state.ntasks}
	defer {
		chunk_channel.close()
		threads.wait()
	}
	for t in 0 .. state.ntasks {
		threads << spawn state.worker(t, chunk_channel, chunk_ready_channel)
	}

	mut oview := ViewRect{}
	mut sw := time.new_stopwatch()

	// infinity loop
	for {
		sw.restart()
		cview := state.view

		if oview == cview {
			time.sleep(1 * time.millisecond)
				continue
		}

		// schedule chunks, describing the work:
		mut nchunks := 0
		for start := 0; start < state.camera.pheight; start += chunk_height {
			chunk_channel <- ImageChunk{
				cview: cview
				ymin:  start
				ymax:  start + chunk_height
			}
			nchunks++
		}
	
		// wait for all chunks to be processed: TODO: rework to make update non blocking...  
		for _ in 0 .. nchunks {
			_ := <-chunk_ready_channel
		}

		// everything is done, swap the buffer pointers
		state.pixels, state.npixels = state.npixels, state.pixels
		println('${state.ntasks:2} threads; ${sw.elapsed().milliseconds():3} ms / frame; scale: ${state.scale:4}; nbchunks: ${nchunks}')
		oview = cview
	}
}

@[direct_array_access]
fn (mut state AppState) worker(id int, input chan ImageChunk, ready chan bool) {

	for {
		chunk := <- input or { break }
		
		for py := chunk.ymin; py < chunk.ymax && py < state.camera.pheight; py++ {
			yrow := unsafe { &state.npixels[int(py * state.camera.pwidth)]} // get the row to work on

			for px := 0; px < state.camera.pwidth; px++ {

				unsafe {
					// To color by chunks
					//yrow[px] = colors[int(chunk.ymin) & 15]

					// To have the 'first grandient image' see Image 1
					//r := f32(px) * 256.0 /(state.pwidth -1)
					//g := f32(py) * 256.0 /(state.pheight -1)
					//yrow[px] = u32(gx.rgb(u8(r),u8(g),0).abgr8())

				//	yrow[px] = state.camera.render_pixel(px, f32(py), state.world)
					yrow[px] = state.camera.render_pixel_antialiased(px, f32(py), state.world)
				}
			}
		}		
		ready <- true
	}
}

fn (mut state AppState) zoom(zoom_factor f64) {
/*	
	c_x, c_y := (state.view.x_max + state.view.x_min) / 2, (state.view.y_max + state.view.y_min) / 2
	d_x, d_y := c_x - state.view.x_min, c_y - state.view.y_min
	state.view.x_min = c_x - zoom_factor * d_x
	state.view.x_max = c_x + zoom_factor * d_x
	state.view.y_min = c_y - zoom_factor * d_y
	state.view.y_max = c_y + zoom_factor * d_y
	state.scale += if zoom_factor < 1 { 1 } else { -1 }
*/
}

fn (mut state AppState) center(s_x f64, s_y f64) {
/*
	c_x, c_y := (state.view.x_max + state.view.x_min) / 2, (state.view.y_max + state.view.y_min) / 2
	d_x, d_y := c_x - state.view.x_min, c_y - state.view.y_min
	state.view.x_min = s_x - d_x
	state.view.x_max = s_x + d_x
	state.view.y_min = s_y - d_y
	state.view.y_max = s_y + d_y
*/
}

fn graphics_init(mut state AppState) {
	state.iidx = state.gg.new_streaming_image(state.camera.pwidth, state.camera.pheight, 4, pixel_format: .rgba8) // 4 = nb channels  TODO: try .rgba16f .rgba32ui .rgba32f
}

fn graphics_frame(mut state AppState) {
	state.gg.begin()
	state.draw()
	state.gg.end()
}

fn graphics_click(x f32, y f32, btn gg.MouseButton, mut state AppState) {
	if btn == .right {
//		size := gg.window_size()
//		m_x := (x / size.width) * state.view.width() + state.view.x_min
//		m_y := (y / size.height) * state.view.height() + state.view.y_min
//		state.center(m_x, m_y)
	}
}

fn graphics_move(x f32, y f32, mut state AppState) {
	if state.gg.mouse_buttons.has(.left) {
/*		size := gg.window_size()
		d_x := (f64(state.gg.mouse_dx) / size.width) * state.view.width()
		d_y := (f64(state.gg.mouse_dy) / size.height) * state.view.height()
		state.view.x_min -= d_x
		state.view.x_max -= d_x
		state.view.y_min -= d_y
		state.view.y_max -= d_y
*/
	}
}

fn graphics_scroll(e &gg.Event, mut state AppState) {
//	state.zoom(if e.scroll_y < 0 { zoom_factor } else { 1 / zoom_factor })
}

fn graphics_keydown(code gg.KeyCode, mod gg.Modifier, mut state AppState) {
/*
	s_x := state.view.width() / 5
	s_y := state.view.height() / 5
	// movement
	mut d_x, mut d_y := 0.0, 0.0
	if code == .enter {
		println('> ViewRect{${state.view.x_min}, ${state.view.x_max}, ${state.view.y_min}, ${state.view.y_max}}')
	}
	if state.gg.pressed_keys[int(gg.KeyCode.left)] {
		d_x -= s_x
	}
	if state.gg.pressed_keys[int(gg.KeyCode.right)] {
		d_x += s_x
	}
	if state.gg.pressed_keys[int(gg.KeyCode.up)] {
		d_y -= s_y
	}
	if state.gg.pressed_keys[int(gg.KeyCode.down)] {
		d_y += s_y
	}
	state.view.x_min += d_x
	state.view.x_max += d_x
	state.view.y_min += d_y
	state.view.y_max += d_y
	// zoom in/out
	if state.gg.pressed_keys[int(gg.KeyCode.left_bracket)]
		|| state.gg.pressed_keys[int(gg.KeyCode.z)] {
		state.zoom(1 / zoom_factor)
		return
	}
	if state.gg.pressed_keys[int(gg.KeyCode.right_bracket)]
		|| state.gg.pressed_keys[int(gg.KeyCode.x)] {
		state.zoom(zoom_factor)
		return
	}
*/
}
