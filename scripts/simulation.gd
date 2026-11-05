class_name LifeSimulation
extends RefCounted
signal changed
signal notice(message:String)
signal shift_requested
const NEED_NAMES=["Fome","Energia","Higiene","Bexiga","Social","Diversão"]
const DECAY=[0.023,0.018,0.015,0.035,0.012,0.014]
var minutes:=450.0
var speed:=1
var needs:Array=[78.0,82.0,90.0,85.0,68.0,75.0]
var money:=320
var food:=6
var player_name:="Alex"
var skin:=1
var hair:=0
var outfit:=0
var pronouns:="elu/delu"
var personality_trait:="Criativo"
var aspiration:="Construir uma vida acolhedora"
var skills:={"criatividade":0.0,"carisma":0.0}
var cell:=Vector2i(7,11)
var queue:Array=[]
var current:Dictionary={}
var route:Array[Vector2i]=[]
const WALK_MINUTES=0.28 # 0.14 real seconds per tile at 1×.
var step_elapsed:=0.0
var direct_cooldown:=0.0
var facing:=Vector2i.DOWN
var visit_until:=-1.0
var npc_system:=NeighborhoodSimulation.new()
var autonomous:=false
var need_rate:=1.0
var invited:=false
var friendship:=15.0
var relationships:={"caio":0.0}
var npcs:Array=[]
var npc_tick:=0.0
var ledger:Array=[]
var shift_prompt:=false
var shift_day:=-1
var warned_day:=-1
var paid_days:Array=[]
var skipped_days:Array=[]
var deferred_until:=-1.0
var working:=false
var work_end:=0.0
var work_style:=0
var auto_work:=false
var performance:=50.0
var mood_cause:="Um novo começo em Vila Aurora"
var mood_until:=540.0
var autosave_at:=450.0
var reservations:={}
var ui_large:=false
var audio_volume:=-24.0
var audio_muted:=false
func _init()->void:
	npcs=[{"id":"bia","name":"Bia Nascimento","cell":Vector2i(19,7),"job":"Florista","state":"Em casa"},{"id":"caio","name":"Caio Alves","cell":Vector2i(12,15),"job":"Barista","state":"Na praça"}]
	npc_system.ensure_state(self)
func day()->int: return int(minutes/1440.0)
func hour_minute()->int: return int(minutes)%1440
func clock()->String: return "%02d:%02d"%[hour_minute()/60,hour_minute()%60]
func comfort()->int:
	if current.get("id","") in ["bed","sofa"] and current.get("arrived",false): return 85
	return 65 if CityData.building_at(cell)=="home" else 50
func mood()->String:
	if working and work_style==1: return "Estressado"
	if needs.min()<15: return "Exausto" if needs[1]<15 else "Desconfortável"
	if needs[4]<25: return "Solitário"
	if minutes<mood_until: return "Inspirado" if personality_trait=="Criativo" else "Confiante"
	var average:=0.0
	for n in needs: average+=n/6.0
	return "Feliz" if average+(comfort()-50)/3.0>65 else "Tranquilo"
func add_transaction(amount:int,reason:String)->void:
	money+=amount
	ledger.push_front({"minute":minutes,"amount":amount,"reason":reason})
	if ledger.size()>80: ledger.resize(80)
	notice.emit(("+" if amount>=0 else "")+"V$ %d · %s"%[amount,reason])
func tick(seconds:float)->void:
	if speed==0 or shift_prompt: return
	var remaining:=seconds*float(speed)*2.0
	while remaining>0.00001 and not shift_prompt:
		var delta:=minf(1.0,remaining)
		advance_minute(delta); remaining-=delta
func advance_minute(delta:float)->void:
	minutes+=delta
	direct_cooldown=maxf(0,direct_cooldown-delta)
	if invited and visit_until>=0 and minutes>=visit_until and CityData.building_at(cell)!="bia": invited=false
	for i in range(6):
		var rate:float=DECAY[i]*need_rate
		if working and i==1: rate*=[1.6,2.8,0.8][work_style]
		needs[i]=clampf(float(needs[i])-delta*rate,0,100)
	check_shift()
	if shift_prompt: changed.emit(); return
	if working:
		if minutes>=work_end: finish_work()
	else:
		advance_actions(delta)
		if autonomous and current.is_empty() and queue.is_empty(): choose_autonomy()
	npc_system.tick(self,delta)
	changed.emit()
func check_shift()->void:
	var d:=day(); var hm:=hour_minute()
	if d%7>=5: return
	if hm>=510 and hm<540 and warned_day!=d:
		warned_day=d; notice.emit("Seu turno começa às 09:00. Salário base: V$ 120.")
	if hm>=540 and hm<780 and shift_day!=d and d not in skipped_days and d not in paid_days:
		if deferred_until>minutes: return
		shift_day=d
		if auto_work: start_work()
		else: shift_prompt=true; shift_requested.emit()
