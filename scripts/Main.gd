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

enum Turno { JUGADOR, CPU }
var turno_actual = Turno.JUGADOR
var primer_turno = Turno.JUGADOR

var seleccion_mesa: Array = []

const PlayerScript = preload("res://scripts/Player.gd")
var jugador: PlayerScript
var cpu: PlayerScript

var ultima_carta_jugada_en_mesa = null # Para la regla de "Caída"

const SECUENCIA_VALIDA = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12] # AS, 2-7, J, Q, K


func _ready():
	turno_actual = [Turno.JUGADOR, Turno.CPU].pick_random()
	primer_turno = turno_actual
	
	if turno_actual == Turno.CPU:
		turno_cpu()
	
	jugador = PlayerScript.new("Jugador")
	cpu = PlayerScript.new("CPU")

	add_child(deck)
	repartir_cartas_jugador(5)
	repartir_mano_cpu(5)
	actualizar_hud()
	

func actualizar_hud():
	$HUD/ScorePlayerLabel.text = "Puntos: " + str(jugador.puntaje)
	$HUD/ScoreCPULabel.text = "Puntos: " + str(cpu.puntaje)
	
	$HUD/CardsPlayerLabel.text = "Cartas: " + str(jugador.cartas_capturadas.size())
	$HUD/CardsCPULabel.text = "Cartas: " + str(cpu.cartas_capturadas.size())
	
func _process(delta):
	$"Jugar Carta".disabled = carta_seleccionada == null or turno_actual != Turno.JUGADOR
	if turno_actual == Turno.JUGADOR:
		$LabelTurno.text = "Turno: Jugador"
	else:
		$LabelTurno.text = "Turno: CPU"
	
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
		carta.main = self
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

func _reorganizar_mesa():
	print("Reorganizando las cartas de la mesa...")
	var offset_x = 95
	
	# Usamos un tween para que la reorganización sea una animación fluida
	var tween = create_tween()
	
	for i in range(mesa_cartas.size()):
		var carta = mesa_cartas[i]
		var nueva_posicion = Vector2(i * offset_x, 0)
		
		# Si la carta no está ya en su sitio, la movemos
		if carta.position != nueva_posicion:
			# Hacemos que la animación de cada carta sea paralela a las demás
			tween.parallel().tween_property(carta, "position", nueva_posicion, 0.25).set_trans(Tween.TRANS_SINE)

