fn define(mod_info) {

	mod_info.add(TextureBuilder(
        "WaterIcon:Factory++",
        "factoryplusplus/assets/textures/water.png",
    ));

	mod_info.add(ItemBuilder(
        "Water:Factory++",
        "Water",
        "Water? it's solid? what? uhh don't drink it.",
        "WaterIcon:Factory++",
    ).pipette("Water:VoxelEras"));

	mod_info.add(
		VoxelBuilder(
			"Water:Factory++",
			"Water",
			"factoryplusplus/scripts/misc/water.rhai"
		).model(TransparentVoxelModel("factoryplusplus/assets/textures/water.png"))
		.lighting(voxel::LIGHT_TRANSPARENT)
		.break_rate(voxel::BREAK_RATE_FRAGILE)
		.pipette("Water:Factory++",)
		.does_tick()
		.does_message()
		.clear_colliders()
		.no_clip()
        .replacable_by_growth()
	);

	mod_info.add(
		VoxelBuilder(
			"WaterSource:Factory++",
			"Water ",
			"factoryplusplus/scripts/misc/water.rhai"
		).model(TransparentVoxelModel("factoryplusplus/assets/textures/water.png"))
		.lighting(voxel::LIGHT_TRANSPARENT)
		.break_rate(voxel::BREAK_RATE_FRAGILE)
		.pipette("Water:Factory++",)
		.does_tick()
		.does_message()
		.clear_colliders()
		.no_clip()
        .replacable_by_growth()
	);

	mod_info.add(
		ConstructBuilder(
			"Water:Factory++",
            "Water",
       		"Water? it's solid? what? uhh don't drink it.",
            "Building",
            "WaterIcon:VoxelEras",
			construct::ROT_NONE
		).variant(
			ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					WeakVoxelVariant("Water:Factory++", voxel::ROT_UP)
						.add_state("State:LiquidLevel", metadata::U64(1))
				)
		)
		.cost(WeakItemStack("OakPlank:VoxelEras", 1))
		.priority(10)
	);
}

fn on_break(voxel, location, target, entity, game_state) {
	if location == target {
		game_state.drop(WeakItemStack("Water:Factory++", 1), location);
	}

	event::ACCEPT
}

fn on_tick(voxel, location, game_state) {
	let voxel = game_state.get_voxel(location);
	let level = utility::get_level(location + voxel::SIDE_TOP.rotate(voxel.rotation).reflect().offset, game_state);
	let current_level = utility::get_level(location, game_state);
	
	if level != 0 && current_level == 0 || level == 0 && current_level != 0 {
		let state = voxel.metadata;
		state.set_u64("State:LiquidLevel", if level == 0 { 0 } else { 32 });
		game_state.set_voxel(location, game_state.get_voxel_prefab("Water" + if level == 1 { "Source" } else { "" } + ":Factory++").get_variant(voxel.rotation, state));
		
		game_state.send_message(location.north(), "LIQUID_UPDATE", ());
		game_state.send_message(location.up(), "LIQUID_UPDATE", ());
		game_state.send_message(location.east(), "LIQUID_UPDATE", ());
		game_state.send_message(location.south(), "LIQUID_UPDATE", ());
		game_state.send_message(location.down(), "LIQUID_UPDATE", ());
		game_state.send_message(location.west(), "LIQUID_UPDATE", ());
	}

	event::ACCEPT
}