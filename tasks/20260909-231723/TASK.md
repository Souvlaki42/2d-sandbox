# old notes

- STATUS: CLOSED
- PRIORITY: 5
- TAGS: reference

## Tasks

- [ ] ~~Separate dirt and gravel~~
- [x] Add debugging menu
- [x] Add selection of block to place with middle click
- [x] Fix more bugs
- [ ] Add proper skin support from inside the game
- [x] Breaking foreground tiles, should spawn background ones sometimes
- [ ] Obviously optimize it, an empty 10000 tiles world uses 5GB RAM!
- [ ] Lighting
- [ ] Day/Night cycle
- [ ] Water
- [ ] Particles

## Bugs

- [x] Player sometimes spawns inside the terrain:
  1.  [x] 9667
  2.  [x] -604
  3.  [x] 7937
  4.  [x] 6883
  5.  [x] 1842
  6.  [x] 7624
- [x] Hands don't animate until first hit/place
- [x] Player face sticks into the borders
- [ ] Player shouldn't be able to break or place block not around them
- [x] Bugged collision on tile drops, under the player
- [x] Player can fall off the world
- [x] Blocks can be placed on top of the player pushing him around
- [x] background tiles should be selectable
  - [x] Infinite variations on background element placements
  - [x] Player placed tiles should always be in the foreground

## Refactors

- [ ] ~~Split general world code and terrain generation~~
- [x] Decide and rework the layering system
- [x] simplify coordinate systems
- [ ] ~~Add some globals and pathing~~
- [x] Rework/simplify player animations

## Proposals

- https://github.com/godotengine/godot-proposals/issues/11790
- https://github.com/godotengine/godot/pull/78991
- https://github.com/godotengine/godot-proposals/issues/2944
- https://github.com/godotengine/godot-proposals/issues/737
- https://github.com/godotengine/godot-proposals/issues/1571
- https://github.com/godotengine/godot-proposals/issues/1902
- https://github.com/godotengine/godot-proposals/issues/1321
- https://github.com/godotengine/godot-proposals/issues/2411

## Resources

- [2D Sandbox Tutorial Series for Unity](https://www.youtube.com/playlist?list=PLn1X2QyVjFVDE9syarF1HoUFwB_3K7z2y)
- [Reset variables API in Godot and GDScript](https://www.reddit.com/r/godot/comments/1p47ds3/reset_variables_api_in_godot_and_gdscript/)
- [2D Voxel Asset Pack by Kenney](https://www.kenney.nl/assets/voxel-pack)
- [Crosshair Pack by Kenney](https://www.kenney.nl/assets/crosshair-pack)
- [Icon Pack by Pixel Boy](https://pixel-boy.itch.io/icon-godot-node)

## Wanna be resources

- [Water Tutorial in Godot 4.5](https://www.youtube.com/watch?v=hmIRJZEyRMs)
- https://www.reddit.com/r/godot/comments/sdypwa/how_to_modulate_specific_tiles_in_a_tilemap/
- https://www.reddit.com/r/godot/comments/186fktw/tilemaps_modulating_single_tiles/
- https://forum.godotengine.org/t/modulate-individual-tilemap-tiles/22889/2
- https://forum.godotengine.org/t/how-can-i-make-the-ui-always-be-at-the-edge-of-the-screen/98976
- https://github.com/alijaya/GodotUpdateTileMap
- [https://youtu.be/dawZisSSUo8](https://youtu.be/BE_LTaGkGv4)
- https://www.reddit.com/r/godot/comments/1jpj901/how_do_i_achieve_similar_shading_on_my_tilemap/

| Space         | Unit   | Y-axis       | Who lives here                                           |
| ------------- | ------ | ------------ | -------------------------------------------------------- |
| Game logic    | tiles  | ↑ positive   | your rules, get_coordinates_from_position output         |
| Global pixels | pixels | ↓ increasing | player, world, physics, tilemap, mouse — all unified now |
| Screen        | pixels | ↓ increasing | what camera zoom 0.35 renders                            |
