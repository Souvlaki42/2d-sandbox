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

## Generates a [NoiseTexture2D] using this noise instance.
## Parameter [size]: Accepts [int], [float] (square), or [Vector2], [Vector2i] (rectangular).
## Parameter [threshold]: Accepts a [Gradient] for full color mapping, or a [float] for a simple black/white cutoff.
func get_noise_texture(size: Variant, threshold: Variant) -> NoiseTexture2D:
	var image_size: Vector2i = Vector2i.ZERO
	var color_ramp: Gradient
	var texture: NoiseTexture2D = NoiseTexture2D.new()

	if size is Vector2 or size is Vector2i or size is Vector3 or size is Vector3i or size is Vector4 or size is Vector4i:
		image_size = Vector2i(size.x, size.y)
	elif size is int or size is float:
		image_size = Vector2i(size, size)

	if threshold is Gradient:
		color_ramp = threshold
	elif threshold is int or threshold is float:
		color_ramp = Gradient.new()
		color_ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		color_ramp.set_offset(0, 0.0)
		color_ramp.set_color(0, Color.BLACK)
		color_ramp.add_point(threshold, Color.WHITE)

	texture.width = image_size.x
	texture.height = image_size.y
	texture.noise = self
	texture.color_ramp = color_ramp
	texture.normalize = true

	return texture
