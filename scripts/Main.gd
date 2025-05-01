extends Node2D
@export var card_scene: PackedScene

@onready var deck = preload("res://scripts/Deck.gd").new()
var numero = 0
var palo = ""
var ya_jugada = false  # bandera para no repetir acción

var mesa_cartas = []  # lista para rastrear las cartas en mesa
var mano_cpu = []
var mano_jugador = []

var carta_seleccionada = null

func _ready():
	add_child(deck)
	repartir_cartas_jugador(5)
	repartir_mano_cpu(5)

func _process(delta):
	$"Jugar Carta".disabled = carta_seleccionada == null
	
func repartir_mano_cpu(cantidad: int):
	var escala = 1.5
	var ancho_real = 80 * escala
	var separacion = 10
	var ancho_total = (cantidad * ancho_real) + ((cantidad - 1) * separacion)

	var screen_width = get_viewport_rect().size.x
	#var screen_height = get_viewport_rect().size.y
		
	
	var inicio_x = (screen_width - ancho_total) / 2.0
	var y = 100  # Altura fija arriba

	for i in range(cantidad):
		var carta_info = deck.mazo.pop_back()
		var carta = card_scene.instantiate()
		carta.configurar_carta(carta_info["numero"], carta_info["palo"])
		carta.mostrar_dorso()
		carta.scale = Vector2(escala, escala)

		var x = inicio_x + i * (ancho_real + separacion) + ancho_real / 2.0
		carta.position = Vector2(x, y)

		# 🌀 Inclinación igual que jugador
		if cantidad > 1:
			var inclinacion = -10 + (i / float(cantidad - 1)) * 20
			carta.rotation_degrees = -inclinacion
		else:
			carta.rotation_degrees = 0
			
		
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
	
	#carta.rotation_degrees = 0	
	carta.actualizar_sprite()
	# Mover la carta con animación
	var tween = carta.create_tween()
	tween.tween_property(carta, "position", destino, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Girar la carta para que se vea su cara
	tween.tween_property(carta, "rotation_degrees", 0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Redimensionar si deseas
	#tween.tween_property(carta, "scale", Vector2(2, 2), 0.3)

func turno_cpu():
	
	await get_tree().create_timer(1.2).timeout
	
	if mano_cpu.size() == 0:
		return

	var carta = mano_cpu.pop_front()
	
	# ✅ Mostrar cara de la carta
	carta.actualizar_sprite()

	# ✅ Crear tween para efecto de agrandar
	var tween = carta.create_tween()
	tween.tween_property(carta, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(carta, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# ✅ Esperar a que termine la animación
	await tween.finished

	# ✅ Esperar 2 segundos más antes de lanzarla a la mesa
	await get_tree().create_timer(1.0).timeout

	# ✅ Enviar la carta a la mesa
	colocar_en_mesa(carta)
	

func repartir_cartas_jugador(cantidad: int):
	var escala = 1.5
	var ancho_real = 80 * escala
	var separacion = 10
	var ancho_total = cantidad * ancho_real + (cantidad - 1) * separacion

	var screen_width = get_viewport_rect().size.x
	var inicio_x = (screen_width - ancho_total) / 2.0
	var base_y = get_viewport_rect().size.y - 120

	for i in range(cantidad):
		var carta_info = deck.mazo.pop_back()
		var carta = card_scene.instantiate()
		carta.connect("carta_seleccionada", Callable(self, "_on_carta_seleccionada"))
		carta.configurar_carta(carta_info["numero"], carta_info["palo"])
		carta.scale = Vector2(escala, escala)

		var x = inicio_x + i * (ancho_real + separacion)+ ancho_real / 2.0

		# 🎨 Altura con curva
		var offset_y = abs((cantidad - 1) / 2.0 - i) * 10
		carta.position = Vector2(x, base_y + offset_y)

		# 🌀 Inclinación para dar efecto de curva
		if cantidad > 1:
			var inclinacion = -10 + (i / float(cantidad - 1)) * 20
			carta.rotation_degrees = inclinacion
		else:
			carta.rotation_degrees = 0  # Si solo hay una carta, no inclinar

		add_child(carta)
		mano_jugador.append(carta)



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
	
func _on_carta_seleccionada(carta):
	if carta_seleccionada == carta:
		# Si es la misma carta → deseleccionar (bajar)
		var tween = carta.create_tween()
		tween.tween_property(carta, "position:y", carta.position.y + 30, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		carta_seleccionada = null
		carta.seleccionada = false
		return

	if carta_seleccionada != null:
		# Bajar la anterior
		var tween = carta_seleccionada.create_tween()
		tween.tween_property(carta_seleccionada, "position:y", carta_seleccionada.position.y + 30, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		carta_seleccionada.seleccionada = false

	# Subir la nueva carta
	var tween = carta.create_tween()
	tween.tween_property(carta, "position:y", carta.position.y - 30, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	carta.seleccionada = true

	carta_seleccionada = carta


func _on_button_pressed() -> void:
	if carta_seleccionada == null:
		print("No hay carta seleccionada.")
		return

	# ✅ Animar la carta seleccionada hacia la mesa
	var carta = carta_seleccionada

	# Ya no está seleccionada
	carta.seleccionada = false
	carta_seleccionada = null

	# Bajar la carta visualmente (si está levantada)
	var tween_bajar = carta.create_tween()
	tween_bajar.tween_property(carta, "position:y", carta.position.y + 30, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Esperar que baje
	await tween_bajar.finished

	# Colocar en la mesa
	await colocar_en_mesa(carta)

	# 🚨 Después de que la carta del jugador llega a la mesa → turno CPU
	turno_cpu()