func answer_shift(choice:int)->void:
	shift_prompt=false
	if choice==0: start_work()
	elif choice==1:
		deferred_until=minutes+15; shift_day=-1
		notice.emit("Turno adiado por 15 minutos. O atraso reduz o pagamento.")
	else:
		skipped_days.append(day()); performance=maxf(0,performance-12)
		notice.emit("Falta registrada. Desempenho −12; nenhum salário hoje.")
	changed.emit()
func start_work()->void:
	cancel_all(); shift_prompt=false; shift_day=day(); working=true
	for at in [Vector2i(24,20),Vector2i(23,20),Vector2i(24,22)]:
		if not occupied(at): cell=at; break
	work_end=day()*1440.0+780.0
	current={"name":"Expediente · Café da Esquina","kind":"work","started":minutes}
	notice.emit("Você chegou ao Café. O turno termina às 13:00.")
func finish_work()->void:
	var d:=int(work_end/1440.0)
	if d not in paid_days:
		paid_days.append(d)
		var served:=clampf((work_end-float(current.get("started",work_end)))/240.0,0,1)
		add_transaction(int(round(120*served)),"Salário de barista · dia %d"%[d+1])
		performance=clampf(performance+[4,9,1][work_style],0,100)
		mood_cause="Expediente concluído; pagamento registrado"; mood_until=minutes+120
	working=false; current={}
	for at in [Vector2i(23,24),Vector2i(22,24),Vector2i(24,24)]:
		if not occupied(at): cell=at; break
	notice.emit("Turno concluído! Volte para casa ou explore o bairro.")
func enqueue_move(target:Vector2i)->void:
	if working: notice.emit("Aguarde o fim do expediente."); return
	queue.append({"kind":"move","name":"Caminhar","target":target}); changed.emit()
func enqueue_object(id:String)->void:
	if working: return
	var o:=CityData.object_by_id(id)
	if not o.is_empty(): queue.append({"kind":"object","id":id,"name":o.action}); changed.emit()
func enqueue_social(id:String,action:String="Conversar")->void:
	if not working: queue.append({"kind":"social","id":id,"name":action}); changed.emit()
func ring_bell()->void:
	if not working: queue.append({"kind":"bell","name":"Tocar campainha","target":Vector2i(19,10)}); changed.emit()
func cancel_all()->void:
	if working: return
	if not current.is_empty() and reservations.get(current.get("id",""))=="player": reservations.erase(current.id)
	current={}; queue.clear(); route.clear(); changed.emit()
func cancel_index(index:int)->void:
	if index>=0 and index<queue.size(): queue.remove_at(index); changed.emit()
func occupied(at:Vector2i,except_id:String="player")->bool:
	if except_id!="player" and at==cell: return true
	for npc in npcs:
		if npc.id!=except_id and npc.cell==at: return true
	return false
func nearest_use(target:Vector2i)->Vector2i:
	var object:Dictionary={}
	for o in CityData.OBJECTS:
		if o.cell==target: object=o; break
	var candidates:Array[Vector2i]=[]
	if not object.is_empty(): candidates=CityData.use_points(object,"player",invited)
	else:
		for dir in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP]:
			var candidate:Vector2i=target+dir
			if CityData.walkable(candidate,"player",invited): candidates.append(candidate)
	var best:=Vector2i(-1,-1); var shortest:=9999
	for at in candidates:
		if occupied(at): continue
		if at==cell: return cell
		var path:=CityData.path(cell,at,"player",invited)
		if not path.is_empty() and path.size()<shortest: best=at; shortest=path.size()
	return best
func fail_action(message:String)->void:
	if reservations.get(current.get("id",""))=="player": reservations.erase(current.id)
	current={}; route.clear(); notice.emit(message)
func begin_next()->void:
	if queue.is_empty(): return
	current=queue.pop_front(); current["remaining"]=0.0
	var target:Vector2i=current.get("target",cell)
	if current.kind=="object":
		var o:=CityData.object_by_id(current.id)
		if not CityData.can_enter(o.home,"player",invited): fail_action("Peça permissão antes de entrar."); return
		if reservations.has(o.id): fail_action("Objeto ocupado."); return
		if o.id=="fridge" and food<=0: fail_action("Sem marmitas. Compre um lanche no Café."); return
		if o.home=="cafe" and (hour_minute()<480 or hour_minute()>=1080): fail_action("O Café abre das 08:00 às 18:00."); return
		if money<o.cost: fail_action("Saldo insuficiente."); return
		current["cost"]=o.cost; current["remaining"]=o.minutes
		target=nearest_use(o.cell)
		if target.x<0: fail_action("Não foi possível chegar ao móvel. A fila foi liberada."); return
		reservations[o.id]="player"
		current["use_cell"]=target
	elif current.kind=="social":
		var npc:=npc_by_id(current.id)
		if npc.is_empty(): fail_action("Pessoa não encontrada."); return
		if npc.get("state","")=="Dormindo": fail_action("Essa pessoa está dormindo. Volte mais tarde."); return
		npc_system.release(self,npc)
		target=nearest_use(npc.cell); current["remaining"]=20.0
		if target.x<0: fail_action("Essa pessoa não está acessível agora."); return
	if target!=cell:
		route=CityData.path(cell,target,"player",invited)
		if route.is_empty(): fail_action("Caminho bloqueado ou entrada sem autorização."); return
	current["arrived"]=false
	current["committed"]=false
	step_elapsed=WALK_MINUTES # Start responding on the first simulation tick.
