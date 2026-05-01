extends Node

const SAVE_DIR = "user://"

func save_game(slot: int) -> void:
	var data = {
		"coins": GameState.coins,
		"mood": GameState.mood,
		"greeted": GameState.greeted,
		"quiz_pack": GameState.quiz_pack,
		"collectibles": GameState.collectibles,
		"inventory": GameState.inventory,
		"pose_tier": GameState.pose_tier,
		"discovered_poses": GameState.discovered_poses,
		"questions_seen": GameState.questions_seen,
		"streak": GameState.streak,
		"intro_played": GameState.intro_played
	}
	
	var path = SAVE_DIR + "save_%d.json" % slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t")) # Menggunakan indentasi agar mudah dibaca
		file.close()

func load_game(slot: int) -> bool:
	var path = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(path):
		return false
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
		
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null:
		return false
	
	GameState.coins            = data.get("coins", 0)
	GameState.mood             = data.get("mood", {})
	GameState.greeted          = data.get("greeted", {})
	GameState.quiz_pack        = data.get("quiz_pack", {})
	GameState.collectibles     = data.get("collectibles", {})
	GameState.inventory        = data.get("inventory", {"mochi": {}, "koko": {}, "bao": {}})
	GameState.pose_tier        = data.get("pose_tier", {})
	GameState.discovered_poses = data.get("discovered_poses", {})
	GameState.questions_seen   = data.get("questions_seen", {})
	GameState.streak           = data.get("streak", 0)
	GameState.intro_played     = data.get("intro_played", true)
	
	return true

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "save_%d.json" % slot)
