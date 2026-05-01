extends Control

var answers: Array = []
var valid_words: Array = [] 

const MAX_GUESSES = 6
const WORD_LENGTH = 5

@onready var board = $Board
@onready var game_over_panel = $GameOverPanel
@onready var title_label = $GameOverPanel/TitleLabel
@onready var word_label = $GameOverPanel/WordLabel

# --- GÜNCELLENEN: YENİ BUTON YOLLARI ---
@onready var restart_button = $GameOverPanel/ButtonContainer/RestartButton
@onready var archive_button = $GameOverPanel/ButtonContainer/ArchiveButton

@onready var keyboard_container = $KeyboardContainer
@onready var stats_label = $GameOverPanel/StatsLabel

var letter_box_scene = preload("res://scenes/letter_box.tscn")
var grid_boxes: Array = []
var current_row: int = 0
var current_col: int = 0
var current_guess: String = ""
var target_word: String = ""
var board_start_pos: Vector2 
var shake_tween: Tween

var keyboard_layout = [
	["E", "R", "T", "Y", "U", "I", "O", "P", "Ğ", "Ü"],
	["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ş", "İ"],
	["ENTER", "Z", "C", "V", "B", "N", "M", "Ö", "Ç", "SİL"]
]
var key_buttons: Dictionary = {} 
var is_animating: bool = false 

var level_day_index: int = -1

func _ready():
	load_words()
	create_board()
	create_keyboard() 
	game_over_panel.hide()
	
	if not restart_button.pressed.is_connected(restart_game):
		restart_button.pressed.connect(restart_game)
		
	# --- YENİ EKLENEN: ARŞİVE DÖN BUTONU BAĞLANTISI ---
	if not archive_button.pressed.is_connected(return_to_archive):
		archive_button.pressed.connect(return_to_archive)

func turkish_to_upper(text: String) -> String:
	var result = ""
	for i in range(text.length()):
		var c = text[i]
		if c == "i": result += "İ"
		elif c == "ı": result += "I"
		elif c == "ç": result += "Ç"
		elif c == "ş": result += "Ş"
		elif c == "ğ": result += "Ğ"
		elif c == "ö": result += "Ö"
		elif c == "ü": result += "Ü"
		else: result += c.to_upper()
	return result

func load_words():
	var answers_path = "res://data/answers.json"
	if FileAccess.file_exists(answers_path):
		var json_string = FileAccess.get_file_as_string(answers_path)
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data != null:
			for word in parsed_data:
				var upper_word = turkish_to_upper(word)
				answers.append(upper_word)
				valid_words.append(upper_word) 
			
			if SaveManager.selected_level != -1:
				level_day_index = SaveManager.selected_level
			else:
				var unix_time = Time.get_unix_time_from_system()
				var tz_bias = Time.get_time_zone_from_system()["bias"] * 60
				level_day_index = int((unix_time + tz_bias) / 86400.0)
			
			target_word = answers[level_day_index % answers.size()]
			print("OYUN BAŞLADI - Gün: ", level_day_index, " | Kelime: ", target_word)
	
	var guesses_path = "res://data/guesses.json"
	if FileAccess.file_exists(guesses_path):
		var json_string = FileAccess.get_file_as_string(guesses_path)
		var parsed_data = JSON.parse_string(json_string)
		if parsed_data != null:
			for word in parsed_data:
				valid_words.append(turkish_to_upper(word))

func create_board():
	for i in range(MAX_GUESSES * WORD_LENGTH):
		var box = letter_box_scene.instantiate()
		board.add_child(box)
		box.text = ""
		box.pivot_offset = Vector2(40, 40) 
		grid_boxes.append(box)

func create_keyboard():
	for row in keyboard_layout:
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 6)
		keyboard_container.add_child(hbox)
		
		for key in row:
			var btn = Button.new()
			btn.text = key
			btn.focus_mode = Control.FOCUS_NONE 
			btn.add_theme_font_size_override("font_size", 20)
			
			if key == "ENTER" or key == "SİL":
				btn.custom_minimum_size = Vector2(70, 50)
			else:
				btn.custom_minimum_size = Vector2(40, 50)
				key_buttons[key] = btn 
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.5, 0.5, 0.53) 
			style.corner_radius_top_left = 5
			style.corner_radius_top_right = 5
			style.corner_radius_bottom_left = 5
			style.corner_radius_bottom_right = 5
			btn.add_theme_stylebox_override("normal", style)
			
			btn.pressed.connect(func(): _on_virtual_key_pressed(key))
			hbox.add_child(btn)

func _on_virtual_key_pressed(key: String):
	if game_over_panel.visible or current_row >= MAX_GUESSES or is_animating: return
	
	if key == "ENTER":
		submit_guess()
	elif key == "SİL":
		remove_letter()
	else:
		add_letter(key)

func _unhandled_input(event):
	if game_over_panel.visible or current_row >= MAX_GUESSES or is_animating: return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			remove_letter()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			submit_guess()
		elif event.unicode != 0: 
			var typed_char = turkish_to_upper(char(event.unicode))
			var turkish_alphabet = "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ"
			if turkish_alphabet.find(typed_char) != -1:
				add_letter(typed_char)

func add_letter(letter: String):
	if current_col < WORD_LENGTH:
		var box = grid_boxes[current_row * WORD_LENGTH + current_col]
		current_guess += letter
		update_grid()
		var pop_tween = create_tween()
		pop_tween.tween_property(box, "scale", Vector2(1.1, 1.1), 0.15)
		pop_tween.tween_property(box, "scale", Vector2(1.0, 1.0), 0.15)
		current_col += 1

