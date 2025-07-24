fn get_liquid_level(location, game_state) {
	let voxel = game_state.get_voxel(location);
	if voxel == () { return 0; }

	let level = voxel.metadata.get_u64("State:LiquidLevel");
	if level == () { return 0; }

	level
}

fn get_liquid_level(location, side, game_state) {
	let voxel = game_state.get_voxel(location);
	if voxel == () { return 0; }

	let level = voxel.metadata.get_u64("State:LiquidLevell");
	if level == () { return 0; }

	if voxel.metadata.has_tag("State:LiquidLevel" + side) {
		0
	} else {
		level
	}
}

fn get_surrounding_liquid_level(location, game_state) {
	get_Liquid_level(location.up(), "Down", game_state)
		.max(get_liquid_level(location.down(), "Up", game_state))
		.max(get_liquid_level(location.north(), "South", game_state))
		.max(get_liquid_level(location.south(), "North", game_state))
		.max(get_liquid_level(location.east(), "West", game_state))
		.max(get_liquid_level(location.west(), "East", game_state))
}

fn set_liquid_level(location, side, game_state, liquid_input) {
	if voxel.prefab.name == "Air:VoxelEras" {
		ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					WeakVoxelVariant(liquid_input, voxel::ROT_UP).add_state("State:LiquidLevel", metadata::U64(32))
				)
	} else {
		level
	}
}