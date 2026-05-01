extends Control

@onready var container = $VBoxContainer

func _ready():
	# 1. Başlangıçta yazıları tamamen şeffaf (görünmez) yapıyoruz
	container.modulate.a = 0.0
	
	var tween = create_tween()
	
	# 2. Yazılar 0.5 saniyede yavaşça belirecek (Fade In)
	tween.tween_property(container, "modulate:a", 1.0, 0.5)
	
	# 3. Ekranda 0.8 saniye boyunca tam görünür halde bekleyecek
	tween.tween_interval(0.8)
	
	# 4. Yazılar 0.5 saniyede tekrar yavaşça şeffaflaşıp kaybolacak (Fade Out)
	tween.tween_property(container, "modulate:a", 0.0, 0.5)
	
	# 5. Animasyon tamamen bitince ana oyun sahnesini yükle komutu veriyoruz
	tween.tween_callback(go_to_game)

func go_to_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
