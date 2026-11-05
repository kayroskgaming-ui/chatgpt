extends Node
var sim:=LifeSimulation.new()
var world:CityWorld
var root:Control
var modal_layer:Control
var modal_panel:PanelContainer
var context:PopupMenu
var context_actions:Array[Callable]=[]
var time_label:Label
var money_label:Label
var mood_label:Label
var action_label:Label
var job_label:Label
var toast_label:Label
var need_bars:Array[ProgressBar]=[]
var need_values:Array[Label]=[]
var queue_box:VBoxContainer
var messages:RichTextLabel
var fade:ColorRect
var music:AudioStreamPlayer
var logs:Array[String]=[]
var started:=false
var previous_speed:=1
var refresh_elapsed:=0.0
var key_elapsed:=0.0
var last_queue:=""
const CREAM=Color("eee4cd")
const MINT=Color("b9d6b1")
func _ready()->void:
	world=CityWorld.new(); world.sim=sim; add_child(world); world.selected.connect(on_cell)
	sim.notice.connect(log_message); sim.shift_requested.connect(show_shift)
	build_ui()
	music=AudioStreamPlayer.new(); music.stream=load("res://assets/aurora.wav"); music.volume_db=sim.audio_volume; add_child(music)
	if DisplayServer.get_name()!="headless": music.play()
	music.finished.connect(music.play)
	log_message("Boas-vindas a Vila Aurora! Clique no chão para caminhar.")
	show_start()
func style(bg:Color=Color("182d35"),border:Color=Color("3d5658"))->StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border; s.set_border_width_all(1); s.set_corner_radius_all(8)
	s.content_margin_left=16; s.content_margin_right=16; s.content_margin_top=12; s.content_margin_bottom=12
	return s
func label(text:String,size:int=15,color:Color=CREAM)->Label:
	var l:=Label.new(); l.text=text; l.set_meta("base_font_size",size)
	l.add_theme_font_size_override("font_size",int(size*(1.15 if sim.ui_large else 1.0))); l.add_theme_color_override("font_color",color)
	return l
func button(text:String,fn:Callable,parent:Node)->Button:
	var b:=Button.new(); b.text=text; b.custom_minimum_size.y=34; b.pressed.connect(fn); parent.add_child(b); return b
