class_name KadaiState
extends RefCounted
## The kadai between days: money, stock, prices, and today's numbers.

var day := 1
var money := 0
## Market item id -> units in stock.
var stock := {}
## Menu item id -> today's price in rupees.
var prices := {}
## Numbers for the day in progress. Reset every morning.
var today := {}
## Upgrade ids bought for the kadai.
var upgrades: Array[String] = []
## Menu items learned beyond the starting menu, like "ginger_tea".
var recipes: Array[String] = []
## Regular id -> {"friendship": int, "visits": int, "flags": Dictionary}.
var regulars := {}
var best_streak := 0


func _init() -> void:
	money = Catalog.START_MONEY
	stock = Catalog.START_STOCK.duplicate()
	for item in Catalog.MENU:
		prices[item] = Catalog.MENU[item]["price"]
	_reset_today()


func next_day() -> void:
	day += 1
	_reset_today()


func _reset_today() -> void:
	today = {
		"revenue": 0, "tips": 0, "spent": 0, "upgrades": 0,
		"served": 0, "waited_long": 0, "out_of_stock": 0, "too_costly": 0, "no_seat": 0, "wasted": 0,
		"perfect": 0, "best_streak": 0,
		"sold": {}, "bought": {}, "met": [],
	}


# --- Saving ---------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": 1, "day": day, "money": money, "stock": stock, "prices": prices,
		"upgrades": upgrades, "recipes": recipes, "regulars": regulars, "best_streak": best_streak,
	}


## Rebuilds a kadai from saved data, keeping defaults for anything missing so
## older saves still load after new items are added.
static func from_dict(data: Dictionary) -> KadaiState:
	var state := KadaiState.new()
	state.day = maxi(1, int(data.get("day", 1)))
	state.money = int(data.get("money", state.money))
	var saved_stock: Dictionary = data.get("stock", {})
	for stock_id in state.stock:
		state.stock[stock_id] = maxi(0, int(saved_stock.get(stock_id, state.stock[stock_id])))
	var saved_prices: Dictionary = data.get("prices", {})
	for item in state.prices:
		state.prices[item] = clampi(int(saved_prices.get(item, state.prices[item])), 1, Catalog.MAX_PRICE)
	for id in data.get("upgrades", []):
		if Catalog.UPGRADES.has(id) and not state.upgrades.has(id):
			state.upgrades.append(id)
	for item in data.get("recipes", []):
		if Catalog.MENU.has(item) and not state.recipes.has(item):
			state.recipes.append(item)
	var saved_regulars: Dictionary = data.get("regulars", {})
	for id in saved_regulars:
		state.regulars[id] = saved_regulars[id]
	state.best_streak = int(data.get("best_streak", 0))
	return state


# --- Menu, upgrades and regulars ------------------------------------------

## Menu items on sale today: the starting menu plus anything learned.
func menu() -> Array[String]:
	var items: Array[String] = []
	for item in Catalog.MENU_ORDER:
		if not Catalog.MENU[item].get("learned", false) or recipes.has(item):
			items.append(item)
	return items


func has_upgrade(id: String) -> bool:
	return upgrades.has(id)


func buy_upgrade(id: String) -> bool:
	var cost := int(Catalog.UPGRADES[id]["cost"])
	if has_upgrade(id) or money < cost:
		return false
	money -= cost
	today["upgrades"] += cost
	upgrades.append(id)
	return true


## The saved story state for a regular, created on first use.
func regular(id: String) -> Dictionary:
	if not regulars.has(id):
		regulars[id] = {"friendship": 0, "visits": 0, "flags": {}}
	return regulars[id]


func add_friendship(id: String, amount: int) -> void:
	var r := regular(id)
	r["friendship"] = clampi(int(r["friendship"]) + amount, 0, 100)


# --- Market ---------------------------------------------------------------

func can_afford(stock_id: String) -> bool:
	return money >= int(Catalog.MARKET[stock_id]["cost"])


func buy(stock_id: String) -> bool:
	if not can_afford(stock_id):
		return false
	var pack: Dictionary = Catalog.MARKET[stock_id]
	money -= int(pack["cost"])
	stock[stock_id] += int(pack["gives"])
	today["spent"] += int(pack["cost"])
	today["bought"][stock_id] = int(today["bought"].get(stock_id, 0)) + 1
	return true


## Puts back a pack bought this morning and refunds it.
func undo_buy(stock_id: String) -> bool:
	var pack: Dictionary = Catalog.MARKET[stock_id]
	var bought := int(today["bought"].get(stock_id, 0))
	if bought <= 0 or int(stock[stock_id]) < int(pack["gives"]):
		return false
	money += int(pack["cost"])
	stock[stock_id] -= int(pack["gives"])
	today["spent"] -= int(pack["cost"])
	today["bought"][stock_id] = bought - 1
	return true


func bought_today(stock_id: String) -> int:
	return int(today["bought"].get(stock_id, 0))


func set_price(item: String, value: int) -> void:
	prices[item] = clampi(value, 1, Catalog.MAX_PRICE)


# --- Stock ----------------------------------------------------------------

## How many of a menu item the current stock can make.
func how_many(item: String) -> int:
	var recipe: Dictionary = Catalog.RECIPES[item]
	var most := 1 << 30
	for stock_id in recipe:
		most = mini(most, int(stock[stock_id]) / int(recipe[stock_id]))
	return most


func can_make(item: String) -> bool:
	return how_many(item) > 0


## Name of the first stock item that is missing for this menu item, or "".
func missing_for(item: String) -> String:
	var recipe: Dictionary = Catalog.RECIPES[item]
	for stock_id in recipe:
		if int(stock[stock_id]) < int(recipe[stock_id]):
			return Catalog.MARKET[stock_id]["name"]
	return ""


func use_recipe(item: String) -> bool:
	if not can_make(item):
		return false
	var recipe: Dictionary = Catalog.RECIPES[item]
	for stock_id in recipe:
		stock[stock_id] -= int(recipe[stock_id])
	return true


# --- Sales ----------------------------------------------------------------

func record_sale(item: String) -> int:
	var price := int(prices[item])
	money += price
	today["revenue"] += price
	today["sold"][item] = int(today["sold"].get(item, 0)) + 1
	return price


func record_tip(amount: int) -> void:
	money += amount
	today["tips"] += amount


## Lost customers today: waited too long, left over missing stock, or found no seat.
func lost_today() -> int:
	return int(today["waited_long"]) + int(today["out_of_stock"]) + int(today["no_seat"])


## One to three stars for the day.
func stars_today() -> int:
	var served := int(today["served"])
	var lost := lost_today()
	var stars := 1 if served > 0 else 0
	if served >= 12 and lost * 3 <= served:
		stars += 1
	if served >= 20 and lost * 6 <= served and int(today["perfect"]) >= 8:
		stars += 1
	return stars


func profit_today() -> int:
	return int(today["revenue"]) + int(today["tips"]) - int(today["spent"])
