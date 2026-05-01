extends CanvasLayer

# unlock_at_mood : total mood_accumulated global sebelum item muncul di shop
# requires       : id toy yang harus dimiliki per kucing (stepping stone)
# unlocks_food   : food id yang jadi tersedia setelah toy ini dibeli
const TOYS: Array[Dictionary] = [
	{
		"id": "yarn_ball", "label": "Yarn Ball", "price": 10,
		"mood_boost": 8, "unlocks_tier": 2,
		"unlocks_food": ["fancy_fish", "treat_bag"],
		"detail": "Tier 2: Fancy Fish, Treat Bag",
		"unlock_at_mood": 0
	},
	{
		"id": "mouse_toy", "label": "Mouse Toy", "price": 25,
		"mood_boost": 15, "unlocks_tier": 0,
		"unlocks_food": [],
		"detail": "Bikin Meowsters hepi :D",
		"unlock_at_mood": 50
	},
	{
		"id": "feather_wand", "label": "Feather Wand", "price": 15,
		"mood_boost": 6, "unlocks_tier": 3,
		"unlocks_food": ["durian", "catnip"],
		"detail": "Tier 3: Durian, Catnip",
		"unlock_at_mood": 100,
		"requires": "mouse_toy"
	},
	{
		"id": "cozy_blanket", "label": "Cozy Blanket", "price": 30,
		"mood_boost": 12, "unlocks_tier": 0,
		"unlocks_food": [],
		"detail": "Biar meowsters tidurnya nyaman",
		"unlock_at_mood": 250
	},
	{
		"id": "cat_tower", "label": "Cat Tower", "price": 35,
		"mood_boost": 12, "unlocks_tier": 4,
		"unlocks_food": ["warm_milk", "laser_pointer"],
		"detail": "Tier 4: Warm Milk, Laser Pointer",
		"unlock_at_mood": 500,
		"requires": "cozy_blanket"
	},
]

# requires_toy: toy yang harus dimiliki kucing agar bisa membeli food ini
# mood_boost sebagai Array [min, max] = random (mystery bag)
const FOOD: Array[Dictionary] = [
	{
		"id": "kibble", "label": "Kibble", "price": 10,
		"mood_boost": 8, "pose_triggered": "loaf yes",
		"flavour": "Woohooo!", "consumable": true,
		"requires_toy": ""
	},
	{
		"id": "fancy_fish", "label": "Fancy Fish", "price": 25,
		"mood_boost": 15, "pose_triggered": "loaf lick",
		"flavour": "Yum, what a delicacy!!", "consumable": true,
		"requires_toy": "yarn_ball"
	},
	{
		"id": "treat_bag", "label": "Treat Bag", "price": 15,
		"mood_boost": 6, "pose_triggered": "sit lick",
		"flavour": "I love it :3", "consumable": true,
		"requires_toy": "yarn_ball"
	},
	{
		"id": "durian", "label": "Durian", "price": 30,
		"mood_boost": -12, "pose_triggered": "scared",
		"flavour": "TF is this.", "consumable": true,
		"requires_toy": "feather_wand"
	},
	{
		"id": "catnip", "label": "Catnip", "price": 35,
		"mood_boost": 12, "pose_triggered": "standup lick",
		"flavour": "Oh.. my.. good...", "consumable": true,
		"requires_toy": "feather_wand"
	},
	{
		"id": "warm_milk", "label": "Warm Milk", "price": 40,
		"mood_boost": 15, "pose_triggered": "donut sleep",
		"flavour": "Zzzz...", "consumable": true,
		"requires_toy": "cat_tower"
	},
	{
		"id": "laser_pointer", "label": "Laser Pointer", "price": 80,
		"mood_boost": 20, "pose_triggered": "sit yawn",
		"flavour": "So.. tired...", "consumable": true,
		"requires_toy": "cat_tower"
	},
	{
		"id": "mystery_bag", "label": "Mystery Bag", "price": 35,
		"mood_boost": [8, 18], "pose_triggered": "",
		"flavour": "Could be anything.", "consumable": true,
		"requires_toy": ""
	},
]

const CAT_KEYS: Array = ["mochi", "koko", "bao"]
const CAT_LABELS: Dictionary = {"mochi": "Mochi", "koko": "Koko", "bao": "Bao"}