func build_ui()->void:
	var hud:=CanvasLayer.new(); add_child(hud)
	root=Control.new(); hud.add_child(root); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme:=Theme.new(); theme.default_font_size=15; theme.set_color("font_color","Label",CREAM); theme.set_color("font_color","Button",CREAM)
	theme.set_stylebox("normal","Button",style(Color("25434a"))); theme.set_stylebox("hover","Button",style(Color("3b6163"),MINT)); theme.set_stylebox("pressed","Button",style(Color("58776a"),MINT)); theme.set_stylebox("focus","Button",style(Color(0,0,0,0),Color("efcb85"))); theme.set_stylebox("panel","PanelContainer",style()); root.theme=theme
	var top:=PanelContainer.new(); root.add_child(top); top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); top.offset_bottom=88
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",22); top.add_child(row)
	var title:=VBoxContainer.new(); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(title); title.add_child(label("MINHA VIDA",25,MINT)); title.add_child(label("HISTÓRIAS DA CIDADE  /  VILA AURORA",11))
	var clock_box:=VBoxContainer.new(); row.add_child(clock_box); time_label=label("",19); clock_box.add_child(time_label); money_label=label("",15,MINT); clock_box.add_child(money_label)
	for value in [0,1,2,3]: button("Ⅱ" if value==0 else "%d×"%value,func(): sim.speed=value; refresh_hud(),row)
	button("Menu",show_menu,row)
	var side:=PanelContainer.new(); root.add_child(side); side.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE); side.offset_left=-306; side.offset_right=-12; side.offset_top=100; side.offset_bottom=-14
	var scroll:=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; side.add_child(scroll)
	var column:=VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; column.add_theme_constant_override("separation",9); scroll.add_child(column)
	column.add_child(label("SEU COTIDIANO",12,MINT)); mood_label=label("",18); mood_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(mood_label)
	for i in range(6):
		var line:=HBoxContainer.new(); column.add_child(line)
		var name_label:=label(LifeSimulation.NEED_NAMES[i]); name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; line.add_child(name_label)
		var value:=label("",13); line.add_child(value); need_values.append(value)
		var bar:=ProgressBar.new(); bar.custom_minimum_size.y=7; bar.show_percentage=false
		var bg:=StyleBoxFlat.new(); bg.bg_color=Color("31434a"); bg.set_corner_radius_all(3); bar.add_theme_stylebox_override("background",bg)
		var fill:=StyleBoxFlat.new(); fill.bg_color=Color("9dbb8a"); fill.set_corner_radius_all(3); bar.add_theme_stylebox_override("fill",fill); column.add_child(bar); need_bars.append(bar)
	column.add_child(HSeparator.new()); action_label=label("",14); action_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(action_label)
	button("Cancelar ações ×",func(): sim.cancel_all(),column); queue_box=VBoxContainer.new(); column.add_child(queue_box)
	column.add_child(HSeparator.new()); job_label=label("",13); job_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(job_label)
	button("Trabalho e finanças",show_job,column); column.add_child(HSeparator.new()); button("Inventário e personagem",show_inventory,column); button("Vizinhança e amizades",show_people,column)
	messages=RichTextLabel.new(); messages.custom_minimum_size.y=95; messages.scroll_following=true; messages.add_theme_font_size_override("normal_font_size",12); column.add_child(messages)
	var bottom:=PanelContainer.new(); root.add_child(bottom); bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); bottom.offset_right=-322; bottom.offset_left=12; bottom.offset_top=-66; bottom.offset_bottom=-14
	var tools:=HBoxContainer.new(); tools.add_theme_constant_override("separation",8); bottom.add_child(tools)
	button("⌂ Casa",func(): sim.enqueue_move(Vector2i(7,8)); follow(),tools); button("Mapa",show_map,tools); button("Salvar · F5",save_now,tools); button("Câmera · C",follow,tools)
	var hint:=label("Clique: andar / interagir · WASD: mover",11); hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; tools.add_child(hint)
	var toast:=PanelContainer.new(); toast.position=Vector2(12,100); toast.custom_minimum_size=Vector2(580,0); toast.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(toast)
	toast_label=label("",13,MINT); toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; toast_label.custom_minimum_size.x=545; toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE; toast.add_child(toast_label)
	context=PopupMenu.new(); root.add_child(context); context.id_pressed.connect(func(id): if id>=0 and id<context_actions.size(): context_actions[id].call())
	fade=ColorRect.new(); fade.color=Color(0.05,0.1,0.13,0); fade.mouse_filter=Control.MOUSE_FILTER_IGNORE; root.add_child(fade); fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer=Control.new(); root.add_child(modal_layer); modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_layer.hide()
	var dim:=ColorRect.new(); modal_layer.add_child(dim); dim.color=Color(0.02,0.05,0.08,0.76); dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center:=CenterContainer.new(); modal_layer.add_child(center); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_panel=PanelContainer.new(); modal_panel.custom_minimum_size=Vector2(600,0); center.add_child(modal_panel); refresh_hud()
func follow()->void: world.following=true; world.pan=Vector2.ZERO
func transition()->void:
	fade.color.a=0.9; create_tween().tween_property(fade,"color:a",0.0,0.65)
