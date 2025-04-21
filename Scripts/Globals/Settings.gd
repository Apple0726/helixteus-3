extends Node

# audio
var master_volume:float = 0.0
var music_volume:float = 0.0
var SFX_volume:float = 0.0
var pitch_affected:bool = false

# graphics
var vsync:bool = true
var fullscreen:bool = false
var max_fps:int = 60
var static_space_LOD:int = 12
var dynamic_space_LOD:int = 8
var screen_shake:bool = true
var enable_shaders:bool = true

# game
var enable_autosave:bool = true
var autosave_light:bool = true
var autosave_interval:int = 10
var autosell:bool = true
var auto_switch_buy_sell:bool = false
enum {
	ENEMY_AI_DIFFICULTY_EASY,
	ENEMY_AI_DIFFICULTY_NORMAL,
	ENEMY_AI_DIFFICULTY_HARD,
}
var enemy_AI_difficulty:int = ENEMY_AI_DIFFICULTY_NORMAL

# interface
var language:String = "en"
var notation:String = "SI"
var cave_gen_info:bool = false

# misc
var discord = true
var op_cursor:bool = false