@onready var _coins_label: Label            = %CoinsLabel
@onready var _feedback_label: Label         = %FeedbackLabel
@onready var _toys_container: VBoxContainer = %ToysContainer
@onready var _food_container: VBoxContainer = %FoodContainer
@onready var _tab_toys: Button              = %TabToys
@onready var _tab_food: Button              = %TabFood

var _overlay: ColorRect
var _cat_buttons: Dictionary = {}
var _pending_item: Dictionary = {}
var _buy_buttons: Array = []

func _ready() -> void:
	visible = false
	_tab_toys.pressed.connect(_show_tab.bind("toys"))
	_tab_food.pressed.connect(_show_tab.bind("food"))
	_build_list(TOYS, _toys_container)
	_build_list(FOOD, _food_container)
	_show_tab("toys")
	_build_cat_popup()

func open() -> void:
	visible = true
	_refresh_coins()
	_feedback_label.text = ""
	_refresh_all_buttons()

func close() -> void:
	visible = false
	_close_cat_popup()

func _show_tab(tab: String) -> void:
	_toys_container.visible = (tab == "toys")
	_food_container.visible = (tab == "food")
	_tab_toys.disabled = (tab == "toys")
	_tab_food.disabled = (tab == "food")

func _mood_str(boost) -> String:
	if typeof(boost) == TYPE_ARRAY:
		return "+%d~%d mood" % [boost[0], boost[1]]
	elif int(boost) < 0:
		return "%d mood" % boost
	else:
		return "+%d mood" % boost

func _build_list(items: Array, container: VBoxContainer) -> void:
	for item in items:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(card)

		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 8)
		card.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		margin.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = item["label"]
		info.add_child(name_lbl)

		var detail_lbl := Label.new()
		detail_lbl.text = item.get("detail", item.get("flavour", ""))
		detail_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(detail_lbl)

		var unlock_mood: int = item.get("unlock_at_mood", 0)
		if not item.get("consumable", false) and unlock_mood > 0:
			var mood_req_lbl := Label.new()
			mood_req_lbl.text = "Unlocks at %d total mood" % unlock_mood
			mood_req_lbl.add_theme_font_size_override("font_size", 10)
			info.add_child(mood_req_lbl)

		var right_col := VBoxContainer.new()
		right_col.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(right_col)

		var price_lbl := Label.new()
		price_lbl.text = "%d coins" % item["price"]
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_col.add_child(price_lbl)

		var mood_lbl := Label.new()
		mood_lbl.text = _mood_str(item["mood_boost"])
		mood_lbl.add_theme_font_size_override("font_size", 11)
		mood_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right_col.add_child(mood_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Beli"
		buy_btn.custom_minimum_size.x = 70
		buy_btn.pressed.connect(_on_buy_pressed.bind(item, buy_btn))
		row.add_child(buy_btn)

		_buy_buttons.append({"item": item, "btn": buy_btn})

func _build_cat_popup() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.45)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)

	var popup := PanelContainer.new()
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popup.grow_vertical = Control.GROW_DIRECTION_BOTH
	_overlay.add_child(popup)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Beli untuk kucing mana?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	for cat_key in CAT_KEYS:
		var btn := Button.new()
		btn.text = CAT_LABELS[cat_key]
		btn.custom_minimum_size.x = 90
		btn.pressed.connect(_on_cat_selected.bind(cat_key))
		hbox.add_child(btn)
		_cat_buttons[cat_key] = btn

	vbox.add_child(HSeparator.new())

	var cancel_btn := Button.new()
	cancel_btn.text = "Batal"
	cancel_btn.pressed.connect(_close_cat_popup)
	vbox.add_child(cancel_btn)