func _process(delta:float)->void:
	if started: sim.tick(delta)
	key_elapsed+=delta
	if started and not modal_layer.visible and key_elapsed>0.13:
		var dx:=int(Input.is_physical_key_pressed(KEY_D))-int(Input.is_physical_key_pressed(KEY_A)); var dy:=int(Input.is_physical_key_pressed(KEY_S))-int(Input.is_physical_key_pressed(KEY_W))
		if dx!=0 or dy!=0:
			var dir:=Vector2i(dx+dy,dy-dx); dir=Vector2i(signi(dir.x),0) if dir.x!=0 else Vector2i(0,signi(dir.y)); sim.manual_step(dir); key_elapsed=0
	refresh_elapsed+=delta
	if refresh_elapsed>0.25: refresh_elapsed=0; refresh_hud()
	if started and sim.minutes-sim.autosave_at>=180:
		sim.autosave_at=sim.minutes
		if SaveStore.save_game(sim)!=OK: log_message("Falha no salvamento automático.")
func _unhandled_key_input(event:InputEvent)->void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_ESCAPE:
		if modal_layer.visible and started and not sim.shift_prompt: close_modal()
		elif started: show_menu()
	if modal_layer.visible: return
	match event.keycode:
		KEY_SPACE: sim.speed=1 if sim.speed==0 else 0
		KEY_1: sim.speed=1
		KEY_2: sim.speed=2
		KEY_3: sim.speed=3
		KEY_F5: save_now()
		KEY_F9: load_now()
		KEY_C: follow()
		KEY_F3: world.debug=not world.debug
		KEY_M: show_map()
		KEY_X: sim.cancel_all()
func refresh_hud()->void:
	if time_label==null: return
	var days:=["Seg","Ter","Qua","Qui","Sex","Sáb","Dom"]
	time_label.text="%s · Dia %d  %s  %s"%[days[sim.day()%7],sim.day()+1,sim.clock(),"Ⅱ" if sim.speed==0 else str(sim.speed)+"×"]
	money_label.text="V$ %d · %s"%[sim.money,sim.player_name]; mood_label.text=sim.mood()+" · conforto "+str(sim.comfort()); mood_label.tooltip_text=sim.mood_cause
	for i in range(6):
		need_bars[i].value=sim.needs[i]; need_values[i].text=str(int(sim.needs[i]))+"%"; need_bars[i].get_theme_stylebox("fill").bg_color=Color("cd826f") if sim.needs[i]<25 else Color("9dbb8a")
	action_label.text=sim.current.get("name","Livre para explorar")
	if not sim.route.is_empty(): action_label.text="A caminho · "+action_label.text
	elif sim.current.get("remaining",0)>0: action_label.text+=" · %d min"%ceili(sim.current.remaining)
	var qstr:=str(sim.queue)
	if qstr!=last_queue:
		last_queue=qstr
		for child in queue_box.get_children(): child.queue_free()
		for i in range(mini(5,sim.queue.size())): button("%d. %s ×"%[i+1,sim.queue[i].name],func(): sim.cancel_index(i),queue_box)
	job_label.text="BARISTA · Café da Esquina\nSeg–Sex 09:00–13:00 · V$ 120/dia"
	if sim.working: job_label.text="EM EXPEDIENTE\nRestam %d min · %s"%[maxi(0,int(sim.work_end-sim.minutes)),["Normal","Esforço","Pegar leve"][sim.work_style]]
func log_message(message:String)->void:
	logs.append("[%s] %s"%[sim.clock(),message])
	if logs.size()>14: logs.pop_front()
	if messages: messages.text="\n\n".join(logs)
	if toast_label: toast_label.text=message
func on_cell(cell:Vector2i)->void:
	if not started or modal_layer.visible: return
	var building:=CityData.building_at(cell)
	if building!="" and world.roof_alpha[building]>0.5:
		context_actions.clear(); context.clear()
		for h in CityData.HOMES:
			if h.id==building:
				add_context(h.name,func(): pass,true)
				if building=="bia": add_context("Tocar campainha",func(): sim.ring_bell())
				if CityData.can_enter(building,"player",sim.invited):
					var inside:Vector2i=h.door+Vector2i.UP; add_context("Entrar",func(): sim.enqueue_move(inside))
		popup_context(); return
	for npc in sim.npcs:
		if npc.cell==cell:
			context_actions.clear(); context.clear(); add_context(npc.name+" · "+npc.state,func(): pass,true)
			for action in ["Apresentar-se","Conversar","Contar piada"]:
				var id:String=npc.id; add_context(action,func(): sim.enqueue_social(id,action))
			popup_context(); return
	for o in CityData.OBJECTS:
		if o.cell==cell:
			context_actions.clear(); context.clear(); add_context(o.name,func(): pass,true); add_context(o.action,func(): sim.enqueue_object(o.id)); popup_context(); return
	if CityData.walkable(cell,"player",sim.invited): sim.enqueue_move(cell)
	else: log_message("Caminho bloqueado. Use a entrada do imóvel.")
