import "voxel_eras/scripts/audio_source" as audio;

const MAX_ENERGY = game::TICK_RATE * 48;
const ENERGY_PER_INTERACT = game::TICK_RATE * 12;
const INTERACT_DELAY = game::TICK_RATE / 4;
const PROGRESS_TO_MINE = game::TICK_RATE * 6;

fn define(mod_info) {

	mod_info.add(ModelBuilder(
		"SupMiner:Factory++",
		"factoryplusplus/assets/models/Super Miner.glb"
	));

	mod_info.add(TextureBuilder(
        "SupMinerIcon:Factory++",
        "voxel_eras/assets/textures/ClockworkDrillSide.png",
    ));

	define_variant(
		"SupMiner:Factory++",
		"Miner (Unpowered)",
		SolidVoxelModel(
			"voxel_eras/assets/textures/OakPlankOutput.png",
			"voxel_eras/assets/textures/ClockworkDrillSide.png",
			"voxel_eras/assets/textures/OakWoodPlank.png"
		),
		mod_info
	);

	define_variant(
		"SupMinerOn:Factory++",
		"Miner (powered)",
		SolidVoxelModel(
			"voxel_eras/assets/textures/OakPlankOutput.png",
			"voxel_eras/assets/textures/ClockworkDrillSideAnim.png",
			"voxel_eras/assets/textures/OakWoodPlank.png"
		),
		mod_info
	);

	define_variant(
		"SupMinerStuck:VoxelEras",
		"Miner (Stalled)",
		SolidVoxelModel(
			"voxel_eras/assets/textures/OakPlankOutput.png",
			"voxel_eras/assets/textures/ClockworkDrillSideStuckAnim.png",
			"voxel_eras/assets/textures/OakWoodPlank.png"
		),
		mod_info
	);

	let default_place_variant = WeakVoxelVariant("SupMiner:Factory++", voxel::ROT_UP)
		.add_state("State:LastInteracted", metadata::U64(0))
		.add_state("State:ClockworkEnergy", metadata::U64(0))
		.add_state("State:Progress", metadata::U64(0))
		.add_state("State:Inventory", metadata::Inventory(0));
	
	mod_info.add(
		ConstructBuilder(
			"SupMiner:Factory++",
            "Miner",
            "Huh how do we power this?",
            "Machines",
            "SupMinerIcon:Factory++",
			construct::ROT_NONE
		).variant(
			ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					default_place_variant
				).require(
					0, -1, 0,
					WeakConstructRequirement(["Ore:VoxelEras"])
				).require(
					0, -1, 0,
					WeakConstructRequirement("Stone:VoxelEras")
				)
		)
		.cost(WeakItemStack("OakPlank:VoxelEras", 4))
		.cost(WeakItemStack("WoodenGear:VoxelEras", 4))
		.cost(WeakItemStack("PigIronIngot:VoxelEras", 8))
		.priority(2)
	);

	mod_info.add(SoundBuilder(
		"ClockworkDrillProgress1:VoxelEras",
		"Clockwork Drill Progress",
		"voxel_eras/assets/sounds/ClockworkDrillProgress1.mp3"
	));

	mod_info.add(SoundBuilder(
		"ClockworkDrillProgress2:VoxelEras",
		"Clockwork Drill Progress",
		"voxel_eras/assets/sounds/ClockworkDrillProgress2.mp3"
	));

	mod_info.add(SoundBuilder(
		"ClockworkDrillTick:VoxelEras",
		"Clockwork Drill Tick",
		"voxel_eras/assets/sounds/ClockworkDrillTick.mp3"
	));
}

private fn define_variant(identifier, name, model, mod_info) {
	mod_info.add(
		VoxelBuilder(
			identifier,
			name,
			"voxel_eras/scripts/nomad/clockwork_drill.rhai"
		).model(model)
		.pipette("ClockworkDrill:VoxelEras")
		.break_rate(voxel::BREAK_RATE_MACHINE)
		.tag("Solid:VoxelEras")
		.does_break()
		.does_tick()
		.does_interact()
		.does_message()
	);
}

fn on_break(voxel, location, target, entity, game_state) {
	if location == target {
		game_state.drop(WeakItemStack("OakPlank:VoxelEras", 4), location);
		game_state.drop(WeakItemStack("WoodenGear:VoxelEras", 4), location);
		game_state.drop(WeakItemStack("PigIronIngot:VoxelEras", 8), location);
	}

	event::ACCEPT
}

