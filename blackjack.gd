extends Control

var color: Array = ["C", "D", "H", "P"]
var value: Array = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
var card_back_color: bool = true # Couleur des cartes -> 1 = Light | 2 = Dark |
var table_color: bool = false # Couleur du fond -> 1 = Vert #31663c | 2 = Rouge #461d25
var deck: Array = []
var player_hand: Array = []
var is_splited: bool = false
var player_splited_hand_left: Array = []
var player_splited_hand_right: Array = []
var dealer_hand: Array = []

# INITIALISATION
@onready var result_panel = $result_panel
@onready var result_label = $result_panel/result_label
@onready var result_detailed_label = $result_panel/result_detailed_label
@onready var dealer_label = $main_container/Hdealer_container/Vdealer_container/dealer_label
@onready var dealer_card = $main_container/Hdealer_container/dealer_card
@onready var player_label = $main_container/Hplayer_container/Vplayer_container/player_label
@onready var player_card = $main_container/Hplayer_container/player_card
@onready var splited_left_label = $main_container/splited_container/left_splited_container/left_splited_label
@onready var splited_left_card = $main_container/splited_container/left_splited_card
@onready var splited_right_label = $main_container/splited_container/right_splited_container2/right_splited_label
@onready var splited_right_card = $main_container/splited_container/right_splited_card

@onready var option = $option_button
@onready var money = $button_container/money
@onready var hit = $button_container/hit_button
@onready var stand = $button_container/stand_button
@onready var split = $button_container/split_button
@onready var replay = $button_container/replay_button

@onready var confetti = $confetti

func _ready() -> void:
	
	option.pressed.connect(_on_option_button)
	hit.pressed.connect(_on_hit_button)
	stand.pressed.connect(_on_stand_button)
	split.pressed.connect(_on_split_button)
	replay.pressed.connect(_on_replay_button)
	
	option.disabled = false
	hit.disabled = true
	stand.disabled = true
	split.disabled = true
	replay.disabled = true
	
	money.text = (" [img]res://assets/token.png[/img] %d" % Global.get_money())
	
	blackjack()

# JEU DU BLACKJACK
func blackjack() -> void:
	Global.remove_money(1)
	# Clear
	is_splited = false
	result_panel.hide()
	confetti.hide()
	player_hand.clear()
	player_splited_hand_left.clear()
	player_splited_hand_right.clear()
	dealer_hand.clear()
	update_label()
	# Créer deck
	shuffle()
	# Distribuer cartes
	await get_tree().create_timer(0.5).timeout
	deal(player_hand)
	await get_tree().create_timer(0.25).timeout
	deal(dealer_hand)
	await get_tree().create_timer(0.25).timeout
	deal(player_hand)
	await get_tree().create_timer(0.25).timeout
	deal(dealer_hand, false)
	# Test si Blackjack
	if is_blackjack(player_hand) or is_blackjack(dealer_hand):
		result()
	else:
		# Tour du joueur
		player_turn()

func shuffle() -> void:
	deck.clear() # On vide le Jeu
	for c in color: # Pour chaque couleur
		for v in value: # Pour chaque valeur
			# On ajoute la Carte au Jeu
			deck.push_back("%s-%s" % [v, c])
	deck.shuffle() # On mélange le Jeu

func deal(hand: Array, visible: bool = true) -> void:
	# Mélange le Deck si il est vide
	if deck.is_empty():
		shuffle()
	# On ajoute une Carte du Deck à la Main
	var card = deck.pop_back()
	if not visible:
		card += "-HIDDEN"
	hand.push_back(card)
	if can_split(player_hand):
		split.disabled = false
	update_label()
	# Si la main dépasse 21 met fin à la partie
	if hand_value(hand) > 21:
		result()

func reveal_card(hand: Array) -> void:
	for c in hand.size():
		if hand[c].ends_with("-HIDDEN"):
			hand[c] = hand[c].replace("-HIDDEN", "")

func hand_value(hand: Array) -> int:
	var total: int = 0
	var ace: int = 0
	# Pour chaque Carte dans la Main
	for card in hand:
		if card.ends_with("-HIDDEN"):
			continue
		# On récupère la valeur de la Carte
		var card_part = card.split("-")
		var card_value = card_part[0]
		# On ajoute la valeur au total
		match card_value:
			"A":
				total += 11
				ace += 1
			"J", "Q", "K":
				total += 10
			_:
				total += int(card_value)
	# Gestion des As (11 → 1 si dépassement)
	while total > 21 and ace > 0:
		total -= 10
		ace -= 1
	# On renvoie la valeur total
	return total

func is_blackjack(hand: Array) -> bool:
	return hand.size() == 2 and hand_value(hand) == 21

func can_split(hand: Array) -> bool:
	var first_value
	var second_value
	if hand.size() == 2:
		var card_part = hand[0].split("-")
		first_value = card_part[0]
		match first_value:
			"A":
				first_value = 11
			"J", "Q", "K":
				first_value = 10
			_:
				first_value = int(first_value)
		card_part = hand[1].split("-")
		second_value = card_part[0]
		match second_value:
			"A":
				second_value = 11
			"J", "Q", "K":
				second_value = 10
			_:
				second_value = int(second_value)
	return hand.size() == 2 and first_value == second_value