func colocar_en_mesa(carta: Node2D):
	var mesa = $Mesa
	
	# 1. LA FUENTE DE VERDAD: Se calcula el índice basado en las cartas
	# que REALMENTE existen como hijas del nodo Mesa. Esto evita desincronizaciones.
	var index = mesa.get_child_count()
	
	print("--- Colocando carta en mesa. Índice calculado: ", index)
	
	var offset_x = 95  # Aumenté un poco la separación para que se vea mejor
	
	# 2. POSICIÓN LOCAL: El destino es un vector local relativo a la posición de 'Mesa'.
	var destino = Vector2(index * offset_x, 0)

	# 3. REPARENTADO SEGURO: Se quita la carta de su padre anterior (Main)
	# y se añade al nuevo (Mesa).
	if carta.get_parent():
		carta.get_parent().remove_child(carta)
	mesa.add_child(carta)
	
	# 4. ACTUALIZACIÓN DE ESTADO: Actualizamos el array y las propiedades de la carta.
	mesa_cartas.append(carta)
	carta.es_mesa = true
	carta.z_index = index

	# 5. ANIMACIÓN: La animación mueve la posición LOCAL de la carta a su
	# destino LOCAL dentro de la mesa.
	var tween = carta.create_tween()
	tween.parallel().tween_property(carta, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(carta, "position", destino, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(carta, "rotation_degrees", 0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

#func colocar_en_mesa(carta: Node2D):
	#var mesa = $Mesa
	#var index = mesa_cartas.size()
	#var offset_x = 90  # separación entre cartas
#
	## 👇 Posición horizontal desde el borde izquierdo
	#var destino = mesa.global_position + Vector2(index * offset_x, 0)
#
	#mesa_cartas.append(carta)	
	#carta.es_mesa = true
	#carta.main = self
	#mesa.add_child(carta)
	#
	#carta.z_index = mesa_cartas.size()
	#
	##carta.rotation_degrees = 0	
	#carta.actualizar_sprite()
	## Mover la carta con animación
	#var tween = carta.create_tween()
	#tween.tween_property(carta, "position", destino, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#
	## Girar la carta para que se vea su cara
	#tween.tween_property(carta, "rotation_degrees", 0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	#
	## Redimensionar si deseas
	##tween.tween_property(carta, "scale", Vector2(2, 2), 0.3)


func turno_cpu():
	$"Jugar Carta".disabled = true
	for carta in mano_jugador:
		carta.get_node("Area2D").input_pickable = false

	await get_tree().create_timer(1.0).timeout
	if mano_cpu.is_empty():
		turno_actual = Turno.JUGADOR
		return

	print("CPU está pensando...")
	var jugada = _cpu_encontrar_mejor_jugada()

	if jugada.carta == null:
		print("CPU no tiene cartas para jugar.")
		turno_actual = Turno.JUGADOR
		return

	var carta_a_jugar = jugada.carta
	var captura_a_realizar = jugada.captura

	mano_cpu.erase(carta_a_jugar)
	carta_a_jugar.actualizar_sprite()
	
	var tween = carta_a_jugar.create_tween()
	tween.tween_property(carta_a_jugar, "scale", carta_a_jugar.scale * 1.2, 0.3)
	await tween.finished
	
	# --- INICIO DE LA CORRECCIÓN ---

	# 1. Revisar si es "Caída" ANTES de procesar la captura
	if ultima_carta_jugada_en_mesa != null and is_instance_valid(ultima_carta_jugada_en_mesa) and ultima_carta_jugada_en_mesa.numero == carta_a_jugar.numero:
		print("¡CAÍDA DE LA CPU!")
		await mostrar_mensaje_evento("¡CAÍDA CPU!")
		cpu.sumar_puntos(2)
		# Si la IA no había incluido la carta de la caída en su captura, la añadimos
		if not captura_a_realizar.has(ultima_carta_jugada_en_mesa):
			captura_a_realizar.append(ultima_carta_jugada_en_mesa)

	if not captura_a_realizar.is_empty():
		print("CPU juega ", carta_a_jugar.numero, " y captura ", captura_a_realizar.size(), " cartas.")
		
		var datos_cartas_capturadas = []
		for c in [carta_a_jugar] + captura_a_realizar:
			datos_cartas_capturadas.append({"numero": c.numero, "palo": c.palo})

		cpu.agregar_capturadas(datos_cartas_capturadas)
		
		for c in captura_a_realizar:
			mesa_cartas.erase(c)
			c.queue_free()
		carta_a_jugar.queue_free()
		
		# 2. Revisar si fue "Limpia" DESPUÉS de quitar las cartas
		if mesa_cartas.is_empty():
			print("¡LIMPIA DE LA CPU!")
			await mostrar_mensaje_evento("¡LIMPIA CPU!")
			cpu.sumar_puntos(2)
			
		_actualizar_vistas_capturadas()
		_reorganizar_mesa()
		
	else:
		print("CPU descarta ", carta_a_jugar.numero)
		colocar_en_mesa(carta_a_jugar)
		ultima_carta_jugada_en_mesa = carta_a_jugar

	# --- FIN DE LA CORRECCIÓN ---

	actualizar_hud()
	_revisar_ganador()
	_revisar_fin_de_mano()
	
	for carta in mano_jugador:
		carta.get_node("Area2D").input_pickable = true
	turno_actual = Turno.JUGADOR
	
	print("Turno del Jugador.")
	
	
#func turno_cpu():
	#
	#await get_tree().create_timer(1.2).timeout
	#
	#if mano_cpu.size() == 0:
		#return
#
	#var carta = mano_cpu.pop_front()
	#
	## ✅ Mostrar cara de la carta
	#carta.actualizar_sprite()
#
	## ✅ Crear tween para efecto de agrandar
	#var tween = carta.create_tween()
	#tween.tween_property(carta, "scale", Vector2(2, 2), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	#tween.tween_property(carta, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
#
	## ✅ Esperar a que termine la animación
	#await tween.finished
#
	## ✅ Esperar 2 segundos más antes de lanzarla a la mesa
	#await get_tree().create_timer(1.0).timeout
#
	## ✅ Enviar la carta a la mesa
	#colocar_en_mesa(carta)
	#
	## Fin del turno CPU → vuelve al jugador
	#turno_actual = Turno.JUGADOR

# Esta función borra las pilas actuales y las vuelve a dibujar con los datos actualizados
func _actualizar_vistas_capturadas():
	# Definimos los contenedores y los datos de cada jugador
	var vistas = [
		{ "container": $HUD/CapturadasJugador, "datos": jugador.cartas_capturadas },
		{ "container": $HUD/CapturadasCPU, "datos": cpu.cartas_capturadas }
	]

	for vista in vistas:
		var container = vista.container
		var datos_cartas = vista.datos

		# 1. Limpiamos las cartas que se mostraban antes
		for child in container.get_children():
			child.queue_free()

		# 2. Creamos las nuevas imágenes de las cartas capturadas
		var offset = Vector2(25, 0) # Pequeño desplazamiento para el efecto de pila
		for i in range(datos_cartas.size()):
			var datos_carta = datos_cartas[i]
			var carta_visual = card_scene.instantiate()

			carta_visual.configurar_carta(datos_carta.numero, datos_carta.palo)
			carta_visual.scale = Vector2(0.8, 0.8) # Las hacemos un poco más pequeñas
			carta_visual.position = i * offset # Apilamos con desplazamiento
			carta_visual.z_index = i # Asegura que se apilen en orden

			container.add_child(carta_visual)
			
# scripts/Main.gd

func _terminar_partida():
	var total_jugador = jugador.cartas_capturadas.size()
	var total_cpu = cpu.cartas_capturadas.size()
	
	var puntos_jugador = 0
	var puntos_cpu = 0

	print("--- Fin de la Partida: Puntuación del Cartón (Reglas C++) ---")
	print("Cartas del Jugador: ", total_jugador)
	print("Cartas de la CPU: ", total_cpu)

	# --- Regla: Puntuación si se tienen 20 o más cartas ---
	if total_jugador >= 20:
		puntos_jugador = 6 + (total_jugador - 20)
		# Regla: Si el total es impar, se suma un punto extra
		if total_jugador % 2 != 0:
			puntos_jugador += 1
		jugador.sumar_puntos(puntos_jugador)
		print("Jugador gana cartón: +%d puntos" % puntos_jugador)
		await mostrar_mensaje_evento("Ganas cartón (+%d Pts)" % puntos_jugador)

	if total_cpu >= 20:
		puntos_cpu = 6 + (total_cpu - 20)
		# Regla: Si el total es impar, se suma un punto extra
		if total_cpu % 2 != 0:
			puntos_cpu += 1
		cpu.sumar_puntos(puntos_cpu)
		print("CPU gana cartón: +%d puntos" % puntos_cpu)
		await mostrar_mensaje_evento("CPU gana cartón (+%d Pts)" % puntos_cpu)
	
	# --- Regla: Empate con menos de 20 cartas ---
	if total_jugador == total_cpu and total_jugador < 20:
		print("Empate en cartas. Gana el que no fue primer turno.")
		# Se dan 2 puntos al jugador que NO inició la ronda
		if primer_turno == Turno.JUGADOR:
			cpu.sumar_puntos(2)
			await mostrar_mensaje_evento("CPU gana por empate (+2 Pts)")
		else:
			jugador.sumar_puntos(2)
			await mostrar_mensaje_evento("Ganas por empate (+2 Pts)")
	
	if total_jugador > total_cpu:
		jugador.sumar_puntos(2)
		await mostrar_mensaje_evento("Ganas el cartón (+2 Pts)")
	elif total_cpu > total_jugador:
		cpu.sumar_puntos(2)
		await mostrar_mensaje_evento("CPU gana el cartón (+2 Pts)")
	
	# Pequeña pausa para que se lean los mensajes
	await get_tree().create_timer(1.5).timeout

	# Actualizar el marcador y mostrar la pantalla final
	actualizar_hud()
	# Después de sumar puntos del cartón, revisamos si alguien ganó EL JUEGO
	if not _revisar_ganador():
		# Si nadie ha ganado, iniciamos una nueva ronda
		_iniciar_nueva_ronda()


func _revisar_ganador() -> bool:
	# Esta función ahora solo comprueba si se cumplió la condición de victoria (>= 40).
	# Devuelve 'true' si el juego terminó, y 'false' si no.
	var ganador = ""
	if jugador.puntaje >= 40:
		ganador = "¡Ganaste la partida!"
	elif cpu.puntaje >= 40:
		ganador = "La CPU ha ganado la partida."

	if ganador != "":
		$HUD/PanelFinPartida/TituloLabel.text = "Fin del Juego"
		$HUD/PanelFinPartida/ResultadoLabel.text = ganador
		$HUD/PanelFinPartida.visible = true
		return true # El juego ha terminado
	
	return false # El juego continúa
		
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
		carta.main = self
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
	var tipo_ronda = _revisar_ronda(mano_jugador)
	if tipo_ronda != "":
		$HUD/RondaButton.visible = true
		$HUD/RondaButton.set_meta("tipo", tipo_ronda) # Guardamos qué tipo es



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
	# Si se hace clic en la carta que ya estaba seleccionada, se deselecciona.
	if carta_seleccionada == carta:
		carta.deseleccionar_visualmente()
		carta_seleccionada = null
		return

	# ✅ ESTA ES LA PARTE CLAVE QUE AÑADIMOS
	# Si ya había otra carta seleccionada, la bajamos visualmente.
	if carta_seleccionada != null:
		carta_seleccionada.deseleccionar_visualmente()

	# Ahora, seleccionamos la nueva carta, subiéndola visualmente.
	var tween = carta.create_tween()
	tween.tween_property(carta, "position:y", carta.position.y - 30, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	carta.seleccionada = true

	# Finalmente, guardamos la referencia a la nueva carta seleccionada.
	carta_seleccionada = carta


func _on_button_pressed() -> void:
	if carta_seleccionada == null:
		print("No hay carta seleccionada.")
		return

	var carta = carta_seleccionada
	var es_captura_valida = validar_captura(carta, seleccion_mesa)

	# --- Lógica de "Caída" ---
	if ultima_carta_jugada_en_mesa != null and is_instance_valid(ultima_carta_jugada_en_mesa) and ultima_carta_jugada_en_mesa.numero == carta.numero:
		print("¡CAÍDA!")
		await mostrar_mensaje_evento("¡CAÍDA!")
		jugador.sumar_puntos(2)
		
		# ✅ CORRECCIÓN: Solo añadimos la carta si el jugador no la seleccionó manualmente.
		if not seleccion_mesa.has(ultima_carta_jugada_en_mesa):
			seleccion_mesa.append(ultima_carta_jugada_en_mesa)
			
		es_captura_valida = true

	# --- Procesar el resultado de la jugada ---
	if es_captura_valida:
		# (El resto de esta sección queda igual)
		print("Captura exitosa!")
		var datos_cartas_capturadas = []
		for c in [carta] + seleccion_mesa:
			datos_cartas_capturadas.append({"numero": c.numero, "palo": c.palo})
		jugador.agregar_capturadas(datos_cartas_capturadas)

		for c in seleccion_mesa:
			mesa_cartas.erase(c)
			c.queue_free()
		
		mano_jugador.erase(carta)
		carta.queue_free()
		
		if mesa_cartas.is_empty():
			await mostrar_mensaje_evento("¡LIMPIA!")
			jugador.sumar_puntos(2)
		
		seleccion_mesa.clear()
		_actualizar_vistas_capturadas()
		_reorganizar_mesa()
		
	else:
		# (Esta sección 'else' queda igual)
		print("Jugada no válida o descarte. Colocando carta en la mesa.")
		mano_jugador.erase(carta)
		colocar_en_mesa(carta)
		ultima_carta_jugada_en_mesa = carta
		
		for c in seleccion_mesa:
			c.deseleccionar_visualmente()
		seleccion_mesa.clear()

	# --- Limpieza final y cambio de turno (esto queda igual) ---
	carta_seleccionada = null
	actualizar_hud()
	_revisar_ganador()
	_revisar_fin_de_mano()
	
	turno_actual = Turno.CPU
	turno_cpu()





# Devuelve un array con todos los subconjuntos/combinaciones posibles de un array dado
func _generar_combinaciones(array: Array) -> Array:
	var resultados = [[]]
	for elemento in array:
		var nuevos_subconjuntos = []
		for subconjunto in resultados:
			nuevos_subconjuntos.append(subconjunto + [elemento])
		resultados.append_array(nuevos_subconjuntos)
	resultados.pop_front() # Eliminamos el primer resultado que es un array vacío []
	return resultados
	

func _cpu_encontrar_mejor_jugada():
	var mejor_jugada = {
		"carta": null,
		"captura": [],
		"valor": -1
	}

	var combinaciones_mesa = _generar_combinaciones(mesa_cartas)

	# 1. Iterar sobre cada carta en la mano de la CPU
	for carta_cpu in mano_cpu:
		# 2. Iterar sobre cada combinación posible de cartas en la mesa
		for combinacion in combinaciones_mesa:
			if validar_captura(carta_cpu, combinacion):
				# Esta es una jugada válida, ahora calculamos su valor
				var valor_actual = combinacion.size() # Valor base: 1 punto por carta
				if combinacion.size() == mesa_cartas.size():
					valor_actual += 10 # Bonus por "Limpia"

				# Si esta jugada es mejor que la que teníamos, la guardamos
				if valor_actual > mejor_jugada.valor:
					mejor_jugada.valor = valor_actual
					mejor_jugada.carta = carta_cpu
					mejor_jugada.captura = combinacion

	# 3. Si no se encontró ninguna jugada de captura
	if mejor_jugada.carta == null and not mano_cpu.is_empty():
		# Descartar la carta de menor valor
		var carta_mas_baja = mano_cpu[0]
		for carta in mano_cpu:
			if carta.numero < carta_mas_baja.numero:
				carta_mas_baja = carta
		mejor_jugada.carta = carta_mas_baja

	return mejor_jugada

func _revisar_fin_de_mano():
	# Si ambos jugadores ya no tienen cartas en la mano...
	if mano_jugador.is_empty() and mano_cpu.is_empty():
		print("--- Fin de la mano ---")
		await get_tree().create_timer(1.5).timeout # Pausa para que se vea la mesa vacía

		# Verificamos si aún quedan cartas en el mazo
		if not deck.mazo.is_empty():
			print("Repartiendo nueva mano...")
			repartir_cartas_jugador(5)
			repartir_mano_cpu(5)
			# Aquí llamaremos a la revisión de "Ronda" en el siguiente paso
		else:
			print("El mazo está vacío. Fin de la partida.")
			_terminar_partida()
			
func validar_captura(carta_jugada, cartas_seleccionadas):
	if cartas_seleccionadas.is_empty():
		return false

	# --- Regla 1: Captura por Par ---
	if cartas_seleccionadas.size() == 1:
		if cartas_seleccionadas[0].numero == carta_jugada.numero:
			print("Validación: Es un PAR.")
			return true

	# --- Regla 2: Captura por Suma ---
	if carta_jugada.numero <= 7:
		var suma = 0
		var todas_son_numeros_bajos = true
		for carta_en_mesa in cartas_seleccionadas:
			if carta_en_mesa.numero >= 10:
				todas_son_numeros_bajos = false
				break
			suma += carta_en_mesa.numero
		
		if todas_son_numeros_bajos and suma == carta_jugada.numero:
			print("Validación: Es una SUMA.")
			return true

	# --- Regla 3: Captura por Escalera ---
	# ✅ CORRECCIÓN: Toda la lógica de la escalera ahora está dentro de una condición.
	# Solo intentaremos validar una escalera si la carta base está en la mesa.
	var base_en_mesa = false
	for carta_en_mesa in cartas_seleccionadas:
		if carta_en_mesa.numero == carta_jugada.numero:
			base_en_mesa = true
			break
	
	# Si la base está, procedemos a validar la secuencia completa.
	if base_en_mesa:
		var unicos = []
		for carta_en_mesa in cartas_seleccionadas:
			if not unicos.has(carta_en_mesa.numero):
				unicos.append(carta_en_mesa.numero)
		unicos.sort()
		
		if unicos[0] != carta_jugada.numero:
			return false # La escalera debe empezar con la carta jugada

		var indice_inicio = SECUENCIA_VALIDA.find(unicos[0])
		if indice_inicio == -1:
			return false
			
		for i in range(unicos.size()):
			if (indice_inicio + i) >= SECUENCIA_VALIDA.size() or unicos[i] != SECUENCIA_VALIDA[indice_inicio + i]:
				return false # La secuencia se rompió
				
		print("Validación: Es una ESCALERA.")
		return true # Si pasó todas las pruebas, es una escalera válida
		
	# Si no fue ni par, ni suma, ni una escalera válida, entonces no es una captura válida.
	return false


func _revisar_ronda(mano: Array) -> String:
	var contador = {} # Usaremos un diccionario para contar los números
	for carta in mano:
		if contador.has(carta.numero):
			contador[carta.numero] += 1
		else:
			contador[carta.numero] = 1

	for numero in contador:
		if contador[numero] == 4:
			return "doble_ronda"
		if contador[numero] == 3:
			return "ronda"

	return "" # No hay ni ronda ni doble ronda

func _on_nuevo_juego_button_pressed() -> void:
	get_tree().reload_current_scene()


func mostrar_mensaje_evento(mensaje: String, duracion: float = 1.5):
	var label = $HUD/EventLabel
	label.text = mensaje
	label.visible = true
	await get_tree().create_timer(duracion).timeout
	label.visible = false

func _on_ronda_button_pressed() -> void:
	var tipo_ronda = $HUD/RondaButton.get_meta("tipo")
	if tipo_ronda == "ronda":
		jugador.sumar_puntos(2)
		print("¡Jugador canta RONDA! +2 puntos.")
		await mostrar_mensaje_evento("¡RONDA!")
	elif tipo_ronda == "doble_ronda":
		jugador.sumar_puntos(4)
		print("¡Jugador canta DOBLE RONDA! +4 puntos.")

	actualizar_hud()
	_revisar_ganador()
	$HUD/RondaButton.visible = false # Ocultamos el botón después de usarlo

func _iniciar_nueva_ronda():
	await mostrar_mensaje_evento("INICIANDO NUEVA RONDA", 2.0)
	
	# 0. Limpiar las cartas sobrantes de la mesa --- INICIO DE LA CORRECCIÓN ---
	for carta in mesa_cartas:
		if is_instance_valid(carta):
			carta.queue_free() # Elimina el nodo de la carta de la partida
	mesa_cartas.clear() # Vacía el array que las controlaba
	
	# 1. Resetear el estado de los jugadores para la ronda (no el puntaje)
	jugador.reset_para_nueva_ronda()
	cpu.reset_para_nueva_ronda()
	_actualizar_vistas_capturadas() # Limpia visualmente las capturas
	
	# 2. Crear y barajar un mazo nuevo
	deck.crear_mazo()
	deck.barajar()
		
	
	# 3. Repartir las primeras manos de la nueva ronda
	repartir_cartas_jugador(5)
	repartir_mano_cpu(5)
	actualizar_hud()
	
	# 4. Asignar el turno (puedes alternarlo si quieres, por ahora es aleatorio)
	turno_actual = [Turno.JUGADOR, Turno.CPU].pick_random()
	primer_turno = turno_actual
	if turno_actual == Turno.CPU:
		turno_cpu()
