class_name Catalog
extends RefCounted
## All tunable numbers for the kadai live here, not in the game logic.
## Money is whole rupees. Times are real seconds unless the name says minutes.

## What the kadai sells. "price" is the usual street price customers expect.
const MENU := {
	"tea": {"name": "Tea", "price": 12, "made": true},
	"ginger_tea": {"name": "Ginger tea", "price": 15, "made": true, "learned": true},
	"vadai": {"name": "Vadai", "price": 10, "made": true},
	"biscuit": {"name": "Biscuit", "price": 5, "made": false},
	"bun": {"name": "Bun", "price": 15, "made": false},
}
const MENU_ORDER: Array[String] = ["tea", "ginger_tea", "vadai", "biscuit", "bun"]
## Glasses made at the tea station and carried on the tray.
const GLASSES: Array[String] = ["tea", "ginger_tea"]

## Market packs bought each morning. One pack adds "gives" units of stock.
const MARKET := {
	"milk": {"name": "Milk", "pack": "1 litre", "gives": 12, "unit": "glasses", "cost": 60},
	"tea_powder": {"name": "Tea powder", "short": "Tea dust", "pack": "Pouch", "gives": 25, "unit": "glasses", "cost": 50},
	"sugar": {"name": "Sugar", "pack": "1 kg", "gives": 40, "unit": "glasses", "cost": 45},
	"ginger": {"name": "Ginger", "pack": "100 g", "gives": 20, "unit": "glasses", "cost": 30, "for": "ginger_tea"},
	"batter": {"name": "Vadai batter", "short": "Batter", "pack": "Tub", "gives": 15, "unit": "vadai", "cost": 48},
	"oil": {"name": "Oil", "pack": "1 litre", "gives": 50, "unit": "vadai", "cost": 140},
	"biscuit": {"name": "Biscuits", "pack": "Jar", "gives": 20, "unit": "biscuits", "cost": 60},
	"bun": {"name": "Buns", "pack": "Pack of 6", "gives": 6, "unit": "buns", "cost": 48},
}
const MARKET_ORDER: Array[String] = ["milk", "tea_powder", "sugar", "ginger", "batter", "oil", "biscuit", "bun"]

## Stock each menu item uses. Made items use it when you start making them;
## packaged items use it when you hand them over.
const RECIPES := {
	"tea": {"milk": 1, "tea_powder": 1, "sugar": 1},
	"ginger_tea": {"milk": 1, "tea_powder": 1, "sugar": 1, "ginger": 1},
	"vadai": {"batter": 1, "oil": 1},
	"biscuit": {"biscuit": 1},
	"bun": {"bun": 1},
}

