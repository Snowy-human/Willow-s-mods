fn define(mod_info) {
	mod_info.add(TextureBuilder(
		"BandedIcon:Stones",
		"Stones/assets/items/bandedblock.png"
	));

	mod_info.add(TextureBuilder(
		"BandedBlockIcon:Stones",
		"Stones/assets/items/bandedblock.png"
	));

	mod_info.add(
		VoxelBuilder(
			"Banded:Stones",
			"Banded iron",
			"Stones/scripts/blocks/Banded.rhai"
		).model(SolidVoxelModel(
			"Stones/assets/textures/banded.png",
			"Stones/assets/textures/bandedtop.png",
			"Stones/assets/textures/banded.png",
			"Stones/assets/textures/banded.png",
			"Stones/assets/textures/bandedtop.png",
			"Stones/assets/textures/banded.png",))
		.pipette("Banded:Stones")
		.break_rate(voxel::BREAK_RATE_HARD)
		.tag("Solid:VoxelEras")
		.does_break()
	);

	mod_info.add(
		ConstructBuilder(
			"Banded:Stones",
			"Banded iron",
			"Some funky iron.",
			"Building",
			"BandedBlockIcon:Stones",
			construct::ROT_NONE
		).variant(
			ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					WeakVoxelVariant("Banded:Stones", voxel::ROT_UP)
				)
		)
		.cost(WeakItemStack("Stone:VoxelEras", 1))
		.cost(WeakItemStack("IronOre:VoxelEras", 2))
		.priority(2)
	);
}

fn on_break(voxel, location, target, entity, game_state) {
	if location == target {
		game_state.drop(WeakItemStack("Stone:VoxelEras", 1), location);
		game_state.drop(WeakItemStack("IronOre:VoxelEras", 2), location);
	}

	event::ACCEPT
}