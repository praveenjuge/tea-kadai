class_name Catalog
extends RefCounted
## All tunable numbers for the kadai live here, not in the game logic.
## Money is whole rupees. Times are real seconds unless the name says minutes.

## What the kadai sells. "price" is the usual street price customers expect.
## "level" items unlock free at that kadai level; "learned" items come from
## the story (a regular teaches them).
const MENU := {
	"tea": {"name": "Tea", "price": 12, "made": true},
	"ginger_tea": {"name": "Ginger tea", "price": 15, "made": true, "learned": true},
	"lemon_tea": {"name": "Lemon tea", "price": 10, "made": true, "level": 2},
	"filter_coffee": {"name": "Filter coffee", "short": "Coffee", "price": 15, "made": true, "level": 4},
	"vadai": {"name": "Vadai", "price": 10, "made": true},
	"bajji": {"name": "Bajji", "price": 12, "made": true, "level": 3},
	"biscuit": {"name": "Biscuit", "price": 5, "made": false},
	"bun": {"name": "Bun", "price": 15, "made": false},
	"samosa": {"name": "Samosa", "price": 15, "made": false, "level": 5},
}
const MENU_ORDER: Array[String] = [
	"tea", "ginger_tea", "lemon_tea", "filter_coffee", "vadai", "bajji", "biscuit", "bun", "samosa",
]
## Drinks made at the tea station and carried on the tray.
const GLASSES: Array[String] = ["tea", "ginger_tea", "lemon_tea", "filter_coffee"]
## Snacks fried in the kadai, in batches.
const FRIED: Array[String] = ["vadai", "bajji"]
## Seconds until a batch turns golden, and until it burns.
const FRY_TIMES := {"vadai": Vector2(8.0, 18.0), "bajji": Vector2(6.0, 14.0)}

## Market packs bought each morning. One pack adds "gives" units of stock.
## Goods with "for" only show once that menu item is on the menu.
const MARKET := {
	"milk": {"name": "Milk", "pack": "1 litre", "gives": 12, "unit": "glasses", "cost": 60},
	"tea_powder": {"name": "Tea powder", "short": "Tea dust", "pack": "Pouch", "gives": 25, "unit": "glasses", "cost": 50},
	"sugar": {"name": "Sugar", "pack": "1 kg", "gives": 40, "unit": "glasses", "cost": 45},
	"ginger": {"name": "Ginger", "pack": "100 g", "gives": 20, "unit": "glasses", "cost": 30, "for": "ginger_tea"},
	"lemon": {"name": "Lemons", "pack": "Two dozen", "gives": 24, "unit": "glasses", "cost": 40, "for": "lemon_tea"},
	"coffee_powder": {"name": "Coffee powder", "short": "Coffee", "pack": "Pouch", "gives": 20, "unit": "glasses", "cost": 70, "for": "filter_coffee"},
	"batter": {"name": "Vadai batter", "short": "Batter", "pack": "Tub", "gives": 15, "unit": "vadai", "cost": 48},
	"besan": {"name": "Bajji mix", "pack": "Tub", "gives": 15, "unit": "bajji", "cost": 54, "for": "bajji"},
	"oil": {"name": "Oil", "pack": "1 litre", "gives": 50, "unit": "fries", "cost": 140},
	"biscuit": {"name": "Biscuits", "pack": "Jar", "gives": 20, "unit": "biscuits", "cost": 60},
	"bun": {"name": "Buns", "pack": "Pack of 6", "gives": 6, "unit": "buns", "cost": 48},
	"samosa": {"name": "Samosas", "pack": "Box of 10", "gives": 10, "unit": "samosas", "cost": 80, "for": "samosa"},
}
const MARKET_ORDER: Array[String] = [
	"milk", "tea_powder", "sugar", "ginger", "lemon", "coffee_powder",
	"batter", "besan", "oil", "biscuit", "bun", "samosa",
]

## Stock each menu item uses. Made items use it when you start making them;
## packaged items use it when you hand them over.
const RECIPES := {
	"tea": {"milk": 1, "tea_powder": 1, "sugar": 1},
	"ginger_tea": {"milk": 1, "tea_powder": 1, "sugar": 1, "ginger": 1},
	"lemon_tea": {"lemon": 1, "tea_powder": 1, "sugar": 1},
	"filter_coffee": {"milk": 1, "coffee_powder": 1, "sugar": 1},
	"vadai": {"batter": 1, "oil": 1},
	"bajji": {"besan": 1, "oil": 1},
	"biscuit": {"biscuit": 1},
	"bun": {"bun": 1},
	"samosa": {"samosa": 1},
}

