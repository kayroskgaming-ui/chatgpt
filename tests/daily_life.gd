extends SceneTree
var checks:=0
var failures:=0
func check(value:bool,message:String)->void:
	checks+=1
	if value: print("PASS COTIDIANO · "+message)
	else: failures+=1; printerr("FAIL COTIDIANO · "+message)
func _init()->void: call_deferred("run")
func quiet()->LifeSimulation:
	var s:=LifeSimulation.new(); s.minutes=900; s.npcs=[]; return s
func idle(s:LifeSimulation)->void:
	for i in range(4000):
		s.tick(.1)
		if s.current.is_empty() and s.queue.is_empty(): return
	check(false,"Ação deve terminar")
func run()->void:
	var s:=quiet(); s.cell=Vector2i(3,11); s.enqueue_move(Vector2i(10,11)); var start:=s.minutes; idle(s)
	check(s.cell==Vector2i(10,11) and s.minutes-start<2.5,"Sete células em menos de 1,25 s a 1×")
	check(s.minutes-start>1.0,"Velocidade tem duração, sem teletransporte")
	s=quiet(); var at:=s.cell; var accepted:=0
	for i in range(100):
		if s.manual_step(Vector2i.RIGHT): accepted+=1
	check(accepted==1 and s.cell==at+Vector2i.RIGHT,"Movimento direto não depende da taxa de frames")
	s.tick(.2); check(s.manual_step(Vector2i.RIGHT),"Analógico contínuo pode dar o próximo passo")
	s.cell=Vector2i(7,6); s.direct_cooldown=0
	check(not s.manual_step(Vector2i(1,-1)),"Diagonal não corta o canto de uma parede")
	var reachable:=true
	for object in CityData.OBJECTS:
		var actor:String="player" if object.home in ["home",""] else ("caio" if object.home=="caio" else "bia")
		var origin:=Vector2i(7,11)
		if actor=="bia": origin=Vector2i(19,10)
		elif actor=="caio": origin=Vector2i(33,10)
		var found:=false
		for use in CityData.use_points(object,actor,true):
			if not CityData.path(origin,use,actor,true).is_empty(): found=true
		reachable=reachable and found
	check(reachable,"Todos os móveis têm ponto de uso alcançável pela porta")
	check(CityData.room_at(Vector2i(4,5))=="Quarto" and CityData.room_at(Vector2i(9,7))=="Banheiro","Casa possui ambientes distintos")
	for wall in CityData.INNER_WALLS:
		check(not CityData.walkable(wall),"Divisória sólida: "+str(wall))
	for door in CityData.INNER_DOORS:
		check(CityData.walkable(door),"Passagem interna livre: "+str(door))
	s=LifeSimulation.new(); s.minutes=900
	var bia:Dictionary=s.npcs[0]; bia.cell=Vector2i(20,4); bia.needs[0]=5.0
	for i in range(180): s.tick(.1)
	check(bia.needs[0]>45 and bia.meals==3,"Bia procura comida, consome estoque e recupera fome")
	bia.needs[2]=5.0; s.npc_system.release(s,bia); bia.decision_in=0
	for i in range(300): s.tick(.1)
	check(bia.needs[2]>55,"Vizinha procura e usa chuveiro")
	bia.needs[3]=5.0; s.npc_system.release(s,bia); bia.decision_in=0
	for i in range(230): s.tick(.1)
	check(bia.needs[3]>50,"Vizinha usa banheiro")
	s.minutes=1330; bia.needs[1]=5.0; s.npc_system.release(s,bia); bia.decision_in=0
	for i in range(800): s.tick(.1)
	check(bia.needs[1]>60,"Vizinha dorme para recuperar energia")
	var simulated:=LifeSimulation.new(); simulated.minutes=1320; simulated.auto_work=true; simulated.speed=3
	var safe:=true; var activities:={}
	for i in range(1200):
		var before:={}
		for npc in simulated.npcs: before[npc.id]=npc.cell
		simulated.tick(.04)
		for npc in simulated.npcs:
			activities[npc.state]=true
			safe=safe and CityData.walkable(npc.cell,npc.id) and Vector2(npc.cell-before[npc.id]).length()<=1.01 and npc.cell!=simulated.cell
	check(safe,"NPCs se deslocam sem atravessar paredes, móveis ou jogador")
	check(activities.has("Dormindo"),"Rotina noturna inclui dormir")
	var neighbors:=LifeSimulation.new(); neighbors.minutes=1000
	neighbors.npcs[0].cell=Vector2i(10,20); neighbors.npcs[1].cell=Vector2i(10,21)
	for npc in neighbors.npcs: npc.needs[4]=5.0; npc.route=[]; npc.action={}; npc.decision_in=0
	for i in range(80): neighbors.tick(.1)
	check(neighbors.npcs[0].needs[4]>15 and neighbors.npcs[1].needs[4]>15,"Vizinhos procuram conversa entre si quando solitários")
	var reserved:=LifeSimulation.new(); reserved.minutes=1330; var n:Dictionary=reserved.npcs[0]; n.needs[1]=0.0; reserved.tick(.1)
	check(reserved.reservations.get("bia_bed","")=="bia","NPC reserva a própria cama")
	reserved.cancel_all(); check(reserved.reservations.get("bia_bed","")=="bia","Cancelar jogador preserva reservas dos NPCs")
	reserved.invited=true; reserved.enqueue_object("bia_bed"); idle(reserved)
	check(reserved.current.is_empty() and reserved.reservations.get("bia_bed","")=="bia","Jogador não usa móvel ocupado por NPC")
	var exit_worker:=LifeSimulation.new(); exit_worker.minutes=540; exit_worker.start_work(); exit_worker.npcs[0].cell=Vector2i(23,24); exit_worker.minutes=780; exit_worker.finish_work()
	check(exit_worker.cell!=exit_worker.npcs[0].cell,"Fim do expediente escolhe uma saída sem sobrepor morador")
	var f:="user://test_npc_v2.json"; SaveStore.save_game(reserved,f)
	var loaded:=LifeSimulation.new(); check(SaveStore.load_game(loaded,f),"Save v2 de vizinho em atividade pode carregar")
	check(loaded.npcs[0].action.id=="bia_bed" and loaded.reservations.get("bia_bed")=="bia","Atividade, estoque e reserva de NPC persistem")
	loaded.tick(20); check(loaded.npcs[0].needs[1]>reserved.npcs[0].needs[1],"Atividade do NPC continua após carregar")
	# Build a v1 fixture using the schema that was shipped in 0.1.1.
	var legacy:=JSON.new(); legacy.parse(FileAccess.get_file_as_string(f)); legacy.data.version=1; legacy.data.erase("facing"); legacy.data.erase("visit_until")
	for npc in legacy.data.npcs:
		for key in ["needs","route","action","move_elapsed","wait","decision_in","meals","money","facing","home","last_goal"]: npc.erase(key)
	var old:=FileAccess.open("user://test_legacy.json",FileAccess.WRITE); old.store_string(JSON.stringify(legacy.data)); old.close()
	var migrated:=LifeSimulation.new(); check(SaveStore.load_game(migrated,"user://test_legacy.json") and migrated.money==reserved.money and migrated.player_name==reserved.player_name,"Save v1 mantém personagem e dinheiro")
	check(migrated.npcs[0].has("needs") and migrated.npcs[0].has("action"),"Migração inicializa novas rotinas sem duplicar moradores")
	legacy.data.cell=SaveStore.encode(Vector2i(9,5)); legacy.data.route=SaveStore.encode([Vector2i(9,5)])
	legacy.data.current={"kind":"object","id":"fridge","name":"Comer uma marmita","remaining":10.0,"cost":0,"arrived":true}; legacy.data.food=5
	old=FileAccess.open("user://test_migrate_route.json",FileAccess.WRITE); old.store_string(JSON.stringify(legacy.data)); old.close()
	var rerouted:=LifeSimulation.new()
	check(SaveStore.load_game(rerouted,"user://test_migrate_route.json") and CityData.walkable(rerouted.cell,"player",rerouted.invited) and not rerouted.route.is_empty(),"Save antigo é reposicionado e ganha rota válida nas novas divisórias")
	idle(rerouted); check(rerouted.food==5 and rerouted.current.is_empty(),"Replanejar refeição antiga não consome comida novamente")
	# Play a day with real routes, essential furniture, a visit and the work prompt.
	for rate in [1,2,3]:
		var day_sim:=LifeSimulation.new(); day_sim.speed=rate
		day_sim.enqueue_object("fridge"); day_sim.enqueue_object("shower"); day_sim.enqueue_object("toilet"); day_sim.enqueue_move(Vector2i(7,11)); day_sim.ring_bell()
		var events:=0; var day_start:=day_sim.minutes; var itinerary_done:=false
		for i in range(20000):
			day_sim.tick(.1)
			if day_sim.shift_prompt: events+=1; day_sim.answer_shift(0)
			if day_sim.current.is_empty() and day_sim.queue.is_empty() and day_sim.minutes<540: itinerary_done=true
			if day_sim.minutes>=day_start+1440: break
		check(day_sim.minutes>=day_start+1440 and events==1 and day_sim.paid_days.size()==1 and day_sim.money==440,"Dia completo %d×: exploração, aviso e salário único"%rate)
		check(day_sim.food==5 and day_sim.current.is_empty() and itinerary_done,"Dia %d×: comer, higiene, banheiro e visita sem fila presa"%rate)
		var valid_needs:=true
		for npc in day_sim.npcs:
			for need in npc.needs: valid_needs=valid_needs and need>=0 and need<=100
		check(valid_needs,"Dia %d×: necessidades dos vizinhos permanecem válidas"%rate)
	for name in [f,"user://test_legacy.json","user://test_migrate_route.json"]:
		for suffix in ["",".bak"]:
			if FileAccess.file_exists(name+suffix): DirAccess.remove_absolute(name+suffix)
	print("RESULTADO COTIDIANO: %d verificações, %d falhas"%[checks,failures]); quit(1 if failures else 0)
