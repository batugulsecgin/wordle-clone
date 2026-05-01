extends Control

@onready var grid = $VBoxContainer/ScrollContainer/GridContainer

const LAUNCH_DAY_INDEX = 20550 

func _ready():
	generate_levels()

func generate_levels():
	var unix_time = Time.get_unix_time_from_system()
	var tz_bias = Time.get_time_zone_from_system()["bias"] * 60
	var current_day_index = int((unix_time + tz_bias) / 86400.0)
	
	for day in range(LAUNCH_DAY_INDEX, current_day_index + 1):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.focus_mode = Control.FOCUS_NONE
		
		var display_num = day - LAUNCH_DAY_INDEX + 1 
		var display_text = str(display_num)
		
		var day_key = str(day)
		if SaveManager.stats["history"].has(day_key):
			if SaveManager.stats["history"][day_key] == "WIN":
				display_text += "\n✅"
			elif SaveManager.stats["history"][day_key] == "LOSS":
				display_text += "\n❌"
				
		btn.text = display_text
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.23)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", style)
		
		btn.pressed.connect(func(): _on_level_selected(day))
		grid.add_child(btn)

func _on_level_selected(day_index: int):
	SaveManager.selected_level = day_index
	# Artık doğrudan oyuna değil, önce Yükleme Ekranına gidiyoruz
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