func _on_buy_pressed(item: Dictionary, _btn: Button) -> void:
	if GameState.coins < item["price"]:
		_feedback_label.text = "Koin tidak cukup!"
		return

	if not item.get("consumable", false):
		if GameState.mood_accumulated < item.get("unlock_at_mood", 0):
			_feedback_label.text = "Belum cukup mood total untuk membuka ini! (%d/%d)" % [GameState.mood_accumulated, item["unlock_at_mood"]]
			return
		var any_eligible := false
		for cat_key in CAT_KEYS:
			var owned: Array = GameState.collectibles.get(cat_key, [])
			if item["id"] in owned:
				continue
			var requires: String = item.get("requires", "")
			if requires != "" and not (requires in owned):
				continue
			any_eligible = true
			break
		if not any_eligible:
			_feedback_label.text = "Semua kucing sudah punya ini."
			return
	else:
		var required_toy: String = item.get("requires_toy", "")
		if required_toy != "":
			var any_eligible := false
			for cat_key in CAT_KEYS:
				var owned: Array = GameState.collectibles.get(cat_key, [])
				if required_toy in owned:
					any_eligible = true
					break
			if not any_eligible:
				_feedback_label.text = "Beli mainan yang diperlukan dulu!"
				return

	_show_cat_popup(item)

func _show_cat_popup(item: Dictionary) -> void:
	_pending_item = item
	var is_consumable: bool = item.get("consumable", false)

	for cat_key in CAT_KEYS:
		var cat_btn: Button = _cat_buttons[cat_key]
		cat_btn.visible = true
		cat_btn.disabled = false

		if is_consumable:
			var required_toy: String = item.get("requires_toy", "")
			if required_toy != "":
				var owned: Array = GameState.collectibles.get(cat_key, [])
				cat_btn.visible = required_toy in owned
		else:
			var owned: Array = GameState.collectibles.get(cat_key, [])
			if item["id"] in owned:
				cat_btn.visible = false
			else:
				var requires: String = item.get("requires", "")
				cat_btn.disabled = requires != "" and not (requires in owned)

	_overlay.visible = true

func _close_cat_popup() -> void:
	if _overlay != null:
		_overlay.visible = false
	_pending_item = {}

func _on_cat_selected(cat_key: String) -> void:
	var item := _pending_item
	_close_cat_popup()
	_do_purchase(item, cat_key)

func _do_purchase(item: Dictionary, cat_key: String) -> void:
	if GameState.coins < item["price"]:
		_feedback_label.text = "Koin tidak cukup!"
		return

	GameState.coins -= item["price"]

	if item.get("consumable", false):
		var inv: Dictionary = GameState.inventory.get(cat_key, {})
		inv[item["id"]] = inv.get(item["id"], 0) + 1
		GameState.inventory[cat_key] = inv
		_feedback_label.text = "%s masuk ke inventory %s!" % [item["label"], CAT_LABELS[cat_key]]
	else:
		var boost: int = item["mood_boost"]
		GameState.mood[cat_key] = GameState.mood.get(cat_key, 0) + boost
		if boost > 0:
			GameState.mood_accumulated += boost

		if item.get("unlocks_tier", 0) > 0:
			var tier: int = item["unlocks_tier"]
			if GameState.pose_tier.get(cat_key, 1) < tier:
				GameState.pose_tier[cat_key] = tier

		var owned: Array = GameState.collectibles.get(cat_key, [])
		owned.append(item["id"])
		GameState.collectibles[cat_key] = owned
		_feedback_label.text = "Berhasil membeli %s untuk %s!" % [item["label"], CAT_LABELS[cat_key]]

	_refresh_coins()
	_refresh_all_buttons()

func _refresh_coins() -> void:
	_coins_label.text = "Coins: %d" % GameState.coins

func _refresh_all_buttons() -> void:
	for entry in _buy_buttons:
		var item: Dictionary = entry["item"]
		var btn: Button = entry["btn"]

		if item.get("consumable", false):
			var required_toy: String = item.get("requires_toy", "")
			if required_toy == "":
				btn.disabled = false
			else:
				var any_eligible := false
				for cat_key in CAT_KEYS:
					var owned: Array = GameState.collectibles.get(cat_key, [])
					if required_toy in owned:
						any_eligible = true
						break
				btn.disabled = not any_eligible
		else:
			var mood_ok: bool = GameState.mood_accumulated >= item.get("unlock_at_mood", 0)
			var any_eligible := false
			for cat_key in CAT_KEYS:
				var owned: Array = GameState.collectibles.get(cat_key, [])
				if item["id"] in owned:
					continue
				var req: String = item.get("requires", "")
				if req != "" and req not in owned:
					continue
				any_eligible = true
				break
			btn.disabled = not mood_ok or not any_eligible

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
