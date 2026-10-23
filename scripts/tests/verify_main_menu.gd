extends SceneTree

func _init() -> void:
	call_deferred("_test")

func _test() -> void:
	print("--- TESTING REFACTORED MAIN MENU SCENE ---")
	var scene_path: String = "res://scenes/ui/main_menu.tscn"
	assert(FileAccess.file_exists(scene_path), "main_menu.tscn does not exist")
	
	var packed: PackedScene = load(scene_path)
	assert(packed != null, "Failed to load main_menu.tscn")
	
	var menu: MainMenu = packed.instantiate() as MainMenu
	assert(menu != null, "Failed to cast to MainMenu")
	root.add_child(menu)
	
	# Verify essential nodes
	assert(menu.play_button != null, "PlayButton missing")
	assert(menu.settings_button != null, "SettingsButton missing")
	assert(menu.about_button != null, "AboutButton missing")
	assert(menu.quit_button != null, "QuitButton missing")
	assert(menu.camera_3d != null, "Camera3D missing")
	assert(menu.diorama_root != null, "DioramaRoot missing")
	assert(menu.lobby_modal != null, "LobbyModal missing")
	assert(menu.settings_modal != null, "SettingsModal missing")
	assert(menu.about_modal != null, "AboutModal missing")
	assert(menu.close_lobby_btn != null, "CloseLobbyBtn missing")
	assert(menu.close_settings_btn != null, "CloseSettingsBtn missing")
	assert(menu.close_about_btn != null, "CloseAboutBtn missing")
	
	print("[OK] All essential UI and 3D nodes found and bound.")
	
	# Simulate process for camera and commando animation
	menu._process(0.016)
	menu._process(0.016)
	print("[OK] _process() executed cleanly.")
	
	# Test opening/closing modals
	menu._open_modal(menu.settings_modal)
	assert(menu.settings_modal.visible, "Settings modal should be visible")
	menu._close_modal(menu.settings_modal)
	
	menu._open_modal(menu.lobby_modal)
	assert(menu.lobby_modal.visible, "Lobby modal should be visible")
	menu._close_modal(menu.lobby_modal)
	
	menu._open_modal(menu.about_modal)
	assert(menu.about_modal.visible, "About modal should be visible")
	menu._close_modal(menu.about_modal)
	
	print("[ALL CHECKS PASSED] MainMenu refactor completely verified in Godot!")
	menu.queue_free()
	quit(0)
