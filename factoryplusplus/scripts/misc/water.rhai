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
		.pipette("CrudeGlass:Factory++",)
		.tag("Solid:VoxelEras")
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
				)
		)
		.cost(WeakItemStack("Water:Factory++", 1))
		.priority(10)
	);
}