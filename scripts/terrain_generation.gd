@tool
extends TileMapLayer
class_name TerrainGenerator

var biome_noise: PerlinNoise = null
var biome_lookup: Dictionary[Color, Biome] = {}
var biome_data: PackedByteArray = PackedByteArray()
var cave_data: Dictionary[Biome, PackedByteArray] = {}
var ore_data: Dictionary[Ore, PackedByteArray] = {}

@export_category("Actions")
@export_tool_button("Generate Terrrain") var generate_terrain_btn: Callable = start_generation
@export_tool_button("Generate Noise Maps") var generate_noise_maps_btn: Callable = _generate_maps
@export_tool_button("Clear Everything") var reset_generation_btn: Callable = clear_everything

@export_category("Terrain Settings")
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_READ_ONLY) var noise_seed: int = 0
@export var world_size: int = 200
@export var height_addition: int = 50
@export var ground_offset: int = 10
@export var tile_size: int = 128

@export_category("Biome Settings")
@export var biome_map: Image = null
@export var biome_frequency: float = 0.01
@export var biome_colors: Gradient
@export var biomes: Array[Biome] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		start_generation()

func clear_everything() -> void:
	assert(not biomes.is_empty(), "Biomes should be here!")
	self.clear()
	cave_data.clear()
	ore_data.clear()
	biome_lookup.clear()

	biome_map = null
	for biome in biomes:
		biome.cave_noise_image = null
		for ore in biome.tile_atlas.get_ores():
			ore.spread_image = null

	noise_seed = 0
	notify_property_list_changed()

func start_generation() -> void:
	clear_everything()

	if noise_seed == 0:
		randomize()
		noise_seed = randi_range(-10000, 10000)
		seed(noise_seed)

	for biome in biomes:
		biome_lookup[biome.tint] = biome

	_generate_maps()
	_generate_terrain()

func _generate_maps() -> void:
	var group_id = WorkerThreadPool.add_group_task(_generate_map_task, 1 + biomes.size(), -1, true)
	WorkerThreadPool.wait_for_group_task_completion(group_id)
	notify_property_list_changed()

func _generate_map_task(index: int) -> void:
	if index == 0:
		biome_noise = PerlinNoise.new(noise_seed, biome_frequency)
		biome_map = generate_noise_image(biome_noise, world_size)
		biome_data = biome_map.get_data()
		return

	var biome: Biome = biomes[index - 1]
	biome.terrain_noise = PerlinNoise.new(noise_seed, biome.terrain_frequency)
	biome.cave_noise = PerlinNoise.new(noise_seed, biome.cave_frequency)
	biome.cave_noise_image = generate_noise_image(biome.cave_noise, world_size, biome.surface_value)
	cave_data[biome] = biome.cave_noise_image.get_data()

	for ore in biome.tile_atlas.get_ores():
		ore.noise = PerlinNoise.new(noise_seed, ore.frequency)
		ore.spread_image = generate_noise_image(ore.noise, world_size, ore.vein_size)
		ore_data[ore] = ore.spread_image.get_data()

func generate_noise_image(noise: PerlinNoise, size: int, threshold: float = -1) -> Image:
	var image: Image = Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	var buffer: PackedByteArray = image.get_data()

	# WARNING: This is too slow, for worlds with more than 100k tiles
	for i in range(size * size):
		var y: int = i / size
		var x: int = i % size

		var val: float = noise.get_unity_noise(x, y)
		var col: Color

		if threshold != -1:
			col = Color.WHITE if val > threshold else Color.BLACK
		else:
			col = biome_colors.sample(val)

		var off = i * 4
		buffer[off] = col.r8
		buffer[off+1] = col.g8
		buffer[off+2] = col.b8
		buffer[off+3] = col.a8

	image.set_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	return image

func get_biome(x: int, y: int) -> Biome:
	var offset: int = (y * world_size + x) * 4

	var r: int = biome_data[offset]
	var g: int = biome_data[offset+1]
	var b: int = biome_data[offset+2]
	var a: int = biome_data[offset+3]

	var color: int = (r << 24) | (g << 16) | (b << 8) | a
	return biome_lookup.get(color)

func _generate_terrain() -> void:
	var cells_to_set: Array[Vector2i] = []
	var source_ids: Array[int] = []
	var atlas_coords: Array[Vector2i] = []

	for x in range(world_size):
		for y in range(world_size):
			var biome: Biome = get_biome(x, y)
			if not biome: continue

			var height: float = biome.terrain_noise.get_unity_noise(x, 0) * biome.height_multiplier + height_addition
			if y >= height: break

			var off: int = (y * world_size + x) * 4
			var tile_to_place: Tile = null
			if y < height - biome.dirt_layer_height:
				tile_to_place = biome.tile_atlas.stone
				for ore in biome.tile_atlas.get_ores():
					if ore_data[ore][off] > 127:
						if height - y > ore.max_spawn_height:
							tile_to_place = ore
							break
			elif y < int(height - 1):
				tile_to_place = biome.tile_atlas.dirt
			else:
				tile_to_place = biome.tile_atlas.grass

			var is_cave = cave_data[biome][off] > 127

			if is_cave or not biome.generate_caves:
				cells_to_set.append(Vector2i(x, ground_offset - y))
				source_ids.append(tile_to_place.source_id)
				atlas_coords.append(tile_to_place.atlas_coord)

	for i in range(cells_to_set.size()):
		set_cell(cells_to_set[i], source_ids[i], atlas_coords[i])
