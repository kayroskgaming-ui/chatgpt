extends SceneTree
var total:=0
var failed:=0
func check(value:bool,message:String)->void:
	total+=1
	if value: print("PASS · "+message)
	else: failed+=1; printerr("FAIL · "+message)
func idle(s:LifeSimulation)->void:
	for i in range(6000):
		s.tick(0.1)
		if s.current.is_empty() and s.queue.is_empty(): return
	check(false,"Fila deve terminar")
func peaceful()->LifeSimulation:
	var s:=LifeSimulation.new(); s.minutes=900; s.npcs=[]; return s
func _init()->void: call_deferred("run")
func run()->void:
	var s:=peaceful()
	check(not CityData.path(s.cell,Vector2i(7,8)).is_empty(),"Entrada da casa acessível")
	check(CityData.path(s.cell,Vector2i(19,7)).is_empty(),"Vizinha bloqueada sem convite")
	check(not CityData.path(s.cell,Vector2i(19,7),"player",true).is_empty(),"Convite autoriza entrada")
	check(not CityData.walkable(Vector2i(3,5)),"Parede sólida")
	check(not CityData.walkable(Vector2i(4,4)),"Móvel sólido")
	var path:=CityData.path(Vector2i(7,11),Vector2i(7,4)); var previous:=Vector2i(7,11); var valid:=true
	for at in path:
		valid=valid and CityData.walkable(at) and absi(at.x-previous.x)+absi(at.y-previous.y)==1; previous=at
	check(valid and not path.is_empty(),"Rota adjacente sem atravessar obstáculos")
	s.needs[1]=10.0; s.enqueue_object("bed"); idle(s)
	check(s.needs[1]>65,"Dormir recupera energia")
	s.enqueue_move(Vector2i(7,8)); idle(s)
	check(s.cell==Vector2i(7,8),"Levantar permite caminhar")
	var food:=s.food; s.needs[0]=15.0; s.enqueue_object("fridge"); idle(s)
	check(s.food==food-1 and s.needs[0]>50,"Comer consome uma marmita")
	for pair in [["shower",2],["toilet",3],["sofa",5]]:
		s.needs[pair[1]]=10.0; s.enqueue_object(pair[0]); idle(s); check(s.needs[pair[1]]>35,"Objeto funcional: "+pair[0])
	s.enqueue_move(Vector2i(4,4)); s.enqueue_object("table"); idle(s)
	check(s.current.is_empty() and s.queue.is_empty(),"Falha libera fila e permite próxima ação")
	s.food=0; s.enqueue_object("fridge"); idle(s)
	check(s.food==0 and s.current.is_empty(),"Sem alimento não há estoque negativo")
	s.enqueue_object("bed"); s.tick(.1); s.cancel_all()
	check(s.current.is_empty() and s.route.is_empty() and s.reservations.is_empty(),"Cancelar libera reservas")
	s.minutes=900; s.cell=Vector2i(24,19); var money:=s.money; var count:=s.ledger.size(); s.enqueue_object("counter"); idle(s)
	check(s.money==money-12 and s.ledger.size()==count+1,"Lanche cobra V$ 12 uma vez")
	s.money=0; s.enqueue_object("counter"); idle(s); check(s.money==0,"Sem saldo não compra")
	s.minutes=1200; s.money=320; s.enqueue_object("counter"); idle(s); check(s.money==320,"Loja fechada não vende")
	var social:=LifeSimulation.new(); social.minutes=490; social.cell=Vector2i(19,10); social.ring_bell(); idle(social)
	check(social.invited,"Vizinha em casa aceita visita")
	social.invited=false; social.friendship=0; social.ring_bell(); idle(social); check(not social.invited,"Vizinha pode recusar")
	social.minutes=1100; social.cell=Vector2i(18,7); social.npcs[0].cell=Vector2i(19,7); var before:=social.friendship; social.enqueue_social("bia"); idle(social)
	check(social.friendship>before,"Conversa melhora amizade")
	var worker:=LifeSimulation.new(); worker.minutes=509; worker.speed=3; worker.tick(20)
	check(worker.shift_prompt and worker.minutes>=540 and worker.minutes<542,"3× não perde aviso de turno")
	worker.answer_shift(1); worker.tick(2); check(not worker.shift_prompt,"Adiar não reabre imediatamente")
	worker.tick(1); check(worker.shift_prompt,"Adiamento dura 15 minutos")
	worker.answer_shift(0); check(worker.working and CityData.building_at(worker.cell)=="cafe","Transporte ao trabalho")
	worker.tick(60); var salary:=worker.money
	check(worker.paid_days.size()==1 and worker.ledger.size()==1 and not worker.working,"Turno termina e paga uma vez")
	worker.tick(15); check(worker.money==salary and worker.ledger.size()==1,"Acelerar não duplica salário")
	var absent:=LifeSimulation.new(); absent.minutes=540; absent.tick(.1); absent.answer_shift(2); absent.tick(200)
	check(absent.money==320 and absent.paid_days.is_empty(),"Falta sem pagamento")
	var full:=LifeSimulation.new(); full.auto_work=true; full.speed=3; full.tick(240)
	check(full.minutes>=1890 and full.paid_days.size()==1 and full.money==440,"Um dia completo em 3×")
	var file:="user://test_vida.json"; worker.cell=Vector2i(7,8); worker.enqueue_object("bed"); worker.tick(.1)
	check(SaveStore.save_game(worker,file)==OK,"Save atômico")
	var loaded:=LifeSimulation.new(); check(SaveStore.load_game(loaded,file),"Carregar save")
	check(loaded.money==worker.money and is_equal_approx(loaded.minutes,worker.minutes) and loaded.cell==worker.cell and loaded.queue==worker.queue and loaded.current==worker.current and loaded.route==worker.route,"Preservar estado, fila e rota")
	check(loaded.paid_days==worker.paid_days and loaded.ledger==worker.ledger,"Histórico financeiro persistente")
	check(SaveStore.save_game(worker,file)==OK and FileAccess.file_exists(file+".bak"),"Cópia anterior preservada")
	var f:=FileAccess.open(file,FileAccess.WRITE); f.store_string("{interrompido"); f.close(); check(SaveStore.load_game(loaded,file),"Recuperação de save corrompido")
	var shift:=LifeSimulation.new(); shift.minutes=540; shift.start_work(); shift.tick(20); SaveStore.save_game(shift,"user://test_shift.json")
	var resumed:=LifeSimulation.new(); SaveStore.load_game(resumed,"user://test_shift.json"); resumed.tick(150)
	check(resumed.money==440 and resumed.paid_days.size()==1,"Carregar turno não duplica salário")
	var eating:=peaceful(); eating.cell=Vector2i(8,4); eating.enqueue_object("fridge"); eating.tick(1); SaveStore.save_game(eating,"user://test_food.json")
	var reloaded:=peaceful(); SaveStore.load_game(reloaded,"user://test_food.json"); idle(reloaded); check(reloaded.food==5,"Carregar refeição não consome outro item")
	var json:=JSON.new(); json.parse(FileAccess.get_file_as_string(file+".bak")); json.data.skin=99
	f=FileAccess.open("user://test_bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(json.data)); f.close(); check(not SaveStore.load_game(loaded,"user://test_bad.json"),"Save com aparência inválida rejeitado")
	var shy:=peaceful(); shy.personality_trait="Tímido"; shy.cell=Vector2i(13,16); shy.npcs=[{"id":"caio","name":"Caio","cell":Vector2i(13,17),"job":"Barista","state":"Na praça"}]
	var sociable:=peaceful(); sociable.personality_trait="Sociável"; sociable.cell=shy.cell; sociable.npcs=shy.npcs.duplicate(true)
	shy.needs[4]=20.0; sociable.needs[4]=20.0; shy.enqueue_social("caio"); sociable.enqueue_social("caio"); idle(shy); idle(sociable)
	check(shy.needs[1]<sociable.needs[1] and shy.needs[4]<sociable.needs[4],"Traços afetam necessidades")
	check(sociable.relationships.caio>0 and sociable.friendship==15,"Amizades separadas")
	for name in ["test_vida.json","test_shift.json","test_food.json","test_bad.json"]:
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists("user://"+name+suffix): DirAccess.remove_absolute("user://"+name+suffix)
	print("RESULTADO: %d verificações, %d falhas"%[total,failed]); quit(1 if failed>0 else 0)
