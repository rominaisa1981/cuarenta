extends Node2D
@export var card_scene: PackedScene

@onready var deck = preload("res://scripts/Deck.gd").new()

func _ready():
	add_child(deck)
	repartir_cartas()

func repartir_cartas():
	#var screen_width = get_viewport_rect().size.x
	var cantidad_cartas = 5
	#var espacio = screen_width / (cantidad_cartas + 1)
	var ancho_carta = 80
	var separacion = 45
	var inicio_x = (get_viewport_rect().size.x - ((ancho_carta + separacion) * cantidad_cartas - separacion)) / 2.0

	for i in range(cantidad_cartas):
		var carta_info = deck.mazo.pop_back()  # {'numero': 1, 'palo': 'brillo'}
				
		var carta_escena = card_scene.instantiate() #preload("res://scenes/Card.tscn").instantiate()
		carta_escena.configurar_carta(carta_info["numero"], carta_info["palo"])
		
		var x = inicio_x + i * (ancho_carta + separacion)
		carta_escena.position = Vector2(x, get_viewport_rect().size.y - 120)
		#carta_escena.position = Vector2(espacio * (i + 1), get_viewport_rect().size.y - 150)
		carta_escena.scale = Vector2(1.3, 1.3)  # Escalamos para móviles/tablets
		
		add_child(carta_escena)
