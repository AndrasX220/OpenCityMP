extends RefCounted
# Authoritative item definitions. Recipes consume exact integer quantities.
const ITEMS = {
	"water": {"name":"Ivóvíz", "weight":0.5, "color":"74aeb8", "kind":"food"},
	"beans": {"name":"Babkonzerv", "weight":0.4, "color":"b9a06a", "kind":"food"},
	"rag": {"name":"Rongy", "weight":0.1, "color":"bcb7a2", "kind":"medical"},
	"bandage": {"name":"Kötés", "weight":0.2, "color":"e6dfc8", "kind":"medical"},
	"wood": {"name":"Deszka", "weight":0.6, "color":"9f704a", "kind":"material"},
	"scrap": {"name":"Fémhulladék", "weight":0.5, "color":"82938a", "kind":"material"},
	"nails": {"name":"Szögcsomag", "weight":0.1, "color":"a3a99a", "kind":"material"},
	"wire": {"name":"Vezeték", "weight":0.3, "color":"bc8244", "kind":"material"},
	"parts": {"name":"Gépalkatrész", "weight":0.8, "color":"839197", "kind":"material"},
	"battery": {"name":"Akkumulátor", "weight":4.0, "color":"b75c40", "kind":"part"},
	"fuel": {"name":"Benzin · 5 L", "weight":3.7, "color":"b74435", "kind":"fuel"},
	"axe": {"name":"Erdészbalta", "weight":1.5, "color":"afa18a", "kind":"tool"},
	"pistol": {"name":"P63 pisztoly", "weight":0.9, "color":"8a969b", "kind":"weapon"},
	"rifle": {"name":"M65 karabély", "weight":3.2, "color":"aa7950", "kind":"weapon"},
	"ammo": {"name":"9×18 töltény", "weight":0.01, "color":"c7a15c", "kind":"ammo"},
	"rifle_ammo": {"name":"7,62×39 töltény", "weight":0.016, "color":"b79855", "kind":"ammo"},
	"backpack": {"name":"Túrahátizsák", "weight":0.8, "color":"778461", "kind":"gear"},
	"map": {"name":"Turistatérkép", "weight":0.1, "color":"c6bd91", "kind":"gear"},
	"repair": {"name":"Járműjavító készlet", "weight":1.0, "color":"a48357", "kind":"tool"},
	"generator": {"name":"G-35 generátor", "weight":10.0, "color":"d17645", "kind":"build"},
	"lamp": {"name":"Műhelylámpa", "weight":0.8, "color":"e8c777", "kind":"build"},
	"campfire": {"name":"Tábortűz", "weight":1.0, "color":"ce8746", "kind":"build"},
	"crate": {"name":"Tárolóláda", "weight":2.0, "color":"986e4a", "kind":"build"}
}
const RECIPES = {
	"bandage":{"name":"Kötés", "need":{"rag":2}, "out":"bandage", "amount":1, "station":0},
	"repair":{"name":"Járműjavító készlet", "need":{"scrap":3,"parts":2}, "out":"repair", "amount":1, "station":1},
	"campfire":{"name":"Tábortűz", "need":{"wood":3}, "out":"campfire", "amount":1, "station":0},
	"crate":{"name":"Tárolóláda", "need":{"wood":6,"nails":2}, "out":"crate", "amount":1, "station":1},
	"generator":{"name":"G-35 generátor", "need":{"scrap":8,"parts":4,"wire":3}, "out":"generator", "amount":1, "station":1},
	"lamp":{"name":"Műhelylámpa", "need":{"scrap":2,"wire":2}, "out":"lamp", "amount":1, "station":1}
}
const BUILD = {
	"foundation":{"name":"Fa alap · 2×2 m", "need":{"wood":4,"nails":1}, "size":Vector3(2,0.25,2)},
	"wall":{"name":"Fal", "need":{"wood":3,"nails":1}, "size":Vector3(2,2.4,0.16)},
	"door":{"name":"Ajtókeret + ajtó", "need":{"wood":4,"nails":1}, "size":Vector3(2,2.4,0.16)},
	"window":{"name":"Ablakfal", "need":{"wood":3,"nails":1}, "size":Vector3(2,2.4,0.16)},
	"roof":{"name":"Tető", "need":{"wood":4}, "size":Vector3(2,0.16,2)},
	"bench":{"name":"Munkapad I", "need":{"wood":6,"scrap":2}, "size":Vector3(1.5,1,0.7)},
	"crate":{"name":"Tárolóláda", "need":{"crate":1}, "size":Vector3(1,0.7,0.7)},
	"generator":{"name":"G-35 generátor", "need":{"generator":1}, "size":Vector3(0.8,0.8,0.6)},
	"lamp":{"name":"Műhelylámpa", "need":{"lamp":1}, "size":Vector3(0.25,2.2,0.25)},
	"campfire":{"name":"Tábortűz", "need":{"campfire":1}, "size":Vector3(0.8,0.3,0.8)}
}
const LOOT = {
	"home":[["beans",2],["water",2],["rag",3],["wood",3],["nails",2]],
	"garage":[["scrap",6],["parts",3],["wire",3],["battery",1],["fuel",1]],
	"police":[["pistol",1],["ammo",24],["bandage",2]],
	"military":[["rifle",1],["rifle_ammo",45],["bandage",2]],
	"forest":[["axe",1],["wood",8],["nails",4]],
	"start":[["water",2],["beans",2],["rag",2],["backpack",1],["map",1]],
	"workshop":[["scrap",8],["parts",6],["wire",5],["fuel",2],["repair",1]]
}
const PLACES = [
	{"name":"Berekfalva", "p":Vector2(0,0)},
	{"name":"Erdészet", "p":Vector2(-150,-150)},
	{"name":"Nyugat üzemanyag", "p":Vector2(43,-61)},
	{"name":"Rendőrőrs", "p":Vector2(-40,-113)},
	{"name":"Aranykalász major", "p":Vector2(150,162)},
	{"name":"Katonai ellenőrzőpont", "p":Vector2(0,-230)}
]
static func mass(items:Dictionary) -> float:
	var total:float=0.0
	for id in items:
		if ITEMS.has(id):
			total+=float(ITEMS[id].weight)*int(items[id])
	return total
static func can_pay(items:Dictionary, cost:Dictionary) -> bool:
	for id in cost:
		if int(items.get(id,0))<int(cost[id]):
			return false
	return true
static func paid(items:Dictionary, cost:Dictionary) -> Dictionary:
	var result:Dictionary=items.duplicate()
	for id in cost:
		result[id]=int(result.get(id,0))-int(cost[id])
		if result[id]<=0:
			result.erase(id)
	return result