func player_turn() -> void: # Tour du joueur
	if can_split(player_hand):
		hit.disabled = false
		stand.disabled = false
		split.disabled = false
		replay.disabled = true
	else:
		hit.disabled = false
		stand.disabled = false
		split.disabled = true
		replay.disabled = true

func dealer_turn() -> void: # Tour du croupier
	reveal_card(dealer_hand)
	update_label()
	while hand_value(dealer_hand) < 17:
		await get_tree().create_timer(0.25).timeout
		deal(dealer_hand)
	result()

func result() -> void:
	await get_tree().create_timer(1).timeout
	if hand_value(player_hand) > 21:
		result_label.text = "PERDU.."
		result_detailed_label.text = "Le joueur depasse 21"
	elif hand_value(dealer_hand) > 21:
		Global.add_money(2)
		result_label.text = "GAGNER !"
		result_detailed_label.text = "Le croupier depasse 21"
	elif is_blackjack(player_hand) and not is_blackjack(dealer_hand):
		confetti.show()
		Global.add_money(5)
		result_label.text = "BLACKJACK !"
		result_detailed_label.text = "Le joueur a Jack Black"
	elif is_blackjack(dealer_hand) and not is_blackjack(player_hand):
		result_label.text = "PERDU.."
		result_detailed_label.text = "Le croupier a Jack Black"
	elif hand_value(player_hand) > hand_value(dealer_hand):
		Global.add_money(2)
		result_label.text = "GAGNER !"
		result_detailed_label.text = "Le joueur a une meilleur main"
	elif hand_value(dealer_hand) > hand_value(player_hand):
		result_label.text = "PERDU.."
		result_detailed_label.text = "Le croupier a une meilleur main"
	else:
		Global.add_money(1)
		result_label.text = "EGALITE"
		result_detailed_label.text = "Le joueur et le croupier on la meme main"
	result_panel.show()
	reveal_card(dealer_hand)
	update_label()
	hit.disabled = true
	stand.disabled = true
	split.disabled = true
	replay.disabled = false

# UI/UX
func _on_hit_button():
	deal(player_hand)
func _on_stand_button():
	dealer_turn()
func _on_split_button():
	var card
	is_splited = true
	card = player_hand.pop_back()
	player_splited_hand_right.push_back(card)
	card = player_hand.pop_back()
	player_splited_hand_left.push_back(card)
	update_label()
	await get_tree().create_timer(0.25).timeout
	deal(player_splited_hand_right)
	await get_tree().create_timer(0.25).timeout
	deal(player_splited_hand_left)
func _on_replay_button():
	blackjack()

func _on_option_button():
	table_color = !table_color
	card_back_color = !card_back_color
	update_label()

func update_label():
	if player_hand.is_empty():
		player_label.text = "0"
	else:
		player_label.text = str(hand_value(player_hand))
	
	if dealer_hand.is_empty():
		dealer_label.text = "0"
	else:
		dealer_label.text = str(hand_value(dealer_hand))
	
	if table_color:
		$background.color = Color(0.192, 0.4, 0.235)
	else:
		$background.color = Color(0.275, 0.114, 0.145)
	
	if is_splited:
		split.disabled = true
		$main_container/splited_container.show()
		$main_container/Hplayer_container.hide()
		if player_splited_hand_left.is_empty():
			splited_left_label.text = 0
		else:
			display_hand(player_splited_hand_left, splited_left_card)
			splited_left_label.text = str(hand_value(player_splited_hand_left))
		if player_splited_hand_right.is_empty():
			splited_right_label.text = "0"
		else:
			display_hand(player_splited_hand_right, splited_right_card)
			splited_right_label.text = str(hand_value(player_splited_hand_right))
		display_hand(player_hand, player_card)
	else:
		split.disabled = true
		$main_container/Hplayer_container.show()
		$main_container/splited_container.hide()
		display_hand(player_hand, player_card)
	
	money.text = (" [img]res://assets/token.png[/img] %d" % Global.get_money())
	display_hand(dealer_hand, dealer_card)


func display_hand(hand: Array, container: Control) -> void:
	# Nettoie les anciennes cartes
	for child in container.get_children():
		child.queue_free()

	for card in hand:
		var texture_rect := TextureRect.new()
		var texture_path := ""
		if card_back_color:
			if card.ends_with("-HIDDEN"):
				texture_path = "res://assets/cards/light/BACK.png"
			else:
				texture_path = "res://assets/cards/light/%s.png" % card
		else:
			if card.ends_with("-HIDDEN"):
				texture_path = "res://assets/cards/dark/BACK.png"
			else:
				texture_path = "res://assets/cards/dark/%s.png" % card
		texture_rect.texture = load(texture_path)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		container.add_child(texture_rect)
