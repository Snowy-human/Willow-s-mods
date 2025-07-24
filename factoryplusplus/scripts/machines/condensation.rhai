import "voxel_eras/scripts/player" as player;

const REQUIRED_PROGRESS = game::TICK_RATE * 4;
const MAX_ENERGY = game::TICK_RATE / 2;

fn define(mod_info) {
	mod_info.add(TextureBuilder(
        "CondensationIcon:Factory++",
        "factoryplusplus/assets/textures/benderside.png",
    ));

	mod_info.add(
		VoxelBuilder(
			"CondensationOff:Factory++",
			"Condensation (Off)",
			"factoryplusplus/scripts/machines/condensation.rhai"
		).model(
			SolidVoxelModel(
			"voxel_eras/assets/textures/AlloyFurnaceTop.png",
			"factoryplusplus/assets/textures/benderside.png",
			"voxel_eras/assets/textures/AlloyFurnaceBottom.png"
		))
		.pipette("Condensation:Factory++")
		.break_rate(voxel::BREAK_RATE_MACHINE)
		.tag("Solid:VoxelEras")
		.does_break()
		.does_tick()
		.does_interact()
		.does_interacting()
		.does_insert()
		.does_extract()
		.does_action()
		.does_message()
	);

	mod_info.add(
		VoxelBuilder(
			"CondensationOn:Factory++",
			"Condensation (On)",
			"factoryplusplus/scripts/machines/condensation.rhai"
		).model(
			SolidVoxelModel(
			"voxel_eras/assets/textures/AlloyFurnaceTop.png",
			"factoryplusplus/assets/textures/benderonanim.png",
			"voxel_eras/assets/textures/AlloyFurnaceBottom.png"
		))
		.pipette("Condensation:Factory++")
		.break_rate(voxel::BREAK_RATE_MACHINE)
		.tag("Solid:VoxelEras")
		.does_break()
		.does_tick()
		.does_interact()
		.does_interacting()
		.does_insert()
		.does_extract()
		.does_action()
		.does_message()
	);

	mod_info.add(
		ConstructBuilder(
			"Condensation:Factory++",
			"Condensation machine",
			"With the power of clockwork! We will make Tubes!",
			"Machines",
			"CondensationIcon:Factory++",
			construct::ROT_NONE
		).cost(WeakItemStack("ClockworkCore:VoxelEras", 1))
		.cost(WeakItemStack("CarbonSteelTube:VoxelEras", 3))
		.cost(WeakItemStack("CarbonSteelGear:VoxelEras", 2))
		.variant(
			ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					WeakVoxelVariant("CondensationOff:Factory++", voxel::ROT_UP)
					.add_state("State:Inventory", metadata::Inventory(2))
					.add_state("State:ClockworkEnergy", metadata::U64(0))
					.add_state("State:Progress", metadata::U64(0))
				)
		).priority(9)
	);
	
	mod_info.add(
		RecipeBuilder(
			"WaterRecipe:Factory++",
			"Making a water block what can go wrong? :3",
			0,
			"WaterIcon:VoxelEras"
		).crafted_in("Condensation:Factory++")
		.with_output(WeakItemStack("Water:Factory++", 1))
	);
}

fn on_break(voxel, location, target, entity, game_state) {
	if location == target {
		let inventory = voxel.metadata.get_inventory();
		for slot in inventory {
			if slot == () {
				continue;
			}

			game_state.drop(slot, location);
		}
		
		game_state.drop(WeakItemStack("ClockworkCore:VoxelEras", 1), location);
		game_state.drop(WeakItemStack("CarbonSteelGear:VoxelEras", 2), location);
		game_state.drop(WeakItemStack("CarbonSteelTube:VoxelEras", 3), location);
	}

	event::ACCEPT
}

fn on_interact(voxel, location, entity, game_state) {
	entity.start_interacting(location);

	event::ACCEPT
}

fn on_extract(voxel, location, slot, items, direction, game_state) {

	event::ACCEPT
}

