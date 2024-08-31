
interface IMaterial {
	scatter(ray Ray, hit HitRecord, mut attenuation Vec3, mut scattered_ray Ray) bool
}
