class_name NeighborhoodSimulation
extends RefCounted
# Every resident owns needs, a cached route, stock, money and an activity.
# Routes are calculated only when choosing a destination, never per render frame.
func ensure_state(sim)->void:
	for npc in sim.npcs:
		var defaults={"needs":[62.0,82.0,80.0,75.0,65.0,60.0],"route":[],"action":{},"move_elapsed":0.0,"wait":0.0,"decision_in":0.0,"meals":4,"money":120,"facing":Vector2i.DOWN,"home":npc.id,"last_goal":"","social_until":-1.0}
		for key in defaults:
			if not npc.has(key): npc[key]=defaults[key]
		npc.meals=int(npc.meals); npc.money=int(npc.money)
		if not npc.action.is_empty(): npc.action.need=int(npc.action.need)
func release(sim,npc:Dictionary)->void:
	var id:String=npc.get("action",{}).get("id","")
	if sim.reservations.get(id)==npc.id: sim.reservations.erase(id)
	npc.action={}; npc.route=[]; npc.wait=0.0
func tick(sim,delta:float)->void:
	ensure_state(sim)
	for npc in sim.npcs:
		for i in range(6): npc.needs[i]=clampf(npc.needs[i]-LifeSimulation.DECAY[i]*delta,0,100)
		if sim.minutes<float(npc.social_until):
			npc.state="Conversando na praça"; npc.needs[4]=minf(100,npc.needs[4]+delta); continue
		if sim.current.get("kind","")=="social" and sim.current.id==npc.id:
			npc.state="Conversando"; npc.needs[4]=minf(100,npc.needs[4]+delta); continue
		npc.decision_in=maxf(0,npc.decision_in-delta)
		if not npc.route.is_empty():
			npc.move_elapsed+=delta
			while npc.move_elapsed>=0.42 and not npc.route.is_empty():
				var next:Vector2i=npc.route[0]
				if sim.occupied(next,npc.id):
					npc.wait+=delta
					if npc.wait>5:
						release(sim,npc); npc.decision_in=2
						# Yield sideways so doorways and narrow passages can clear.
						for dir in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
							var side:Vector2i=npc.cell+dir
							if CityData.walkable(side,npc.id) and not sim.occupied(side,npc.id): npc.facing=dir; npc.cell=side; break
					break
				npc.move_elapsed-=0.42; npc.wait=0
				npc.facing=next-npc.cell; npc.cell=next; npc.route.pop_front()
			continue
		if not npc.action.is_empty():
			var o:=CityData.object_by_id(npc.action.id)
			if not npc.action.get("started",false):
				npc.action.started=true; npc.facing=o.cell-npc.cell
				if o.kind=="fridge": npc.meals-=1
			var used:=minf(delta,float(npc.action.remaining))
			npc.needs[npc.action.need]=clampf(npc.needs[npc.action.need]+float(npc.action.gain)*used/float(npc.action.duration),0,100)
			npc.action.remaining-=used
			if npc.action.remaining<=0: release(sim,npc); npc.decision_in=5
			continue
		if npc.decision_in<=0: decide(sim,npc)
func decide(sim,npc:Dictionary)->void:
	npc.decision_in=8
	var hm:int=sim.hour_minute()
	var prefix:String=npc.id+"_"
	if (hm>=1320 or hm<360) and npc.needs[1]<96:
		if use_object(sim,npc,prefix+"bed",1,"Dormindo",120,65): return
	if npc.needs[0]<35:
		if npc.meals<=0 and npc.money>=12: npc.meals+=2; npc.money-=12
		if npc.meals>0 and use_object(sim,npc,prefix+"fridge",0,"Comendo",25,48): return
	if npc.needs[3]<25 and use_object(sim,npc,prefix+"toilet",3,"No banheiro",12,80): return
	if npc.needs[2]<35 and use_object(sim,npc,prefix+"shower",2,"Tomando banho",25,75): return
	if npc.needs[5]<35:
		if use_object(sim,npc,prefix+"sofa",5,"Lendo em casa",40,45): return
	if npc.needs[4]<30:
		for other in sim.npcs:
			if other.id==npc.id or not other.action.is_empty() or not other.route.is_empty(): continue
			if CityData.building_at(npc.cell)!=CityData.building_at(other.cell): continue
			var nearby:=CityData.path(npc.cell,other.cell,npc.id)
			if not nearby.is_empty() and nearby.size()<=2:
				npc.social_until=sim.minutes+20; other.social_until=sim.minutes+20; npc.state="Conversando na praça"; other.state="Conversando na praça"; return
	var goal:Vector2i
	var at_work:bool=sim.day()%7<5 and ((hm>=540 and hm<780) if npc.id=="caio" else (hm>=600 and hm<1020))
	if at_work:
		goal=Vector2i(24,21) if npc.id=="caio" else Vector2i(10,20)
		npc.state="Trabalhando no Café" if npc.id=="caio" else "Vendendo flores na praça"
	elif hm>=1080 or hm<480:
		goal=Vector2i(19,7) if npc.id=="bia" else Vector2i(33,7); npc.state="Em casa"
	else:
		goal=Vector2i(10,21) if npc.id=="bia" else Vector2i(12,19); npc.state="Passeando na praça"
	if goal!=npc.cell: npc.route=CityData.path(npc.cell,goal,npc.id)
func use_object(sim,npc:Dictionary,id:String,need:int,state:String,duration:float,gain:float)->bool:
	var o:=CityData.object_by_id(id)
	if o.is_empty() or sim.reservations.has(id): return false
	var chosen:=Vector2i(-1,-1); var shortest:=9999; var route:Array[Vector2i]=[]
	for at in CityData.use_points(o,npc.id):
		if sim.occupied(at,npc.id): continue
		var p:=CityData.path(npc.cell,at,npc.id)
		if at==npc.cell: chosen=at; route=[]; break
		if not p.is_empty() and p.size()<shortest: chosen=at; shortest=p.size(); route=p
	if chosen.x<0: return false
	sim.reservations[id]=npc.id; npc.route=route
	npc.action={"id":id,"need":need,"duration":duration,"remaining":duration,"gain":gain,"started":false,"use_cell":chosen}
	npc.state=state; return true
