extends SceneTree
var checks:=0
var failures:=0
var game:Node
func check(value:bool,message:String)->void:
	checks+=1
	if value: print("PASS CONTROLE · "+message)
	else: failures+=1; printerr("FAIL CONTROLE · "+message)
func _init()->void: call_deferred("run")
func frames(count:int=3)->void:
	for i in range(count): await process_frame
func press(index:int)->void:
	var event:=InputEventJoypadButton.new(); event.device=0; event.button_index=index; event.pressed=true; Input.parse_input_event(event); await frames()
	event=InputEventJoypadButton.new(); event.device=0; event.button_index=index; event.pressed=false; Input.parse_input_event(event); await frames()
func axis(index:int,value:float)->void:
	var event:=InputEventJoypadMotion.new(); event.device=0; event.axis=index; event.axis_value=value; Input.parse_input_event(event); await frames()
func find_button(node:Node,text:String)->Button:
	for child in node.get_children():
		if child is Button and child.text==text: return child
		var found:=find_button(child,text)
		if found: return found
	return null
func capture(name:String)->void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	game.refresh_hud(); await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds/captures"); root.get_texture().get_image().save_png("res://builds/captures/"+name+".png")
func run()->void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await frames(); game.set_process(false)
	check(game.get_viewport().gui_get_focus_owner() is Button,"Menu inicial tem foco")
	await press(JOY_BUTTON_A)
	check(game.get_viewport().gui_get_focus_owner() is LineEdit,"A abre criador e foca nome")
	await press(JOY_BUTTON_A)
	check(game.name_keyboard!=null,"A abre teclado de nome sem teclado físico")
	await capture("06-controle-teclado")
	var field:LineEdit=game.name_field; var original:=field.text
	await press(JOY_BUTTON_A)
	check(field.text==original+"A","Teclado na tela escreve pelo controle")
	await press(JOY_BUTTON_B)
	check(game.name_keyboard==null and game.get_viewport().gui_get_focus_owner()==field,"B fecha teclado e restaura foco")
	await press(JOY_BUTTON_DPAD_DOWN)
	check(game.get_viewport().gui_get_focus_owner() is OptionButton,"Direcional percorre campos do criador")
	var start:=find_button(game.modal_panel,"Começar minha história"); start.grab_focus(); await press(JOY_BUTTON_A)
	check(game.started and game.modal_layer.visible,"A confirma criação e abre tutorial")
	await press(JOY_BUTTON_A)
	check(not game.modal_layer.visible,"A fecha tutorial e permite jogar")
	game.sim.speed=1; game.sim.npcs=[]; game.sim.cell=Vector2i(7,11); game.sim.direct_cooldown=0
	await axis(JOY_AXIS_LEFT_X,0.1); var before:Vector2i=game.sim.cell; await frames(8)
	check(game.sim.cell==before,"Zona morta evita movimento involuntário")
	await axis(JOY_AXIS_LEFT_X,1.0)
	check(game.sim.cell!=before,"Analógico esquerdo move o personagem")
	await axis(JOY_AXIS_LEFT_X,0.0)
	game.sim.direct_cooldown=0; before=game.sim.cell; await press(JOY_BUTTON_DPAD_DOWN)
	check(game.sim.cell!=before,"Direcional também move no bairro")
	game.sim.speed=1; await press(JOY_BUTTON_RIGHT_SHOULDER); check(game.sim.speed==2,"RB acelera")
	await press(JOY_BUTTON_LEFT_SHOULDER); check(game.sim.speed==1,"LB reduz velocidade")
	await press(JOY_BUTTON_BACK); check(game.sim.speed==0,"View pausa")
	await press(JOY_BUTTON_BACK); check(game.sim.speed==1,"View retoma")
	var zoom:int=game.world.zoom_level; await axis(JOY_AXIS_TRIGGER_RIGHT,1.0); await axis(JOY_AXIS_TRIGGER_RIGHT,0.0)
	check(game.world.zoom_level==zoom+1,"RT aproxima câmera")
	await axis(JOY_AXIS_TRIGGER_LEFT,1.0); await axis(JOY_AXIS_TRIGGER_LEFT,0.0)
	check(game.world.zoom_level==zoom,"LT afasta câmera")
	await axis(JOY_AXIS_RIGHT_X,1.0); await frames(4); await axis(JOY_AXIS_RIGHT_X,0.0)
	check(game.pad.cursor_active and game.pad.cursor.visible,"Analógico direito move cursor virtual")
	await press(JOY_BUTTON_RIGHT_STICK); check(not game.pad.cursor_active and game.world.following,"Clique do analógico restaura câmera")
	await press(JOY_BUTTON_Y); check(game.modal_layer.visible and game.get_viewport().gui_get_focus_owner() is Button,"Y abre destinos com foco")
	await press(JOY_BUTTON_B); check(not game.modal_layer.visible,"B volta do menu")
	game.sim.cell=Vector2i(7,11); await press(JOY_BUTTON_A)
	check(game.context.visible,"A abre interação na entrada próxima")
	if game.context.visible:
		check(game.context.get_focused_item()>=0 and not game.context.is_item_disabled(game.context.get_focused_item()),"Menu de interação foca ação válida")
		await press(JOY_BUTTON_A)
		check(not game.sim.queue.is_empty(),"A confirma Entrar e cria caminhada real")
	game.context.hide(); game.sim.cancel_all()
	await press(JOY_BUTTON_X); check(game.modal_layer.visible,"X lista interações próximas")
	check(game.get_viewport().gui_get_focus_owner() is Button,"Lista de ações foca botão acessível ao controle")
	await capture("07-controle-acoes")
	await press(JOY_BUTTON_A); check(game.context.visible,"Controle seleciona alvo na lista de ações")
	await press(JOY_BUTTON_B)
	game.sim.enqueue_object("bed"); await press(JOY_BUTTON_B); check(game.sim.queue.is_empty(),"B cancela ações no bairro")
	await press(JOY_BUTTON_START); check(game.modal_layer.visible,"Start abre menu completo")
	await capture("08-controle-menu")
	await press(JOY_BUTTON_START); check(not game.modal_layer.visible,"Start retorna ao jogo")
	game.sim.minutes=539.9; game.sim.speed=3; game.sim.tick(.1); await frames()
	check(game.sim.shift_prompt and game.modal_layer.visible,"Turno pode ser decidido pelo controle")
	await press(JOY_BUTTON_B); check(game.sim.shift_prompt,"B não fecha indevidamente a decisão de trabalho")
	await press(JOY_BUTTON_A); check(game.sim.working,"A confirma ida ao trabalho")
	game.pad.connection_changed(0,false)
	check(game.sim.speed==0 and game.pad.axes.is_empty(),"Desconexão interrompe movimento e pausa")
	print("RESULTADO CONTROLE: %d verificações, %d falhas"%[checks,failures]); game.queue_free(); await create_timer(.15).timeout; quit(1 if failures else 0)
