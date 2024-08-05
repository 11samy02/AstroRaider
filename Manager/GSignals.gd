extends Node

#Enviroment
signal ENV_destroy_tile

#Hitbox
signal HIT_take_Damage
signal HIT_take_heal

#Perks
signal PERK_event_collect_crystal
signal PERK_reset_perks_from_player_id

## first value -> strength, seconst value -> duration
signal CAM_shake_effect


#Enemy
signal ENE_killed_by

#Waves
signal WAV_wave_endet
