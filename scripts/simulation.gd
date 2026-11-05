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
var step_elapsed:=0.0
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
	npc_tick+=delta
	if npc_tick>=6: npc_tick=0; update_npcs()
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
	cell=Vector2i(24,20); work_end=day()*1440.0+780.0
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
	working=false; current={}; cell=Vector2i(23,24)
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
	reservations.clear(); current={}; queue.clear(); route.clear(); changed.emit()
func cancel_index(index:int)->void:
	if index>=0 and index<queue.size(): queue.remove_at(index); changed.emit()
func nearest_use(target:Vector2i)->Vector2i:
	var best:=Vector2i(-1,-1); var shortest:=9999
	for dir in [Vector2i.DOWN,Vector2i.RIGHT,Vector2i.LEFT,Vector2i.UP]:
		var candidate:Vector2i=target+dir
		if candidate==cell: return cell
		var p:=CityData.path(cell,candidate,"player",invited)
		if not p.is_empty() and p.size()<shortest: best=candidate; shortest=p.size()
	return best
func fail_action(message:String)->void:
	reservations.erase(current.get("id","")); current={}; route.clear(); notice.emit(message)
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
	elif current.kind=="social":
		var npc:=npc_by_id(current.id)
		if npc.is_empty(): fail_action("Pessoa não encontrada."); return
		target=nearest_use(npc.cell); current["remaining"]=20.0
		if target.x<0: fail_action("Essa pessoa não está acessível agora."); return
	if target!=cell:
		route=CityData.path(cell,target,"player",invited)
		if route.is_empty(): fail_action("Caminho bloqueado ou entrada sem autorização."); return
	current["arrived"]=false
func advance_actions(delta:float)->void:
	if current.is_empty(): begin_next()
	if current.is_empty(): return
	if not route.is_empty():
		step_elapsed+=delta
		var duration:=1.1 if needs[1]<20 else 0.65
		if step_elapsed>=duration:
			step_elapsed-=duration
			for npc in npcs:
				if npc.cell==route[0]: fail_action("Uma pessoa está no caminho. Tente novamente."); return
			cell=route.pop_front()
		return
	if not current.get("arrived",false):
		current["arrived"]=true
		if current.kind=="object":
			if current.id=="fridge": food-=1
			if current.cost>0: add_transaction(-int(current.cost),current.name)
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
		elif hour_minute()<480 or hour_minute()>1260: notice.emit("Bia está dormindo. Visita recusada.")
		elif friendship<10: notice.emit("Bia prefere descansar. Visita recusada.")
		else: invited=true; notice.emit("Bia: Entre! Você está convidado.")
	elif current.kind=="social":
		var gain:=7 if current.name=="Contar piada" else 5
		if current.id=="bia": friendship=clampf(friendship+gain,0,100)
		else: relationships[current.id]=clampf(relationships.get(current.id,0.0)+gain,0,100)
		skills.carisma+=0.5; mood_cause="Uma boa conversa"; mood_until=minutes+120
		notice.emit("Conversa concluída. A amizade aumentou.")
	reservations.erase(current.get("id","")); current={}
func npc_by_id(id:String)->Dictionary:
	for npc in npcs:
		if npc.id==id: return npc
	return {}
func update_npcs()->void:
	for npc in npcs:
		if current.get("kind","")=="social" and current.id==npc.id: continue
		var hm:=hour_minute(); var goal:Vector2i
		if npc.id=="bia":
			goal=Vector2i(19,7) if hm<600 or hm>=1080 else Vector2i(10,20)
			npc.state="Em casa" if hm<600 or hm>=1080 else "Na praça"
		else:
			goal=Vector2i(24,21) if hm>=480 and hm<1080 else Vector2i(13,16)
			npc.state="No Café" if hm>=480 and hm<1080 else "Na praça"
		var p:=CityData.path(npc.cell,goal,npc.id,false)
		if not p.is_empty() and p[0]!=cell:
			var occupied:=false
			for other in npcs:
				if other.id!=npc.id and other.cell==p[0]: occupied=true
			if not occupied: npc.cell=p[0]
	if hour_minute()<420 and CityData.building_at(cell)!="bia": invited=false
func choose_autonomy()->void:
	var lowest:=0
	for i in range(6):
		if needs[i]<needs[lowest]: lowest=i
	if needs[lowest]>=30: return
	var ids:=["fridge","bed","shower","toilet","","sofa"]
	if lowest==4: enqueue_social("caio")
	elif lowest!=0 or food>0: enqueue_object(ids[lowest])
func manual_step(dir:Vector2i)->void:
	if working or shift_prompt or speed==0: return
	cancel_all()
	var target:=cell+dir
	for npc in npcs:
		if npc.cell==target: return
	if CityData.walkable(target,"player",invited): cell=target; changed.emit()
