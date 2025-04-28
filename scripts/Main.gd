extends Node2D

@onready var deck = preload("res://scripts/Deck.gd").new()

func _ready():
	add_child(deck)
	repartir_cartas()

func repartir_cartas():
	var screen_width = get_viewport_rect().size.x
	var cantidad_cartas = 5
	var espacio = screen_width / (cantidad_cartas + 1)
	
	for i in range(cantidad_cartas):
		var carta_info = deck.mazo.pop_back()  # {'numero': 1, 'palo': 'brillo'}
		
		var carta_escena = preload("res://scenes/Card.tscn").instantiate()
		carta_escena.configurar_carta(carta_info["numero"], carta_info["palo"])
		
		carta_escena.position = Vector2(espacio * (i + 1), get_viewport_rect().size.y - 150)
		carta_escena.scale = Vector2(1.5, 1.5)  # Escalamos para móviles/tablets
		
		add_child(carta_escena)
