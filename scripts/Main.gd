extends Node2D
@export var card_scene: PackedScene

@onready var deck = preload("res://scripts/Deck.gd").new()
var numero = 0
var palo = ""
var ya_jugada = false  # bandera para no repetir acción

var mesa_cartas = []  # lista para rastrear las cartas en mesa
var mano_cpu = []

func _ready():
	add_child(deck)
	repartir_cartas()
	repartir_mano_cpu(5)

func repartir_mano_cpu(cantidad: int):
	var escala = 1.5
	var ancho_real = 80 * escala
	var separacion = 12
	var ancho_total = cantidad * ancho_real + (cantidad - 1) * separacion

	var screen_width = get_viewport_rect().size.x
	var inicio_x = (screen_width - ancho_total) / 2.0
	var y = 100  # Altura fija arriba

	for i in range(cantidad):
		var carta_info = deck.mazo.pop_back()
		var carta = card_scene.instantiate()
		carta.configurar_carta(carta_info["numero"], carta_info["palo"])
		carta.scale = Vector2(escala, escala)

		var x = inicio_x + i * (ancho_real + separacion)
		carta.position = Vector2(x, y)

		# 👇 Si quieres simular cartas boca abajo (opcional)
		# carta.rotation_degrees = 180

		add_child(carta)  # 👈 Añadimos directamente al nodo principal, NO a ManoCPU
		mano_cpu.append(carta)


		
func colocar_en_mesa(carta: Node2D):
	var mesa = $Mesa
	var index = mesa_cartas.size()
	var offset_x = 90  # separación entre cartas

	# 👇 Posición horizontal desde el borde izquierdo
	var destino = mesa.global_position + Vector2(index * offset_x, 0)

	mesa_cartas.append(carta)

	carta.z_index = mesa_cartas.size()
	
	# Mover la carta con animación
	var tween = carta.create_tween()
	tween.tween_property(carta, "position", destino, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Redimensionar si deseas
	tween.tween_property(carta, "scale", Vector2(2, 2), 0.3)

func turno_cpu():
	if mano_cpu.size() == 0:
		return

	var carta = mano_cpu.pop_front()
	colocar_en_mesa(carta)

func repartir_cartas():
	var cantidad_cartas = 5
	var ancho_real = 80
	var escala = 1.8
	var ancho_visible = ancho_real * escala
	var separacion = 10  # más juntas

	var ancho_total = (cantidad_cartas * ancho_visible) + ((cantidad_cartas - 1) * separacion)
	var screen_width = get_viewport_rect().size.x
	var screen_height = get_viewport_rect().size.y

	var centro_inicial = (screen_width - ancho_total) / 2.0

	for i in range(cantidad_cartas):
		var carta_info = deck.mazo.pop_back()
		var carta_escena = card_scene.instantiate()
		carta_escena.configurar_carta(carta_info["numero"], carta_info["palo"])
		carta_escena.scale = Vector2(escala, escala)

		var x = centro_inicial + i * (ancho_visible + separacion) + ancho_visible / 2.0
		var y = screen_height - 120
		carta_escena.position = Vector2(round(x), y)

		add_child(carta_escena)

func configurar_carta(nuevo_numero, nuevo_palo):
	numero = nuevo_numero
	palo = nuevo_palo
	actualizar_sprite()
	
func actualizar_sprite():
	var nombre_numero = "AS" if numero == 1 else ("J" if numero == 10 else ("Q" if numero == 11 else ("K" if numero == 12 else str(numero))))
	var nombre_palo = palo.to_upper()
	var ruta = "res://assets/cartas/" + nombre_numero + nombre_palo + ".png"

	if $Sprite2D and ResourceLoader.exists(ruta):
		$Sprite2D.texture = load(ruta)
		$Sprite2D.scale = Vector2(1, 1)
	else:
		print("No se encontró la imagen de la carta: ", ruta)

func _input_event(viewport, event, shape_idx):
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and not ya_jugada:
		jugar_carta()


func jugar_carta():
	ya_jugada = true
	print("Carta tocada: ", numero, palo)
	var destino = Vector2(
		get_viewport_rect().size.x / 2,
		get_viewport_rect().size.y / 2 - 50
	)

	var tween = create_tween()
	tween.tween_property(self, "position", destino, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Opcional: agrandarla un poco al llegar
	tween.tween_property(self, "scale", Vector2(2, 2), 0.3)