const START_MONEY := 300
## You can't lose: if a morning starts with less than this and little tea
## stock, family sends a little money so the kadai can open.
const HELP_BELOW := 150
const HELP_AMOUNT := 200
## Enough for a whole first day, so a new player can just open the kadai.
const START_STOCK := {
	"milk": 24, "tea_powder": 25, "sugar": 40, "ginger": 0, "lemon": 0, "coffee_powder": 0,
	"batter": 15, "besan": 0, "oil": 50, "biscuit": 20, "bun": 6, "samosa": 0,
}
const MAX_PRICE := 60

## The kinds of people who stop by. Each picks one drink from "drinks"
## (weighted, only what's on the menu) and maybe some snacks ("snacks" are
## chances). "price_sense" is how much a price above the usual puts them off,
## "tip" the most they tip, "patience" seconds before they grumble. The rest
## is how they look.
const CUSTOMERS := {
	"auto_driver": {
		"name": "Auto driver", "patience": 40.0, "tip": 3, "price_sense": 0.9,
		"drinks": {"tea": 6, "ginger_tea": 2, "lemon_tea": 1, "filter_coffee": 1},
		"snacks": {"vadai": 0.45, "bajji": 0.3, "biscuit": 0.15},
		"skin": Color("7a4a2e"), "shirt": Color("d9b44a"), "legs": Color("6b5a3a"), "hair": Color("1e1612"),
		"mustache": true,
	},
	"student": {
		"name": "College student", "patience": 35.0, "tip": 1, "price_sense": 1.6,
		"drinks": {"tea": 5, "lemon_tea": 2, "filter_coffee": 2, "ginger_tea": 1},
		"snacks": {"biscuit": 0.45, "bun": 0.3, "samosa": 0.3},
		"skin": Color("9a6440"), "shirt": Color("4a90d9"), "legs": Color("2d3a5a"), "hair": Color("2b1d14"),
	},
	"office": {
		"name": "Office worker", "patience": 25.0, "tip": 4, "price_sense": 0.6,
		"drinks": {"filter_coffee": 4, "tea": 4, "ginger_tea": 1},
		"snacks": {"bun": 0.25, "samosa": 0.2},
		"skin": Color("8d5a3b"), "shirt": Color("eef0f2"), "legs": Color("3a3a48"), "hair": Color("16110e"),
		"mustache": true, "tag": true,
	},
	"uncle": {
		"name": "Retired uncle", "patience": 70.0, "tip": 2, "price_sense": 1.3,
		"drinks": {"tea": 4, "filter_coffee": 4},
		"snacks": {"biscuit": 0.4},
		"skin": Color("80543a"), "shirt": Color("d9d2c0"), "legs": Color("f4f1e8"), "hair": Color("c9c4bb"),
		"hair_style": "bald", "glasses": true, "mustache": true,
	},
	"metro_worker": {
		"name": "Metro worker", "patience": 45.0, "tip": 2, "price_sense": 1.1,
		"drinks": {"tea": 5, "ginger_tea": 3},
		"snacks": {"vadai": 0.6, "bajji": 0.4, "samosa": 0.2},
		"skin": Color("6e4329"), "shirt": Color("e8742f"), "legs": Color("4a4a4a"), "hair": Color("1e1612"),
		"hat": Color("e8c547"),
	},
	"nurse": {
		"name": "Nurse", "patience": 30.0, "tip": 3, "price_sense": 1.0,
		"drinks": {"tea": 4, "lemon_tea": 3, "ginger_tea": 2},
		"snacks": {"biscuit": 0.3, "bun": 0.2},
		"skin": Color("9a6440"), "shirt": Color("f4f6f8"), "legs": Color("f4f6f8"), "hair": Color("1a120d"),
		"hair_style": "bun",
	},
	"flower_seller": {
		"name": "Flower seller", "patience": 55.0, "tip": 2, "price_sense": 1.4,
		"drinks": {"tea": 5, "ginger_tea": 3},
		"snacks": {"vadai": 0.4, "bajji": 0.3},
		"skin": Color("7a4a2e"), "shirt": Color("3a8a3a"), "legs": Color("3a8a3a"), "hair": Color("1a120d"),
		"hair_style": "bun", "saree": Color("c0392b"), "flowers": true,
	},
}

