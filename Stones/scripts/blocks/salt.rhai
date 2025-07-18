fn define(mod_info) {
	mod_info.add(TextureBuilder(
		"SaltIcon:Stones",
		"Stones/assets/items/saltitem.png"
	));

	mod_info.add(TextureBuilder(
		"SaltBlockIcon:Stones",
		"Stones/assets/items/saltblock.png"
	));


	mod_info.add(ItemBuilder(
		"Salt:Stones",
		"Salt",
		"A chunk of salt.",
		"SaltIcon:Stones"
	).pipette("Salt:Stones"));

	mod_info.add(
		VoxelBuilder(
			"Salt:Stones",
			"Salt",
			"Stones/scripts/blocks/salt.rhai"
		).model(SolidVoxelModel(
			"Stones/assets/textures/salt.png",
			"Stones/assets/textures/salttop.png",
			"Stones/assets/textures/salt.png",
			"Stones/assets/textures/salt.png",
			"Stones/assets/textures/salttop.png",
			"Stones/assets/textures/salt.png",))
		.pipette("Salt:Stones")
		.break_rate(voxel::BREAK_RATE_SOFT)
		.tag("Solid:VoxelEras")
		.does_break()
	);

	mod_info.add(
		ConstructBuilder(
			"Salt:Stones",
			"Salt",
			"I do recommend licking it!",
			"Building",
			"SaltBlockIcon:Stones",
			construct::ROT_CARDINAL
		).variant(
			ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					WeakVoxelVariant("Salt:Stones", voxel::ROT_UP)
				)
		)
		.cost(WeakItemStack("Salt:Stones", 4))
		.variant(ConstructVariantBuilder(voxel::ROT_UP)
			.place(
				0, 0, 0,
				WeakVoxelVariant("Salt:Stones", voxel::ROT_UP)
			)
		).variant(ConstructVariantBuilder(voxel::ROT_DOWN)
			.place(
				0, 0, 0,
				WeakVoxelVariant("Salt:Stones", voxel::ROT_DOWN)
			)
		).variant(ConstructVariantBuilder(voxel::ROT_NORTH)
			.place(
				0, 0, 0,
				WeakVoxelVariant("Salt:Stones", voxel::ROT_NORTH)
			)
		).variant(ConstructVariantBuilder(voxel::ROT_SOUTH)
			.place(
				0, 0, 0,
				WeakVoxelVariant("Salt:Stones", voxel::ROT_SOUTH)
			)
		).variant(ConstructVariantBuilder(voxel::ROT_EAST)
			.place(
				0, 0, 0,
				WeakVoxelVariant("Salt:Stones", voxel::ROT_EAST)
			)
		).variant(ConstructVariantBuilder(voxel::ROT_WEST)
			.place(
				0, 0, 0,
				WeakVoxelVariant("Salt:Stones", voxel::ROT_WEST)
			)
		)
		.priority(2)
	);

	mod_info.add(
		RecipeBuilder(
			"SaltMortar:VoxelEras",
			"Grind Stone and hopfully get salt",
			0,
			"SaltIcon:Stones"
		).crafted_in("Mortar:VoxelEras")
		.with_input(WeakItemStack("Stone:VoxelEras", 3))
		.with_output(WeakItemStack("Salt:Stones", 1))
	);
	mod_info.add(
		RecipeBuilder(
			"SaltGrinder:VoxelEras",
			"Grind sand and get salt",
			0,
			"SaltIcon:Stones"
		).crafted_in("Grinder:VoxelEras")
		.with_input(WeakItemStack("Sand:VoxelEras", 1))
		.with_output(WeakItemStack("Salt:Stones", 1))
	);
}

fn on_break(voxel, location, target, entity, game_state) {
	if location == target {
		game_state.drop(WeakItemStack("Salt:Stones", 4), location);
	}

	event::ACCEPT
}