func remove_letter():
	if current_col > 0:
		current_col -= 1
		current_guess = current_guess.substr(0, current_guess.length() - 1)
		update_grid()

func update_grid():
	var start_index = current_row * WORD_LENGTH
	for i in range(WORD_LENGTH):
		var box = grid_boxes[start_index + i]
		if i < current_guess.length():
			box.text = current_guess[i]
		else:
			box.text = ""

func shake_error(should_clear: bool):
	if not shake_tween or not shake_tween.is_valid():
		board_start_pos = board.position
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
		board.position.x = board_start_pos.x
	shake_tween = create_tween()
	var offset = 10 
	var time = 0.05 
	shake_tween.tween_property(board, "position:x", board_start_pos.x - offset, time)
	shake_tween.tween_property(board, "position:x", board_start_pos.x + offset, time)
	shake_tween.tween_property(board, "position:x", board_start_pos.x - offset, time)
	shake_tween.tween_property(board, "position:x", board_start_pos.x + offset, time)
	shake_tween.tween_property(board, "position:x", board_start_pos.x, time)
	if should_clear:
		shake_tween.tween_callback(func():
			current_col = 0
			current_guess = ""
			update_grid()
		)

func submit_guess():
	if current_guess.length() != WORD_LENGTH:
		shake_error(false)
		return
	if not valid_words.has(current_guess):
		shake_error(true) 
		return
	check_guess() 

func check_guess():
	is_animating = true 
	var start_index = current_row * WORD_LENGTH
	var remaining_letters = []
	for i in range(WORD_LENGTH):
		remaining_letters.append(target_word[i])
	var box_colors = []
	box_colors.resize(WORD_LENGTH)
	box_colors.fill(Color(0.23, 0.23, 0.24))
	for i in range(WORD_LENGTH):
		if current_guess[i] == target_word[i]:
			box_colors[i] = Color(0.33, 0.55, 0.35)
			remaining_letters[i] = "."
	for i in range(WORD_LENGTH):
		if box_colors[i] == Color(0.33, 0.55, 0.35):
			continue
		var letter = current_guess[i]
		var found_index = remaining_letters.find(letter)
		if found_index != -1:
			box_colors[i] = Color(0.71, 0.61, 0.23)
			remaining_letters[found_index] = "."
	var tween = create_tween()
	tween.set_parallel(true) 
	var final_time = 0.0
	for i in range(WORD_LENGTH):
		var box = grid_boxes[start_index + i]
		var letter = current_guess[i]
		var final_color = box_colors[i]
		var delay = i * 0.2 
		tween.tween_property(box, "scale:y", 0.0, 0.15).set_delay(delay)
		tween.tween_callback(apply_color.bind(box, final_color, letter)).set_delay(delay + 0.15)
		tween.tween_property(box, "scale:y", 1.0, 0.15).set_delay(delay + 0.15)
		final_time = delay + 0.3
	tween.tween_callback(finish_submit).set_delay(final_time)

func apply_color(box: Control, new_color: Color, letter: String):
	var style = StyleBoxFlat.new()
	style.bg_color = new_color
	box.add_theme_stylebox_override("normal", style)
	var btn = key_buttons[letter]
	var btn_style = btn.get_theme_stylebox("normal") as StyleBoxFlat
	var current_color = btn_style.bg_color
	if current_color == Color(0.33, 0.55, 0.35): return
	if current_color == Color(0.71, 0.61, 0.23) and new_color != Color(0.33, 0.55, 0.35): return
	btn_style.bg_color = new_color

func finish_submit():
	if current_guess == target_word:
		show_game_over(true)
		is_animating = false
		return
	current_row += 1
	current_col = 0
	current_guess = ""
	if current_row >= MAX_GUESSES:
		show_game_over(false)
	is_animating = false 

func show_game_over(has_won: bool):
	SaveManager.stats["games_played"] += 1
	
	var day_key = str(level_day_index)
	
	if has_won:
		SaveManager.stats["games_won"] += 1
		SaveManager.stats["current_streak"] += 1
		if SaveManager.stats["current_streak"] > SaveManager.stats["max_streak"]:
			SaveManager.stats["max_streak"] = SaveManager.stats["current_streak"]
		SaveManager.stats["guess_distribution"][current_row] += 1
		
		SaveManager.stats["history"][day_key] = "WIN"
		
		title_label.text = "TEBRİKLER!"
		title_label.modulate = Color(0.33, 0.55, 0.35)
	else:
		SaveManager.stats["current_streak"] = 0 
		
		if not SaveManager.stats["history"].has(day_key):
			SaveManager.stats["history"][day_key] = "LOSS"
			
		title_label.text = "BİLEMEDİNİZ!"
		title_label.modulate = Color(0.8, 0.2, 0.2)
	
	SaveManager.save_game()
	
	var played = SaveManager.stats["games_played"]
	var won = SaveManager.stats["games_won"]
	var win_rate = 0
	if played > 0: win_rate = round((float(won) / float(played)) * 100)
	
	word_label.text = "Kelime: " + target_word
	stats_label.text = "Oynanan: %d   |   Kazanma: %%%d\nGüncel Seri: %d   |   En İyi Seri: %d" % [played, win_rate, SaveManager.stats["current_streak"], SaveManager.stats["max_streak"]]
	game_over_panel.show()

func restart_game():
	get_tree().reload_current_scene()

# --- YENİ EKLENEN: ARŞİVE DÖN FONKSİYONU ---
func return_to_archive():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