## The day, in order. "from" and "to" are kadai clock minutes after midnight.
## "seconds" is how long the phase lasts in real time; a day is about five
## minutes. "spawn_gap" is the min/max real seconds between arrivals, and
## "mix" weights who shows up.
const PHASES := [
	{
		"id": "morning_rush", "name": "Morning rush", "from": 360, "to": 600, "seconds": 100.0,
		"spawn_gap": Vector2(5.0, 9.0),
		"mix": {"office": 3, "auto_driver": 3, "student": 2, "uncle": 2, "nurse": 2, "metro_worker": 1},
	},
	{
		"id": "afternoon", "name": "Quiet afternoon", "from": 600, "to": 960, "seconds": 60.0,
		"spawn_gap": Vector2(12.0, 20.0),
		"mix": {"uncle": 3, "auto_driver": 2, "flower_seller": 2, "student": 1},
	},
	{
		"id": "evening_rush", "name": "Evening rush", "from": 960, "to": 1200, "seconds": 100.0,
		"spawn_gap": Vector2(5.0, 9.0),
		"mix": {"student": 3, "metro_worker": 3, "office": 2, "auto_driver": 2, "nurse": 1, "flower_seller": 1},
	},
	{
		"id": "closing", "name": "Closing time", "from": 1200, "to": 1320, "seconds": 40.0,
		"spawn_gap": Vector2(14.0, 22.0),
		"mix": {"auto_driver": 2, "metro_worker": 1},
	},
]
## No new customers after 9:30 PM.
const LAST_ARRIVAL_MINUTE := 1290
## Gaps between arrivals are stretched on the first days so the week starts
## gently. Index 0 is day 1; later days use the last value.
const DAY_PACE: Array[float] = [1.6, 1.35, 1.15, 1.0]


static func pace_for_day(day: int) -> float:
	return DAY_PACE[clampi(day - 1, 0, DAY_PACE.size() - 1)]

const SEATS := 4
## Seconds a grumbling customer keeps waiting before they give up and leave
## without paying, so an order you can't make never blocks the counter.
const GRUMBLE_LIMIT := 45.0
## How many glasses fit on the tray, and how many fried snacks on the plate.
## The bigger counter raises both.
const TRAY_GLASSES := 6
const FRY_PLATE := 8
const BIG_COUNTER_TRAY := 8
const BIG_COUNTER_PLATE := 12

## Reputation: the kadai level rises with happy customers. These are the
## points needed for each level, starting at level 1.
const LEVEL_POINTS: Array[int] = [0, 40, 140, 260, 420, 600, 820, 1100]
const POINTS_SERVED := 2
const POINTS_PERFECT := 1
const POINTS_GRUMPY := 1
const POINTS_RADIO := 1
const POINTS_GOAL := 15

## Small goals for each week. Targets grow a little every week.
const WEEK_GOALS := [
	{"id": "served", "text": "Serve %s customers", "base": 120, "growth": 30},
	{"id": "perfect", "text": "Pour %s perfect teas", "base": 50, "growth": 15},
	{"id": "revenue", "text": "Take %s in sales", "base": 2500, "growth": 600, "money": true},
]
const GOAL_REWARD := 100

## Things to save up for, bought on the night screen. "level" is the kadai
## level needed before it's for sale.
const UPGRADES := {
	"bench": {"name": "Bench", "cost": 350, "level": 1, "about": "Room for one more customer."},
	"pot": {"name": "Bigger milk pot", "cost": 450, "level": 1, "about": "Glasses fill twice as fast."},
	"paint": {"name": "Fresh paint & sign", "cost": 400, "level": 2, "about": "A smart kadai earns bigger tips."},
	"plants": {"name": "Plants & string lights", "cost": 500, "level": 3, "about": "Customers wait more happily."},
	"fan": {"name": "Table fan", "cost": 700, "level": 3, "about": "Customers stay patient much longer."},
	"radio": {"name": "Radio & posters", "cost": 800, "level": 4, "about": "Good vibes: more reputation per customer."},
	"counter": {"name": "Bigger counter", "cost": 1100, "level": 5, "about": "Room for 8 glasses and 12 fries."},
	"sign": {"name": "Lit signboard", "cost": 1400, "level": 5, "about": "More customers in the evening."},
}
const UPGRADE_ORDER: Array[String] = ["bench", "pot", "paint", "plants", "fan", "radio", "counter", "sign"]
const FAN_PATIENCE := 1.5
const PLANTS_PATIENCE := 1.15
const PAINT_TIPS := 1.25
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


## The kadai level for these reputation points.
static func level_for(points: int) -> int:
	var level := 1
	for i in LEVEL_POINTS.size():
		if points >= LEVEL_POINTS[i]:
			level = i + 1
	return level


## Menu items that unlock at exactly this level.
static func unlocks_at(level: int) -> Array[String]:
	var items: Array[String] = []
	for item in MENU_ORDER:
		if int(MENU[item].get("level", 0)) == level:
			items.append(item)
	return items


## The week's goals as [{"id", "text", "target"}] for a week number from 1.
static func goals_for_week(week: int) -> Array[Dictionary]:
	var goals: Array[Dictionary] = []
	for goal in WEEK_GOALS:
		var target := int(goal["base"]) + int(goal["growth"]) * (week - 1)
		var shown := ("₹%d" % target) if goal.get("money", false) else str(target)
		goals.append({"id": goal["id"], "text": goal["text"] % shown, "target": target})
	return goals


static func week_of(day: int) -> int:
	return (day - 1) / 7 + 1


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
