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
## Reputation points. The kadai level comes from these.
var reputation := 0
## This week's running totals for the goals, and which goals are done.
var week := {}
## Helper id -> how many you own.
var helpers := {}
## Staff hired and boosts bought.
var staff: Array[String] = []
var boosts: Array[String] = []
## Everything earned ever, and since this branch opened.
var earned_total := 0
var branch_earned := 0
## How many new branches you've opened; 0 is the first kadai.
var branches := 0
## Helper id -> upgrade tiers bought (each doubles that helper).
var tiers := {}
## All-time counts that never reset: served, perfect, poured, fried, golden,
## frenzies, days, seconds.
var stats := {}
## Achievement ids earned, and how many big-number milestones have been seen.
var achievements: Array[String] = []
var big_numbers_seen := 0
## Lines for the next morning's paper, like a milestone story.
var news: Array[String] = []


func _init() -> void:
	money = Catalog.START_MONEY
	stock = Catalog.START_STOCK.duplicate()
	for item in Catalog.MENU:
		prices[item] = Catalog.MENU[item]["price"]
	_reset_today()
	_reset_week()


func next_day() -> void:
	day += 1
	_reset_today()
	if (day - 1) % 7 == 0:
		_reset_week()


func _reset_week() -> void:
	week = {"served": 0, "perfect": 0, "revenue": 0, "tips": 0, "best_streak": 0, "stars": [], "done": []}


func _reset_today() -> void:
	today = {
		"revenue": 0, "tips": 0, "spent": 0, "upgrades": 0,
		"served": 0, "waited_long": 0, "gave_up": 0, "out_of_stock": 0, "too_costly": 0, "no_seat": 0, "wasted": 0,
		"perfect": 0, "best_streak": 0, "points": 0, "helpers": 0,
		"sold": {}, "bought": {}, "met": [], "level_ups": [], "goals_done": [],
	}


# --- Saving ---------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": 1, "day": day, "money": money, "stock": stock, "prices": prices,
		"upgrades": upgrades, "recipes": recipes, "regulars": regulars, "best_streak": best_streak,
		"reputation": reputation, "week": week,
		"helpers": helpers, "staff": staff, "boosts": boosts,
		"earned_total": earned_total, "branch_earned": branch_earned, "branches": branches,
		"tiers": tiers, "stats": stats, "achievements": achievements, "big_numbers_seen": big_numbers_seen,
		"news": news,
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
	state.reputation = maxi(0, int(data.get("reputation", 0)))
	var saved_week: Dictionary = data.get("week", {})
	for key in ["served", "perfect", "revenue", "tips", "best_streak"]:
		state.week[key] = int(saved_week.get(key, 0))
	for stars in saved_week.get("stars", []):
		state.week["stars"].append(int(stars))
	for id in saved_week.get("done", []):
		state.week["done"].append(str(id))
	var saved_helpers: Dictionary = data.get("helpers", {})
	for id in saved_helpers:
		if Catalog.HELPERS.has(id):
			state.helpers[id] = maxi(0, int(saved_helpers[id]))
	for id in data.get("staff", []):
		if Catalog.STAFF.has(id) and not state.staff.has(id):
			state.staff.append(id)
	var saved_tiers: Dictionary = data.get("tiers", {})
	for id in saved_tiers:
		if Catalog.HELPERS.has(id):
			state.tiers[id] = clampi(int(saved_tiers[id]), 0, Milestones.TIER_COUNTS.size())
	for id in data.get("boosts", []):
		if Catalog.BOOSTS.has(id) and not state.boosts.has(id):
			state.boosts.append(id)
		elif Catalog.OLD_HELPER_BOOSTS.has(id):
			var helper: String = Catalog.OLD_HELPER_BOOSTS[id]
			state.tiers[helper] = maxi(1, int(state.tiers.get(helper, 0)))
	var saved_stats: Dictionary = data.get("stats", {})
	for key in saved_stats:
		state.stats[str(key)] = maxi(0, int(saved_stats[key]))
	for id in data.get("achievements", []):
		if not Milestones.achievement(str(id)).is_empty() and not state.achievements.has(str(id)):
			state.achievements.append(str(id))
	state.big_numbers_seen = maxi(0, int(data.get("big_numbers_seen", 0)))
	for line in data.get("news", []):
		state.news.append(str(line))
	state.earned_total = maxi(0, int(data.get("earned_total", 0)))
	state.branch_earned = maxi(0, int(data.get("branch_earned", 0)))
	state.branches = maxi(0, int(data.get("branches", 0)))
	return state


# --- Menu, upgrades and regulars ------------------------------------------

