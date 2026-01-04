extends Control

func _on_start_button_pressed():
	SceneManager.Set_Scene(SceneManager.MAIN_SCENE)
	queue_free()

func _on_quit_button_pressed():
	get_tree().quit()
