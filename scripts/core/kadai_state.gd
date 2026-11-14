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


func _init() -> void:
	money = Catalog.START_MONEY
	stock = Catalog.START_STOCK.duplicate()
	for item in Catalog.MENU_ORDER:
		prices[item] = Catalog.MENU[item]["price"]
	_reset_today()


func next_day() -> void:
	day += 1
	_reset_today()


func _reset_today() -> void:
	today = {
		"revenue": 0, "tips": 0, "spent": 0,
		"served": 0, "walked_out": 0, "too_costly": 0, "no_seat": 0, "wasted": 0,
		"sold": {}, "bought": {},
	}


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


func profit_today() -> int:
	return int(today["revenue"]) + int(today["tips"]) - int(today["spent"])
