extends Node

var coins: int = 100
var mood: Dictionary = { "mochi": 0, "koko": 0, "bao": 0 }
var mood_accumulated: int = 0
var greeted: Dictionary = { "mochi": false, "koko": false, "bao": false }
var quiz_pack: Dictionary = { "mochi": 0, "koko": 0, "bao": 0 }
var collectibles: Dictionary = { "mochi": [], "koko": [], "bao": [] }
var inventory: Dictionary = { "mochi": {}, "koko": {}, "bao": {} }
var pose_tier: Dictionary = { "mochi": 1, "koko": 1, "bao": 1 }
var discovered_poses: Dictionary = { "mochi": [], "koko": [], "bao": [] }
var questions_seen: Dictionary = { "mochi": [], "koko": [], "bao": [] }
var streak: int = 0
