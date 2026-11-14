class_name Catalog
extends RefCounted
## All tunable numbers for the kadai live here, not in the game logic.
## Money is whole rupees. Times are real seconds unless the name says minutes.

## What the kadai sells. "price" is the usual street price customers expect.
const MENU := {
	"tea": {"name": "Tea", "price": 12, "made": true},
	"vadai": {"name": "Vadai", "price": 10, "made": true},
	"biscuit": {"name": "Biscuit", "price": 5, "made": false},
	"bun": {"name": "Bun", "price": 15, "made": false},
}
const MENU_ORDER: Array[String] = ["tea", "vadai", "biscuit", "bun"]

## Market packs bought each morning. One pack adds "gives" units of stock.
const MARKET := {
	"milk": {"name": "Milk", "pack": "1 litre", "gives": 12, "unit": "glasses", "cost": 60},
	"tea_powder": {"name": "Tea powder", "pack": "Pouch", "gives": 25, "unit": "glasses", "cost": 50},
	"sugar": {"name": "Sugar", "pack": "1 kg", "gives": 40, "unit": "glasses", "cost": 45},
	"batter": {"name": "Vadai batter", "pack": "Tub", "gives": 15, "unit": "vadai", "cost": 48},
	"oil": {"name": "Oil", "pack": "1 litre", "gives": 50, "unit": "vadai", "cost": 140},
	"biscuit": {"name": "Biscuits", "pack": "Jar", "gives": 20, "unit": "biscuits", "cost": 60},
	"bun": {"name": "Buns", "pack": "Pack of 6", "gives": 6, "unit": "buns", "cost": 48},
}
const MARKET_ORDER: Array[String] = ["milk", "tea_powder", "sugar", "batter", "oil", "biscuit", "bun"]

## Stock each menu item uses. Made items use it when you start making them;
## packaged items use it when you hand them over.
const RECIPES := {
	"tea": {"milk": 1, "tea_powder": 1, "sugar": 1},
	"vadai": {"batter": 1, "oil": 1},
	"biscuit": {"biscuit": 1},
	"bun": {"bun": 1},
}

const START_MONEY := 300
const START_STOCK := {
	"milk": 12, "tea_powder": 25, "sugar": 40,
	"batter": 0, "oil": 0, "biscuit": 10, "bun": 0,
}
const MAX_PRICE := 60

## Regulars come later. These are the kinds of people who stop by on day one.
## "wants" is the chance they order each item. "price_sense" is how much a
## price above the usual one puts them off. "tip" is the most they tip.
## "patience" is how many seconds they wait happily before they start to grumble.
const CUSTOMERS := {
	"auto_driver": {
		"name": "Auto driver", "patience": 40.0, "tip": 3, "price_sense": 0.9,
		"wants": {"tea": 0.95, "vadai": 0.45, "biscuit": 0.15},
		"shirt": Color("d9b44a"), "legs": Color("6b5a3a"), "hair": Color("1e1612"),
	},
	"student": {
		"name": "College student", "patience": 35.0, "tip": 1, "price_sense": 1.6,
		"wants": {"tea": 0.8, "biscuit": 0.5, "bun": 0.35},
		"shirt": Color("4a90d9"), "legs": Color("2d3a5a"), "hair": Color("2b1d14"),
	},
	"office": {
		"name": "Office worker", "patience": 25.0, "tip": 4, "price_sense": 0.6,
		"wants": {"tea": 0.9, "bun": 0.25},
		"shirt": Color("eef0f2"), "legs": Color("3a3a48"), "hair": Color("16110e"),
	},
	"uncle": {
		"name": "Retired uncle", "patience": 70.0, "tip": 2, "price_sense": 1.3,
		"wants": {"tea": 1.0, "biscuit": 0.4},
		"shirt": Color("d9d2c0"), "legs": Color("f4f1e8"), "hair": Color("c9c4bb"),
	},
	"metro_worker": {
		"name": "Metro worker", "patience": 45.0, "tip": 2, "price_sense": 1.1,
		"wants": {"tea": 0.9, "vadai": 0.7},
		"shirt": Color("e8742f"), "legs": Color("4a4a4a"), "hair": Color("1e1612"),
	},
}

## The day, in order. "from" and "to" are kadai clock minutes after midnight.
## "seconds" is how long the phase lasts in real time. "spawn_gap" is the
## min/max real seconds between arrivals, and "mix" weights who shows up.
const PHASES := [
	{
		"id": "morning_rush", "name": "Morning rush", "from": 360, "to": 600, "seconds": 210.0,
		"spawn_gap": Vector2(5.0, 10.0),
		"mix": {"office": 3, "auto_driver": 3, "student": 2, "uncle": 2, "metro_worker": 1},
	},
	{
		"id": "afternoon", "name": "Quiet afternoon", "from": 600, "to": 960, "seconds": 150.0,
		"spawn_gap": Vector2(14.0, 24.0),
		"mix": {"uncle": 3, "auto_driver": 2, "student": 1},
	},
	{
		"id": "evening_rush", "name": "Evening rush", "from": 960, "to": 1200, "seconds": 210.0,
		"spawn_gap": Vector2(5.0, 10.0),
		"mix": {"student": 3, "metro_worker": 3, "office": 2, "auto_driver": 2},
	},
	{
		"id": "closing", "name": "Closing time", "from": 1200, "to": 1320, "seconds": 90.0,
		"spawn_gap": Vector2(18.0, 30.0),
		"mix": {"auto_driver": 2, "metro_worker": 1},
	},
]
## No new customers after 9:30 PM.
const LAST_ARRIVAL_MINUTE := 1290

const SEATS := 4
## How many made items can wait ready at once: glasses on the tray, vadai on the plate.
const READY_CAPS := {"tea": 6, "vadai": 8}


## What one unit of a menu item costs you in stock, in rupees.
static func unit_cost(item: String) -> float:
	var total := 0.0
	var recipe: Dictionary = RECIPES[item]
	for stock_id in recipe:
		var pack: Dictionary = MARKET[stock_id]
		total += float(pack["cost"]) / float(pack["gives"]) * float(recipe[stock_id])
	return total
