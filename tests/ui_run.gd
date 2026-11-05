extends SceneTree
var total:=0
var failures:=0
var game:Node
func check(value:bool,name:String)->void:
	total+=1
	if value: print("PASS UI · "+name)
	else: failures+=1; printerr("FAIL UI · "+name)
func _init()->void: call_deferred("run")
func press_named(node:Node,text:String)->bool:
	for child in node.get_children():
		if child is Button and child.text==text: child.pressed.emit(); return true
		if press_named(child,text): return true
	return false
func capture(name:String)->void:
	game.refresh_hud()
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://builds/captures"); root.get_texture().get_image().save_png("res://builds/captures/"+name+".png")
func settle()->void:
	for i in range(35): await process_frame
func run()->void:
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame; game.set_process(false)
	check(game.modal_layer.visible,"Menu inicial")
	check(press_named(game.modal_panel,"Criar meu personagem"),"Criar personagem")
	check(press_named(game.modal_panel,"Começar minha história"),"Iniciar história")
	check(game.started,"Simulação iniciada")
	check(press_named(game.modal_panel,"Voltar ao bairro"),"Fechar tutorial")
	game.sim.speed=0; await settle(); await capture("01-bairro")
	game.sim.speed=1; game.sim.enqueue_move(Vector2i(7,8))
	for i in range(160): game.sim.tick(.1)
	game.sim.speed=0; await create_timer(.5).timeout
	check(CityData.building_at(game.sim.cell)=="home" and game.world.roof_alpha.home<.05,"Entrar remove telhado")
	await capture("02-interior")
	game.sim.speed=1; game.sim.enqueue_object("bed")
	for i in range(500):
		game.sim.tick(.1)
		if game.sim.current.get("arrived",false): break
	game.sim.speed=0; await settle()
	check(game.sim.current.get("id","")=="bed" and game.sim.current.get("arrived",false),"Pose usa ponto do móvel")
	await capture("05-dormir"); game.sim.cancel_all()
	game.sim.speed=1; game.sim.enqueue_move(Vector2i(7,11))
	for i in range(100): game.sim.tick(.1)
	game.sim.speed=0; await create_timer(.5).timeout; check(game.world.roof_alpha.home>.95,"Sair restaura telhado")
	game.show_settings(); check(game.modal_layer.visible,"Configurações"); game.close_modal()
	game.sim.needs=[78.0,82.0,90.0,85.0,68.0,75.0]; game.sim.minutes=539.9; game.sim.speed=3; game.sim.tick(.1)
	check(game.modal_layer.visible and game.sim.shift_prompt,"Pop-up do turno")
	await capture("03-expediente")
	check(press_named(game.modal_panel,"Ir agora"),"Ir agora funcional")
	check(game.sim.working and not game.modal_layer.visible,"Transporte inicia turno")
	game.sim.tick(50); check(not game.sim.working and game.sim.money==440,"Fim do turno e pagamento")
	game.sim.speed=0; await settle(); game.show_job(); await capture("04-financas"); game.close_modal()
	game.show_people(); check(game.modal_layer.visible,"Vizinhança"); game.close_modal()
	game.show_inventory(); check(game.modal_layer.visible,"Inventário"); game.close_modal()
	game.show_map(); check(game.modal_layer.visible,"Destinos"); game.close_modal()
	print("RESULTADO UI: %d verificações, %d falhas"%[total,failures]); game.queue_free(); await create_timer(.15).timeout; quit(1 if failures>0 else 0)