func add_context(text:String,fn:Callable,disabled:bool=false)->void:
	context.add_item(text,context_actions.size()); context.set_item_disabled(context_actions.size(),disabled); context_actions.append(fn)
func popup_context()->void:
	context.position=Vector2i(root.get_global_mouse_position()); context.popup()
func open_modal(title:String,subtitle:String="",pause:bool=true)->VBoxContainer:
	if not modal_layer.visible:
		previous_speed=sim.speed
		if pause: sim.speed=0
	for child in modal_panel.get_children(): modal_panel.remove_child(child); child.queue_free()
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); modal_panel.add_child(box); box.add_child(label(title,25,MINT))
	if subtitle!="":
		var desc:=label(subtitle,14); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; desc.custom_minimum_size.x=560; box.add_child(desc)
	modal_layer.show(); return box
func close_modal()->void: modal_layer.hide(); sim.speed=previous_speed; refresh_hud()
func close_button(box:Node)->void: button("Voltar ao bairro",close_modal,box)
func show_start()->void:
	var box:=open_modal("Uma vida começa aqui.","MINHA VIDA — HISTÓRIAS DA CIDADE\nBase jogável · Bairro Ipê, Vila Aurora")
	box.add_child(label("Uma casa simples. Dois vizinhos. Muitas pequenas histórias."))
	button("Criar meu personagem",show_creator,box)
	button("Continuar jogo salvo",load_now,box).disabled=not FileAccess.file_exists(SaveStore.FILE) and not FileAccess.file_exists(SaveStore.FILE+".bak")
	box.add_child(label("Arte procedural original provisória · versão reconstruída 0.1.1",12))
	button("Sair",quit_game,box)
func option(title:String,values:Array,parent:Node,index:int=0)->OptionButton:
	var row:=HBoxContainer.new(); parent.add_child(row); var l:=label(title); l.custom_minimum_size.x=180; row.add_child(l)
	var opt:=OptionButton.new(); opt.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for value in values: opt.add_item(value)
	opt.select(index); row.add_child(opt); return opt
func show_creator()->void:
	var box:=open_modal("Quem vai morar aqui?","Você começa com V$ 320, seis marmitas e uma casa cedida.\nA carreira inicial é barista. Moradia e outras carreiras: próximas etapas.")
	var name_field:=LineEdit.new(); name_field.text="Alex"; name_field.max_length=26; box.add_child(name_field)
	var skin_opt:=option("Tom de pele",["Claro","Médio","Escuro","Retinto"],box,1); var hair_opt:=option("Cor do cabelo",["Castanho escuro","Castanho","Loiro","Grisalho"],box); var clothes:=option("Roupa",["Verde água","Terracota","Lavanda","Mostarda"],box)
	var pro:=option("Pronomes",["elu/delu","ela/dela","ele/dele"],box); var trait_opt:=option("Traço",["Criativo","Sociável","Tímido"],box)
	box.add_child(label("Criativo: aprende leitura mais rápido. Tímido: conversar cansa.\nSociável: recupera a necessidade social mais rápido.",12))
	button("Começar minha história",func():
		sim.player_name=name_field.text.strip_edges() if not name_field.text.strip_edges().is_empty() else "Alex"
		sim.skin=skin_opt.selected; sim.hair=hair_opt.selected; sim.outfit=clothes.selected; sim.pronouns=pro.get_item_text(pro.selected); sim.personality_trait=trait_opt.get_item_text(trait_opt.selected)
		started=true; previous_speed=1; close_modal(); transition(); show_tutorial(),box)
	button("Voltar",show_start,box)
