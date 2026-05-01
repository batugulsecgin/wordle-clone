extends Node

const SAVE_PATH = "user://wordle_save.json"

var selected_level: int = -1

var stats: Dictionary = {
	"games_played": 0,
	"games_won": 0,
	"current_streak": 0,
	"max_streak": 0,
	"guess_distribution": [0, 0, 0, 0, 0, 0],
	"history": {}
}

func _ready():
	load_game()

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(stats)
		file.store_string(json_string)
		file.close()
		print("Oyun kaydedildi: ", stats)
	else:
		print("Kayıt dosyası oluşturulamadı!")

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var parsed_data = JSON.parse_string(json_string)
			if parsed_data != null and typeof(parsed_data) == TYPE_DICTIONARY:
				for key in parsed_data.keys():
					if stats.has(key):
						stats[key] = parsed_data[key]
				print("Kayıt dosyası yüklendi: ", stats)
