extends Node

#Enviroment
signal ENV_destroy_tile
signal ENV_check_detection_tile
signal ENV_remove_tile_from_wall
signal ENV_reset_timer_for_wall_notification

#Hitbox
signal HIT_take_Damage
signal HIT_take_heal

#Perks
signal PERK_event_collect_crystal
signal PERK_reset_perks_from_controller_id
signal PERK_Aim_bot_activate
signal PERK_Extra_health
signal PERK_show_items_behind_wall
signal PERK_add_vision_behind_wall
signal PERK_barrier_shield_destroyed
signal PERK_barrier_shield_changed(player: Player, current_shield: int, max_shield: int)
signal PERK_energy_overload_stopped
signal PERK_magnetic_pull_changed

## first value -> strength, seconst value -> duration
signal CAM_shake_effect


#Enemy
signal ENE_killed_by

#Waves
signal WAV_wave_endet

#Player
signal PLA_is_shooting
signal PLA_collects_crystal

#UI
signal UI_mission_finished
signal UI_selected_blueprint
signal UI_show_only_PerkSelector


#Buildings
signal BUI_generator_gets_hit
signal BUI_generator_is_placed(generator: CrystalGenerator)
signal BUI_BUILDING_select_building
signal BUI_allow_to_place
signal BUI_hide_resource_cost

#Tutorial
signal TUT_tiles_destroyed(count: int)
signal TUT_build_mode_changed(player: Player, is_build_mode: bool)
signal TUT_building_placed(player: Player, building: Building, blueprint_key)
signal TUT_building_salvaged(player: Player, blueprint_key)