func show_tutorial()->void:
	var box:=open_modal("Seu primeiro dia no Bairro Ipê","1. Clique na casa e escolha Entrar. O telhado desaparece.\n2. Clique nos móveis para comer, dormir, ler e cuidar de si.\n3. Converse com vizinhos ou toque a campainha da Bia.\n4. Às 09:00, decida se vai ao trabalho. O transporte é automático.\n5. Há salvamento automático a cada 3 horas do jogo.")
	box.add_child(label("Mouse: andar e interagir · roda: zoom · botão do meio: mover câmera\nWASD: andar · C: seguir · Espaço: pausa · 1/2/3: tempo\nX: cancelar · F5: salvar · F9: carregar · M: destinos · F3: depuração",13)); close_button(box)
func show_menu()->void:
	var box:=open_modal("Uma pausa na rotina")
	button("Continuar",close_modal,box); button("Salvar jogo",save_now,box); button("Carregar jogo",load_now,box); button("Configurações",show_settings,box); button("Ajuda e controles",show_tutorial,box)
	button("Novo jogo…",func():
		var confirm:=open_modal("Começar outra história?","O progresso não salvo será descartado. O save só será substituído ao salvar.")
		button("Sim, criar novo personagem",func():
			sim=LifeSimulation.new(); world.sim=sim; sim.notice.connect(log_message); sim.shift_requested.connect(show_shift); started=false; show_creator(),confirm)
		button("Voltar",show_menu,confirm),box)
	button("Sair",quit_game,box)
func show_settings()->void:
	var box:=open_modal("Seu jeito de jogar")
	var auto:=CheckButton.new(); auto.text="Autonomia para necessidades baixas"; auto.button_pressed=sim.autonomous; box.add_child(auto); auto.toggled.connect(func(v): sim.autonomous=v)
	var auto_job:=CheckButton.new(); auto_job.text="Aceitar próximos expedientes automaticamente"; auto_job.button_pressed=sim.auto_work; box.add_child(auto_job); auto_job.toggled.connect(func(v): sim.auto_work=v)
	var rate:=option("Necessidades",["Suaves · 0,5×","Padrão · 1×","Intensas · 1,5×"],box,int(sim.need_rate*2)-1); rate.item_selected.connect(func(i): sim.need_rate=(i+1)*0.5)
	var font_opt:=option("Texto da interface",["Padrão","Grande"],box,int(sim.ui_large)); font_opt.item_selected.connect(func(i): sim.ui_large=i==1; apply_preferences())
	box.add_child(label("Volume da música original",14)); var volume:=HSlider.new(); volume.custom_minimum_size.y=25; volume.min_value=-50; volume.max_value=-8; volume.value=sim.audio_volume; box.add_child(volume); volume.value_changed.connect(func(v): sim.audio_volume=v; music.volume_db=v)
	var mute:=CheckButton.new(); mute.text="Silenciar música"; mute.button_pressed=sim.audio_muted; box.add_child(mute); mute.toggled.connect(func(v): sim.audio_muted=v; music.stream_paused=v)
	close_button(box)
func show_shift()->void:
	var box:=open_modal("Está na hora de trabalhar.\nIr para o trabalho?","Café da Esquina · Barista · 09:00–13:00\nVocê será transportado ao Café. A atividade atual será cancelada.",false)
	for i in range(3):
		button(["Ir agora","Adiar 15 minutos","Faltar hoje"][i],func():
			modal_layer.hide(); sim.speed=maxi(1,previous_speed); sim.answer_shift(i)
			if i==0: transition(),box)