## Menu items on sale: the starting menu, plus anything unlocked by the
## kadai level or learned from a regular.
func menu() -> Array[String]:
	var items: Array[String] = []
	for item in Catalog.MENU_ORDER:
		var info: Dictionary = Catalog.MENU[item]
		if info.get("learned", false) and not recipes.has(item):
			continue
		if int(info.get("level", 0)) > level():
			continue
		items.append(item)
	return items


func level() -> int:
	return Catalog.level_for(reputation)


## Progress through the current level, from 0 to 1. 1 at the top level.
func level_progress() -> float:
	var current := level()
	if current >= Catalog.LEVEL_POINTS.size():
		return 1.0
	var low := Catalog.LEVEL_POINTS[current - 1]
	var high := Catalog.LEVEL_POINTS[current]
	return float(reputation - low) / float(high - low)


## Adds reputation, noting any new level reached today.
func add_points(amount: int) -> void:
	var before := level()
	reputation += amount
	today["points"] += amount
	for reached in range(before + 1, level() + 1):
		today["level_ups"].append(reached)


## This week's goals with progress: [{"id", "text", "target", "value", "done"}].
func week_goals() -> Array[Dictionary]:
	var goals := Catalog.goals_for_week(Catalog.week_of(day))
	for goal in goals:
		goal["value"] = int(week.get(goal["id"], 0))
		goal["done"] = week["done"].has(goal["id"])
	return goals


## Wraps up the day for the night screen: pays out goals, and notes the
## day's stars and best streak in the week's record.
func close_day() -> void:
	claim_goals()
	count("days")
	week["stars"].append(stars_today())
	week["best_streak"] = maxi(int(week.get("best_streak", 0)), int(today["best_streak"]))


## A morning safety net: nearly broke and low on tea means Amma sends money.
## Returns the amount sent, or 0.
func morning_help() -> int:
	if money >= Catalog.HELP_BELOW or how_many("tea") >= 10:
		return 0
	money += Catalog.HELP_AMOUNT
	return Catalog.HELP_AMOUNT


func is_week_end() -> bool:
	return day % 7 == 0


## Pays out any goal reached since the last check. Returns the goals just done.
func claim_goals() -> Array[Dictionary]:
	var claimed: Array[Dictionary] = []
	for goal in week_goals():
		if not goal["done"] and int(goal["value"]) >= int(goal["target"]):
			week["done"].append(goal["id"])
			money += Catalog.GOAL_REWARD
			add_points(Catalog.POINTS_GOAL)
			today["goals_done"].append(goal["text"])
			claimed.append(goal)
	return claimed


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
	_earn(price)
	today["revenue"] += price
	week["revenue"] = int(week["revenue"]) + price
	today["sold"][item] = int(today["sold"].get(item, 0)) + 1
	return price


func record_tip(amount: int) -> void:
	_earn(amount)
	today["tips"] += amount
	week["tips"] = int(week.get("tips", 0)) + amount


## Lost customers today: waited too long, left over missing stock, or found no seat.
func lost_today() -> int:
	return int(today["waited_long"]) + int(today.get("gave_up", 0)) + int(today["out_of_stock"]) + int(today["no_seat"])


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


func _earn(amount: int) -> void:
	money += amount
	earned_total += amount
	branch_earned += amount


# --- Helpers, staff, boosts and branches ----------------------------------

func helper_count(id: String) -> int:
	return int(helpers.get(id, 0))


## The next one costs a little more than the last.
func helper_cost(id: String) -> int:
	var base := float(Catalog.HELPERS[id]["cost"])
	return ceili(base * pow(Catalog.HELPER_COST_GROWTH, helper_count(id)))


func buy_helper(id: String) -> bool:
	var cost := helper_cost(id)
	if money < cost:
		return false
	money -= cost
	helpers[id] = helper_count(id) + 1
	return true


## Rupees per second one helper of this type earns, with its tiers, boosts,
## branches and achievements.
func helper_income(id: String) -> float:
	var income := float(Catalog.HELPERS[id]["income"]) * pow(2.0, tier(id))
	for boost in boosts:
		if Catalog.BOOSTS[boost].get("all", false):
			income *= 2.0
	return income * branch_multiplier() * achievement_multiplier()


## Rupees per second all helpers earn together.
func income_per_second() -> float:
	var total := 0.0
	for id in helpers:
		total += helper_income(id) * helper_count(id)
	return total


## Adds money helpers earned (not counted as counter sales).
func record_helper_income(amount: int) -> void:
	_earn(amount)
	today["helpers"] += amount


func has_staff(id: String) -> bool:
	return staff.has(id)


func can_hire(id: String) -> bool:
	var info: Dictionary = Catalog.STAFF[id]
	return not has_staff(id) and level() >= int(info["level"]) and money >= int(info["cost"])