fn on_interact(voxel, location, entity, game_state) {
	if game_state.tick < voxel.metadata.get_u64("State:LastInteracted") + INTERACT_DELAY {
		return event::CANCEL;
	}

	let stored_energy = voxel.metadata.get_u64("State:ClockworkEnergy");
	if stored_energy + global::ENERGY_PER_INTERACT > global::MAX_ENERGY {
		return event::CANCEL;
	}

	let new_state = voxel.metadata;
	new_state.set_u64("State:LastInteracted", game_state.tick);
	new_state.set_u64("State:ClockworkEnergy", stored_energy + global::ENERGY_PER_INTERACT);

	game_state.set_voxel(
		location,
		voxel.get_variant(new_state)
	);

	event::ACCEPT
}

fn on_message(voxel, location, type, message, game_state) {
	if type != "CLOCKWORK" { return event::CANCEL; }
	let energy = message;

	let stored_energy = voxel.metadata.get_u64("State:ClockworkEnergy");
	if stored_energy + energy > global::MAX_ENERGY / 4 {
		return event::CANCEL;
	}

	let new_state = voxel.metadata;
	new_state.set_u64("State:ClockworkEnergy", stored_energy + energy);

	game_state.set_voxel(
		location,
		voxel.get_variant(new_state)
	);

	event::ACCEPT
}

fn on_tick(voxel, location, game_state) {
	let energy = voxel.metadata.get_u64("State:ClockworkEnergy");
	let progress = voxel.metadata.get_u64("State:Progress");

	if energy == 0 && progress == 0 && voxel.prefab.identifier != "ClockworkDrillOn:VoxelEras" {
		return event::ACCEPT;
	}

	let was_running = false;
	if progress < global::PROGRESS_TO_MINE {
		if energy > 0 {
			energy -= 1;
			progress += 1;
			was_running = true;
		}
	}

	if was_running && progress % (game::TICK_RATE / 4) == 3 {
		audio::spawn_oneshot_3d(
			"ClockworkDrillTick:VoxelEras",
			"Machine:VoxelEras",
			Vec3(location.x.to_float() + 0.5, location.y.to_float() + 0.5, location.z.to_float() + 0.5),
			game_state,
			1.,
			10.
		);
	}

	let stalled = false;
	if progress >= global::PROGRESS_TO_MINE {
		let below = game_state.get_voxel(location.down());

		let mining_drop = switch below.prefab.identifier.to_string() {
			"IronOre:VoxelEras" => WeakItemStack("IronOre:VoxelEras", 1),
			"CopperOre:VoxelEras" => WeakItemStack("CopperOre:VoxelEras", 1),
			"TinOre:VoxelEras" => WeakItemStack("TinOre:VoxelEras", 1),
			"CoalOre:VoxelEras" => WeakItemStack("Coal:VoxelEras", 1),
			"Floor:VoxelEras" => WeakItemStack("Stone:VoxelEras", 1),
			"Stone:VoxelEras" => WeakItemStack("Stone:VoxelEras", 1),
			_ => {
				stalled = true;
				()
			}
		};

		if mining_drop != () {
			// Try inserting into the bottom side of the block above
			if game_state.try_insert(location.up(), voxel::SIDE_BOTTOM, mining_drop) {
				// Success!
				audio::spawn_oneshot_3d(
					if game_state.random_bool(0.5) {
						"ClockworkDrillProgress1:VoxelEras"
					} else {
						"ClockworkDrillProgress2:VoxelEras"
					},
					"Machine:VoxelEras",
					Vec3(location.x.to_float() + 0.5, location.y.to_float() + 0.5, location.z.to_float() + 0.5),
					game_state,
					1.,
					35.
				);
			} else { 
				let above = game_state.get_voxel(location.up());
				if above.prefab.identifier == "Air:VoxelEras" {
					game_state.drop(mining_drop, location.up());
					audio::spawn_oneshot_3d(
						if game_state.random_bool(0.5) {
							"ClockworkDrillProgress1:VoxelEras"
						} else {
							"ClockworkDrillProgress2:VoxelEras"
						},
						"Machine:VoxelEras",
						Vec3(location.x.to_float() + 0.5, location.y.to_float() + 0.5, location.z.to_float() + 0.5),
						game_state,
						1.,
						35.
					);
				} else {
					stalled = true;
				}
			}
		}

		if !stalled {
			progress -= global::PROGRESS_TO_MINE;
		}
	}

	let new_state = voxel.metadata;
	new_state.set_u64("State:Progress", progress);
	new_state.set_u64("State:ClockworkEnergy", energy);

	game_state.set_voxel(
		location,
		game_state.get_voxel_prefab(
			if stalled {
				"ClockworkDrillStuck:VoxelEras"
			} else if was_running {
				"ClockworkDrillOn:VoxelEras"
			} else {
				"ClockworkDrill:VoxelEras"
			}
		).get_variant(voxel.rotation, new_state)
	);
	
	event::ACCEPT
}