func show_job()->void:
	var box:=open_modal("Trabalho e finanças","Barista · Café da Esquina\nSegunda a sexta · 09:00–13:00 · V$ 120 por turno integral\nAtrasos descontam proporcionalmente; faltas reduzem o desempenho.\nDesempenho: %d/100. Promoções ainda não implementadas."%int(sim.performance))
	if sim.working:
		var posture:=option("Postura",["Trabalhar normalmente","Esforçar-se","Pegar leve"],box,sim.work_style); posture.item_selected.connect(func(i): sim.work_style=i)
		box.add_child(label("Esforço: mais desempenho e cansaço. Pegar leve: menos cansaço.",12))
	var text:="SALDO PESSOAL · V$ %d\n"%sim.money
	for tx in sim.ledger.slice(0,7): text+="\n%sV$ %d · %s"%["+" if tx.amount>=0 else "",tx.amount,tx.reason]
	box.add_child(label(text,14)); close_button(box)
func show_inventory()->void:
	var box:=open_modal(sim.player_name+" · "+sim.pronouns,"Traço: %s\nAspiração: %s\nRua Ipê, 12 · casa cedida\n\nGeladeira: %d marmitas prontas, sem validade nesta versão.\nCriatividade: %.1f · Carisma: %.1f\n\nUse a geladeira para comer. Quando acabar, visite o Café\naberto das 08:00 às 18:00. Não há compras remotas."%[sim.personality_trait,sim.aspiration,sim.food,sim.skills.criatividade,sim.skills.carisma]); close_button(box)
func show_people()->void:
	var box:=open_modal("Gente do bairro","Bia aceita visitas entre 08:00 e 21:00 quando está em casa\ne a amizade é suficiente. Romance ainda não implementado.")
	for npc in sim.npcs:
		box.add_child(label(npc.name+" · "+npc.job+" · "+npc.state+" · Amizade "+str(int(sim.friendship if npc.id=="bia" else sim.relationships.get(npc.id,0))),14))
		button("Encontrar e conversar",func(): close_modal(); sim.enqueue_social(npc.id),box)
	button("Visitar Bia · tocar campainha",func(): close_modal(); sim.ring_bell(),box); close_button(box)
func show_map()->void:
	var box:=open_modal("Bairro Ipê · Vila Aurora","Escolha um destino: o personagem caminha por uma rota válida.")
	for entry in [{"name":"Sua casa · Rua Ipê, 12","cell":Vector2i(7,10)},{"name":"Bia · Rua Ipê, 18 (campainha)","cell":Vector2i(19,10)},{"name":"Praça das Flores","cell":Vector2i(8,20)},{"name":"Café da Esquina · 08:00–18:00","cell":Vector2i(23,24)}]:
		button(entry.name,func(): close_modal(); sim.enqueue_move(entry.cell); follow(),box)
	box.add_child(label("Outros bairros, imobiliária, supermercado e lojas: etapas futuras.",12)); close_button(box)
func save_now()->void:
	var speed_now:=sim.speed
	if modal_layer.visible: sim.speed=previous_speed
	var error:=SaveStore.save_game(sim); sim.speed=speed_now
	log_message("Jogo salvo. Cópia anterior preservada." if error==OK else "Falha ao salvar: "+error_string(error))
func load_now()->void:
	if SaveStore.load_game(sim):
		started=true; modal_layer.hide(); apply_preferences(); follow(); transition(); log_message("História carregada.")
		if sim.shift_prompt: show_shift()
	else: log_message("Nenhum save válido, inclusive na cópia de recuperação.")
func apply_preferences()->void:
	root.theme.default_font_size=18 if sim.ui_large else 15; scale_labels(root,1.15 if sim.ui_large else 1.0); music.volume_db=sim.audio_volume; music.stream_paused=sim.audio_muted
func scale_labels(node:Node,factor:float)->void:
	if node is Label and node.has_meta("base_font_size"): node.add_theme_font_size_override("font_size",int(node.get_meta("base_font_size")*factor))
	for child in node.get_children(): scale_labels(child,factor)
func quit_game()->void:
	music.stop(); await get_tree().create_timer(0.1).timeout; get_tree().quit()
func _exit_tree()->void:
	if is_instance_valid(music): music.stop(); music.stream=null
