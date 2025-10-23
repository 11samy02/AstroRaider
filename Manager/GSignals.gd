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
signal PERK_barrier_shield_destroyed
signal PERK_Aim_bot_activate
signal PERK_Extra_health
signal PERK_show_items_behind_wall
signal Perk_add_vision_behind_wall

## first value -> strength, seconst value -> duration
signal CAM_shake_effect


#Enemy
signal ENE_killed_by

#Waves
signal WAV_wave_endet

#Player
signal PLA_is_shooting
signal PLA_open_skill_tree
signal PLA_collects_crystal

#UI
signal UI_reset_skill_tree
signal UI_mission_finished
signal UI_selected_blueprint


#Buildings
signal BUI_generator_gets_hit