fn on_tick(voxel, location, game_state) {
	let metadata = voxel.metadata;

	let energy = metadata.get_u64("State:ClockworkEnergy");
	let progress = metadata.get_u64("State:Progress");
	let inventory = metadata.get_inventory();
	
	let recipe = game_state.find_possible_recipe("Condensation:Factory++", [inventory[0]]);

	if energy == 0 {
		if recipe != () {
			if progress > 0 {
				progress -= 1;
				metadata.set_u64("State:Progress", progress);
			} else if voxel.prefab.identifier == "CondensationOff:Factory++" {
				return event::ACCEPT;
			}
		} else if voxel.prefab.identifier == "CondensationOff:Factory++" {
			return event::ACCEPT;
		}
	}

	if energy > 0 {
		let was_running = false;
		if recipe != () {
			was_running = true;
			energy -= 1;
			metadata.set_u64("State:ClockworkEnergy", energy);

			progress += 1;

			// Craft
			if progress >= global::REQUIRED_PROGRESS {
				inventory[0].quantity -= recipe.inputs[0].quantity;

				metadata.set_inventory(inventory);
				progress = 0;
			}
		} else if progress > 0 {
			progress -= 1;
		}

		metadata.set_u64("State:Progress", progress);

		game_state.set_voxel(location,
			game_state.get_voxel_prefab(
				if was_running { 
					"CondensationOn:Factory++"
				} else {
					"CondensationOff:Factory++"
				})
				.get_variant(metadata));
	} else {
		game_state.set_voxel(location, 
			game_state
				.get_voxel_prefab("CondensationOff:Factory++")
				.get_variant(metadata));
	}

	event::ACCEPT
}

fn on_interacting(voxel, location, entity, egui, client_state) {
	let game_state = client_state.game_state;
	egui.window(
		"CondensationInteracting",
		|ui| {
			client_state.heading(
				ui,
				"CondensationIcon:Factory++",
				"Condensation machine",
				"Condensation!"
			);

			condensation_ui(ui, location, voxel, entity, client_state);

			player::inventory_ui(
				ui,
				location,
				voxel,
				entity,
				client_state
			);
		}
	);

	let selected_slot = entity.metadata.get_slot_ref("State:SelectedSlot");
	if selected_slot != () {
		client_state.render_grabbed_slot(
			egui,
			selected_slot.using_primary, 
			(if selected_slot.inventory_index == 0 {
				entity.metadata.get_inventory()
			} else {
				game_state.get_voxel(location).metadata.get_inventory()
			})[selected_slot.slot_index]
		);
	}

	event::ACCEPT
}

fn on_message(voxel, location, type, message, game_state) {
	if type != "CLOCKWORK" { return event::CANCEL; }
	let energy = message;

	let stored_energy = voxel.metadata.get_u64("State:ClockworkEnergy");
	if stored_energy + energy > global::MAX_ENERGY {
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

private fn condensation_ui(ui, location, voxel, entity, client_state) {
	ui.vertical_centered_justified(|ui| {
		ui.set_width(150.);

		ui.columns(3, |ui| {
			condensation_interactables(ui, location, voxel, entity, client_state);
		});
	});
}

private fn condensation_interactables(ui, location, voxel, entity, client_state) {
	const FIRE_FRAMES = 8;
	const COOK_FRAMES = 15;

	let metadata = voxel.metadata;
	let inventory = metadata.get_inventory();
	let selected_slot = entity.metadata.get_slot_ref("State:SelectedSlot");

	let cook_anim = ((metadata.get_u64("State:Progress") * COOK_FRAMES) / global::REQUIRED_PROGRESS).min(COOK_FRAMES - 1);

	ui[0].vertical(|ui| {
		let slot_interact = client_state.inventory_slot(
			ui,
			inventory[0],
			if selected_slot != () {
				selected_slot.inventory_index == 0 && selected_slot.slot_index == 0
			} else {
				false
			},
			"PipeOutputIcon:Factory++",
			"The output of the Condensation machine.\nCan be taken from all sides."
		);

		if slot_interact.clicked_down() || slot_interact.secondary_clicked() {
			let metadata = MetaData();
			metadata.set_slot_ref("State:ClickedSlot", metadata::SlotRef(
				1,
				1,
				slot_interact.clicked_down(),
				slot_interact.shifting(),
			));
			client_state.action(location, "Transfer", metadata);
		}
	});
}

fn on_action(voxel, location, player, type, message, game_state) {
	if type != "Transfer" {
		return event::ACCEPT;
	}

	let player = game_state.validate_player_interact(player, location);
	if player == () { return event::ACCEPT; }

	let clicked_slot = message.get_slot_ref("State:ClickedSlot");
	if clicked_slot != () {
		game_state.voxel_entity_transfer(
			clicked_slot,
			location,
			voxel,
			player
		);
	}

	event::ACCEPT
} 