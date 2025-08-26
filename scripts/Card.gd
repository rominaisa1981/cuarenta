extends Node2D

var numero = 0
var palo = ""
var ya_jugada = false
var seleccionada = false
signal carta_seleccionada(carta)
var es_mesa = false
var main = null  # Referencia a Main

func configurar_carta(nuevo_numero, nuevo_palo):
	numero = nuevo_numero
	palo = nuevo_palo

	actualizar_sprite()

func mostrar_dorso():
	if $Sprite2D:
		$Sprite2D.texture = load("res://assets/cartas/back.png")
		
func actualizar_sprite():
	#var nombre_numero = "AS" if numero == 1 else str(numero)
	
	var nombre_numero = ""

	if numero == 1:
		nombre_numero = "AS"
	elif numero == 10:
		nombre_numero = "J"
	elif numero == 11:
		nombre_numero = "Q"
	elif numero == 12:
		nombre_numero = "K"
	else:
		nombre_numero = str(numero)
	
	var nombre_palo = palo.to_upper()
		
	var ruta = "res://assets/cartas/" + nombre_numero + nombre_palo + ".png"
	
	if $Sprite2D and ResourceLoader.exists(ruta):
		$Sprite2D.texture = load(ruta)
		#$Sprite2D.scale = Vector2(1.5, 1.5)
		
	else:
		print("No se encontró la imagen de la carta: ", ruta)


func toggle_seleccion():
	emit_signal("carta_seleccionada", self)

func toggle_seleccion_mesa():
	if self in main.seleccion_mesa:
		main.seleccion_mesa.erase(self)
		position.y += 20  # Baja visualmente (desmarca)
	else:
		main.seleccion_mesa.append(self)
		position.y -= 20  # Sube visualmente (marca)
		

func deseleccionar_visualmente():
	if seleccionada:
		position.y += 30
		seleccionada = false
		
func jugar_carta():
	print("Carta jugada: ", numero, palo)

	ya_jugada = true

	var mesa = get_parent().get_node("Mesa")
	var destino_global = mesa.global_position
	
	var main = get_tree().get_root().get_node("Main")  
	main.colocar_en_mesa(self)
	main.turno_cpu()
	#var tween = create_tween()
	#tween.tween_property(self, "position", destino_global, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Opcional: agrandar la carta
	#tween.tween_property(self, "scale", Vector2(2, 2), 0.3)



func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed and not ya_jugada:		
				
		#jugar_carta()
		print(get_parent().name)
		if es_mesa:  # Solo si está en la mesa
			toggle_seleccion_mesa()
		else : 
			toggle_seleccion()
