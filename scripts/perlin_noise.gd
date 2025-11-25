@tool
extends FastNoiseLite
class_name PerlinNoise

func _init(noise_seed: int, noise_frequency: float) -> void:
	seed = noise_seed
	frequency = noise_frequency
	noise_type = FastNoiseLite.TYPE_PERLIN
	fractal_type = FastNoiseLite.FRACTAL_NONE

func get_unity_noise(x: int, y: int) -> float:
	return clamp((get_noise_2d(x, y) + 1.0) / 2.0, 0.0, 1.0)

func get_threshold_image(size: int, threshold: float) -> Image:
	var image: Image = Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	
	for x: int in range(size):
		for y: int in range(size):
			if  get_unity_noise(x, y) > threshold:
				image.set_pixel(x, y, Color.WHITE)
	return image