const START_MONEY := 300
const START_STOCK := {
	"milk": 12, "tea_powder": 25, "sugar": 40, "ginger": 0,
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
## Gaps between arrivals are stretched on the first days so the week starts
## gently. Index 0 is day 1; later days use the last value.
const DAY_PACE: Array[float] = [1.7, 1.4, 1.15, 1.0]


static func pace_for_day(day: int) -> float:
	return DAY_PACE[clampi(day - 1, 0, DAY_PACE.size() - 1)]

const SEATS := 4
## How many glasses fit on the tray, and how many vadai on the plate.
const TRAY_GLASSES := 6
const VADAI_PLATE := 8
## Customers who order tea ask for ginger tea instead this often, once it's learned.
const GINGER_SHARE := 0.3

## Things to save up for, bought on the night screen.
const UPGRADES := {
	"bench": {"name": "Bench", "cost": 350, "about": "Room for one more customer at the counter."},
	"pot": {"name": "Bigger milk pot", "cost": 450, "about": "Glasses fill twice as fast."},
	"fan": {"name": "Table fan", "cost": 600, "about": "Customers stay patient much longer."},
	"sign": {"name": "Lit signboard", "cost": 900, "about": "More customers find you in the evening."},
}
const UPGRADE_ORDER: Array[String] = ["bench", "pot", "fan", "sign"]
const FAN_PATIENCE := 1.5
const SIGN_EVENING_PACE := 0.75

## Day 1 is Monday 3 November, in the northeast monsoon.
const START_DATE := {"year": 2025, "month": 11, "day": 3}
const WEEKDAYS: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const MONTHS: Array[String] = ["January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]
## About one day in three gets a shower. Never on day 1.
const RAIN_CHANCE := 0.34
const RAIN_PACE := 0.7

## The morning paper. One headline a day, in order.
const HEADLINES: Array[String] = [
	"Metro work on the main road to finish \"very soon\", officials say again",
	"Jasmine prices touch a record high before the wedding season",
	"Big-star film releases Friday; fans plan a 4 AM show",
	"Corporation promises smooth roads by Pongal",
	"Filter coffee vs tea: the debate reaches the city council",
	"Beach clean-up drive this weekend; volunteers wanted",
	"College results out this weekend; students \"completely calm\"",
	"Auto fares to be revised; drivers unimpressed",
	"Local cricket club wins by one run, celebrates for three days",
	"Weather office: \"Carry an umbrella. Or don't. We're not your mother.\"",
]

## Things customers say while they wait, by situation.
const CHATTER := {
	"any": [
		"Did you see last night's match?", "Traffic was crazy today.", "That new film? Waste of time.",
		"Petrol went up again, I tell you.", "My boss called again. On a Sunday!",
		"My daughter got full marks in maths!", "Ayyo, this heat.", "Smells good, anna!",
	],
	"morning": ["First tea of the day. Life saver.", "Late for office, quick quick!", "Didn't sleep at all."],
	"evening": ["Long day, anna.", "One tea, then home.", "The sunset is nice today."],
	"rain": ["Rain means tea, no?", "Forgot my umbrella again.", "Roads will flood by evening, watch."],
}
## What customers say as they leave, by how good their order was.
const REACTIONS := {
	"perfect": ["Super-a irukku!", "Semma tea!", "Aaha, perfect!", "Best in Chennai!"],
	"good": ["Nice, anna.", "Good tea.", "Hmm, nice."],
	"okay": ["Okay okay.", "Bit flat today."],
	"grumpy": ["Finally!", "Took your time…"],
}
## A perfect-pour streak this long or longer earns a bonus each pour.
const STREAK_BONUS_FROM := 3


## A date like "Monday, 3 November" for a day number.
static func date_text(day: int) -> String:
	var info := _date(day)
	return "%s, %d %s" % [WEEKDAYS[(day - 1) % 7], info["day"], MONTHS[int(info["month"]) - 1]]


static func weekday_short(day: int) -> String:
	return WEEKDAYS[(day - 1) % 7].substr(0, 3)


static func _date(day: int) -> Dictionary:
	var start := Time.get_unix_time_from_datetime_dict(START_DATE)
	return Time.get_datetime_dict_from_unix_time(start + (day - 1) * 86400)


## The minutes a rain shower falls on this day, as (start, end), or ZERO.
## Fixed per day so the morning paper can forecast it.
static func rain_for_day(day: int) -> Vector2:
	if day <= 1:
		return Vector2.ZERO
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 13
	if rng.randf() >= RAIN_CHANCE:
		return Vector2.ZERO
	var start := rng.randf_range(660.0, 1020.0)
	return Vector2(start, start + rng.randf_range(90.0, 150.0))


static func headline(day: int) -> String:
	return HEADLINES[(day - 1) % HEADLINES.size()]


## What one unit of a menu item costs you in stock, in rupees.
static func unit_cost(item: String) -> float:
	var total := 0.0
	var recipe: Dictionary = RECIPES[item]
	for stock_id in recipe:
		var pack: Dictionary = MARKET[stock_id]
		total += float(pack["cost"]) / float(pack["gives"]) * float(recipe[stock_id])
	return total