func advance_actions(delta:float)->void:
	if current.is_empty(): begin_next()
	if current.is_empty(): return
	if not route.is_empty():
		step_elapsed+=delta
		var duration:=WALK_MINUTES*(1.35 if needs[1]<20 else 1.0)
		while step_elapsed>=duration and not route.is_empty():
			if occupied(route[0]):
				current["waiting"]=float(current.get("waiting",0.0))+delta
				if current.waiting>6: fail_action("Uma pessoa bloqueou a passagem. A fila foi liberada.")
				return
			current["waiting"]=0.0
			step_elapsed-=duration
			var next:Vector2i=route.pop_front(); facing=next-cell; cell=next
		return
	if not current.get("arrived",false):
		current["arrived"]=true
		if current.kind=="object":
			var active:=CityData.object_by_id(current.id)
			facing=active.cell-cell
		if current.kind=="object":
			if not current.get("committed",false):
				if current.id=="fridge": food-=1
				if current.cost>0: add_transaction(-int(current.cost),current.name)
				current["committed"]=true
	if current.kind=="object":
		var o:=CityData.object_by_id(current.id)
		needs[o.need]=clampf(needs[o.need]+o.gain*delta/o.minutes,0,100)
		if o.id=="sofa": skills.criatividade+=delta*(0.02 if personality_trait=="Criativo" else 0.01)
	elif current.kind=="social":
		needs[4]=clampf(needs[4]+delta*(0.35 if personality_trait=="Tímido" else (1.5 if personality_trait=="Sociável" else 1.2)),0,100)
		if personality_trait=="Tímido": needs[1]=maxf(0,needs[1]-delta*0.1)
	current.remaining-=delta
	if current.remaining<=0: complete_action()
func complete_action()->void:
	if current.kind=="bell":
		var bia:=npc_by_id("bia")
		if bia.is_empty() or CityData.building_at(bia.cell)!="bia": notice.emit("Bia está fora. Volte mais tarde.")
		elif bia.get("state","")=="Dormindo" or hour_minute()<480 or hour_minute()>1260: notice.emit("Bia está dormindo. Visita recusada.")
		elif friendship<10: notice.emit("Bia prefere descansar. Visita recusada.")
		else: invited=true; visit_until=minutes+240; notice.emit("Bia: Entre! Você está convidado por quatro horas.")
	elif current.kind=="social":
		var gain:=7 if current.name=="Contar piada" else 5
		if current.id=="bia": friendship=clampf(friendship+gain,0,100)
		else: relationships[current.id]=clampf(relationships.get(current.id,0.0)+gain,0,100)
		skills.carisma+=0.5; mood_cause="Uma boa conversa"; mood_until=minutes+120
		notice.emit("Conversa concluída. A amizade aumentou.")
	if reservations.get(current.get("id",""))=="player": reservations.erase(current.id)
	current={}
func npc_by_id(id:String)->Dictionary:
	for npc in npcs:
		if npc.id==id: return npc
	return {}
func update_npcs()->void:
	npc_system.tick(self,6.0)
func choose_autonomy()->void:
	var lowest:=0
	for i in range(6):
		if needs[i]<needs[lowest]: lowest=i
	if needs[lowest]>=30: return
	var ids:=["fridge","bed","shower","toilet","","sofa"]
	if lowest==4: enqueue_social("caio")
	elif lowest!=0 or food>0: enqueue_object(ids[lowest])
func manual_step(dir:Vector2i)->bool:
	if working or shift_prompt or speed==0 or direct_cooldown>0 or dir==Vector2i.ZERO: return false
	var target:=cell+dir
	if not CityData.walkable(target,"player",invited) or occupied(target): return false
	if dir.x!=0 and dir.y!=0:
		for side in [cell+Vector2i(dir.x,0),cell+Vector2i(0,dir.y)]:
			if not CityData.walkable(side,"player",invited) or occupied(side): return false
	cancel_all(); facing=dir; cell=target
	direct_cooldown=WALK_MINUTES*Vector2(dir).length()*(1.35 if needs[1]<20 else 1.0)
	changed.emit(); return true