func hire(id: String) -> bool:
	if not can_hire(id):
		return false
	money -= int(Catalog.STAFF[id]["cost"])
	staff.append(id)
	return true


func has_boost(id: String) -> bool:
	return boosts.has(id)


## Whether a boost is on offer yet.
func boost_unlocked(id: String) -> bool:
	return total_helpers() >= int(Catalog.BOOSTS[id].get("needs_total", 0))


func total_helpers() -> int:
	var total := 0
	for helper in helpers:
		total += helper_count(helper)
	return total


## Upgrade tiers bought for this helper.
func tier(id: String) -> int:
	return int(tiers.get(id, 0))


## The helper's next tier if you own enough of them for it, or -1.
func next_tier(id: String) -> int:
	var next := tier(id)
	if next >= Milestones.TIER_COUNTS.size() or helper_count(id) < Milestones.TIER_COUNTS[next]:
		return -1
	return next


func buy_tier(id: String) -> bool:
	var next := next_tier(id)
	if next < 0 or money < Milestones.tier_cost(id, next):
		return false
	money -= Milestones.tier_cost(id, next)
	tiers[id] = next + 1
	return true


func buy_boost(id: String) -> bool:
	var cost := int(Catalog.BOOSTS[id]["cost"])
	if has_boost(id) or not boost_unlocked(id) or money < cost:
		return false
	money -= cost
	boosts.append(id)
	return true


## Tips multiplier from boosts and branches.
func tip_multiplier() -> float:
	var times := branch_multiplier() * achievement_multiplier()
	for boost in boosts:
		if Catalog.BOOSTS[boost].get("tips", false):
			times *= 2.0
	return times


## Every branch opened adds a permanent bonus.
func branch_multiplier() -> float:
	return 1.0 + Catalog.BRANCH_BONUS * branches


func branch_name() -> String:
	return Catalog.BRANCHES[branches % Catalog.BRANCHES.size()]


func next_branch_name() -> String:
	return Catalog.BRANCHES[(branches + 1) % Catalog.BRANCHES.size()]


func can_open_branch() -> bool:
	return branch_earned >= Catalog.BRANCH_NEEDS


## Starts fresh in a new part of Chennai: money, stock, prices, level,
## upgrades, helpers, staff and boosts reset; the story, regulars, recipes and
## the day carry on, and the new branch earns a permanent bonus.
func open_branch() -> bool:
	if not can_open_branch():
		return false
	var fresh := KadaiState.new()
	money = fresh.money
	stock = fresh.stock
	prices = fresh.prices
	reputation = 0
	upgrades.clear()
	helpers.clear()
	tiers.clear()
	staff.clear()
	boosts.clear()
	branch_earned = 0
	branches += 1
	return true


# --- Stats, achievements and milestones -----------------------------------

## Adds to an all-time count.
func count(key: String, amount: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


## An all-time number by name, for achievements and the stats page.
func stat(key: String) -> int:
	if key.begins_with("helper:"):
		return helper_count(key.trim_prefix("helper:"))
	match key:
		"earned":
			return earned_total
		"helpers":
			return total_helpers()
		"branches":
			return branches
		"best_streak":
			return best_streak
		"staff":
			return staff.size()
		"boosts":
			return boosts.size()
	return int(stats.get(key, 0))


func achievement_multiplier() -> float:
	return 1.0 + Milestones.ACHIEVEMENT_BONUS * achievements.size()


## Marks any achievements just reached, and returns them.
func check_achievements() -> Array[Dictionary]:
	var earned: Array[Dictionary] = []
	for entry in Milestones.ACHIEVEMENTS:
		if not achievements.has(entry["id"]) and stat(entry["stat"]) >= int(entry["at"]):
			achievements.append(entry["id"])
			earned.append(entry)
	return earned


## Big-number milestones just passed; each also goes in tomorrow's paper.
func check_big_numbers() -> Array[Dictionary]:
	var passed: Array[Dictionary] = []
	while big_numbers_seen < Milestones.big_numbers_passed(earned_total):
		var milestone: Dictionary = Milestones.BIG_NUMBERS[big_numbers_seen]
		passed.append(milestone)
		news.append(milestone["line"])
		big_numbers_seen += 1
	return passed


## Pays out what helpers earned while you were away, and returns it.
func collect_away(seconds: float) -> int:
	var amount := away_earnings(seconds)
	_earn(amount)
	return amount


## What helpers earned while you were away for this many seconds.
func away_earnings(seconds: float) -> int:
	var capped := clampf(seconds, 0.0, Catalog.AWAY_MAX_HOURS * 3600.0)
	return floori(income_per_second() * capped * Catalog.AWAY_RATE)


func profit_today() -> int:
	return int(today["revenue"]) + int(today["tips"]) + int(today["helpers"]) - int(today["spent"])
