extends Node
## Root: switches between the title screen and the game.

var current: Node


func _ready() -> void:
	get_window().theme = UiTheme.build()
	_show_menu()


func _show_menu() -> void:
	_clear()
	var m := MainMenu.new()
	m.start_game.connect(_start)
	add_child(m)
	current = m


func _start(new_game: bool) -> void:
	if new_game or not Game.load_game():
		Game.new_game()
	_clear()
	var g := GameScreen.new()
	g.quit_to_menu.connect(_show_menu)
	add_child(g)
	current = g


func _clear() -> void:
	if current:
		current.queue_free()
		current = null
