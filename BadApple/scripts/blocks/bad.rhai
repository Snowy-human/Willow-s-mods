import "voxel_eras/scripts/player" as player;

const REQUIRED_PROGRESS = game::TICK_RATE * 4;
const MAX_ENERGY = game::TICK_RATE / 2;

fn define(mod_info) {
	mod_info.add(TextureBuilder(
        "BadIcon:BadApple",
        "BadApple/assets/items/bad.png",
    ));

	mod_info.add(
		VoxelBuilder(
			"BadOff:BadApple",
			"Bad (Off)",
			"BadApple/scripts/blocks/bad.rhai"
		).model(
			SolidVoxelModel("BadApple/assets/items/bad.png"))
		.pipette("Bad:BadApple")
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
			"BadOn:BadApple",
			"Bad (On)",
			"BadApple/scripts/blocks/bad.rhai"
		).model(
			SolidVoxelModel("BadApple/assets/textures/bad_appleanim.png"))
		.pipette("Bad:BadApple")
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
			"Bad:BadApple",
			"Bad Apple",
			"Oh god what am I doing?",
			"Machines",
			"BadIcon:BadApple",
			construct::ROT_NONE
		).cost(WeakItemStack("Dirt:VoxelEras", 1))
		.variant(
			ConstructVariantBuilder(voxel::ROT_UP)
				.place(
					0, 0, 0,
					WeakVoxelVariant("BadOff:BadApple", voxel::ROT_UP)
					.add_state("State:Inventory", metadata::Inventory(2))
					.add_state("State:ClockworkEnergy", metadata::U64(0))
					.add_state("State:Progress", metadata::U64(0))
				)
		).priority(9)
	);
	
	mod_info.add(
		RecipeBuilder(
			"BadBad:BadApple",
			"inf pwer",
			0,
			"BadIcon:BadApple"
		).crafted_in("Bad:BadApple")
		.with_input(WeakItemStack("Dirt:VoxelEras", 1))
		.with_output(WeakItemStack("Dirt:VoxelEras", 1))
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
		
		game_state.drop(WeakItemStack("Dirt:VoxelEras", 1), location);
	}

	event::ACCEPT
}

fn on_interact(voxel, location, entity, game_state) {
	entity.start_interacting(location);

	event::ACCEPT
}

fn on_insert(voxel, location, slot, items, direction, game_state) {
	if slot == 0 {
		event::ACCEPT
	} else {
		event::CANCEL
	}
}

fn on_extract(voxel, location, slot, items, direction, game_state) {
	if direction != () && slot == 0 {
		return event::CANCEL;
	}

	event::ACCEPT
}

fn on_tick(voxel, location, game_state) {
	let metadata = voxel.metadata;

	let energy = metadata.get_u64("State:ClockworkEnergy");
	let progress = metadata.get_u64("State:Progress");
	let inventory = metadata.get_inventory();
	
	let recipe = game_state.find_possible_recipe("Bad:BadApple", [inventory[0]], [inventory[1]]);

	if energy == 0 {
		if recipe != () {
			if progress > 0 {
				progress -= 1;
				metadata.set_u64("State:Progress", progress);
			} else if voxel.prefab.identifier == "BadOff:BadApple" {
				return event::ACCEPT;
			}
		} else if voxel.prefab.identifier == "BadOff:BadApple" {
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

				if inventory[1] == () {
					inventory[1] = recipe.outputs[0];
				} else {
					inventory[1].quantity += recipe.outputs[0].quantity;
				}

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
					"BadOn:BadApple"
				} else {
					"BadOn:BadApple"
				})
				.get_variant(metadata));
	} else {
		game_state.set_voxel(location, 
			game_state
				.get_voxel_prefab("BadOff:BadApple")
				.get_variant(metadata));
	}

	event::ACCEPT
}

fn on_interacting(voxel, location, entity, egui, client_state) {
	let game_state = client_state.game_state;
	egui.window(
		"BadInteracting",
		|ui| {
			client_state.heading(
				ui,
				"BadIcon:Stones",
				"Bad",
				"Don't."
			);

			grinder_ui(ui, location, voxel, entity, client_state);

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

private fn grinder_ui(ui, location, voxel, entity, client_state) {
	ui.vertical_centered_justified(|ui| {
		ui.set_width(150.);

		ui.columns(3, |ui| {
			grinder_interactables(ui, location, voxel, entity, client_state);
		});
	});
}

private fn grinder_interactables(ui, location, voxel, entity, client_state) {
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
				selected_slot.inventory_index == 1 && selected_slot.slot_index == 0
			} else {
				false
			},
			"FurnaceOutputIcon:VoxelEras",
			"Please don't"
		);

		if slot_interact.clicked() || slot_interact.secondary_clicked() {
			let metadata = MetaData();
			metadata.set_slot_ref("State:ClickedSlot", metadata::SlotRef(
				1,
				0,
				slot_interact.clicked(),
			));
			client_state.action(location, "Transfer", metadata);
		}
	});
	ui[1].vertical(|ui| {
		client_state.draw_icon(
			ui,
			"CookingArrow" + cook_anim + "Icon:VoxelEras",
			Vec2(50., 50.)
		);
	});
	ui[2].vertical(|ui| {
		let slot_interact = client_state.inventory_slot(
			ui,
			inventory[1],
			if selected_slot != () {
				selected_slot.inventory_index == 1 && selected_slot.slot_index == 1
			} else {
				false
			},
			"PlateOutputIcon:Factory++",
			"STOP!"
		);

		if slot_interact.clicked() || slot_interact.secondary_clicked() {
			let metadata = MetaData();
			metadata.set_slot_ref("State:ClickedSlot", metadata::SlotRef(
				1,
				1,
				slot_interact.clicked(),
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