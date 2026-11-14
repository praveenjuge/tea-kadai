class_name Milestones
extends RefCounted
## Long-term goals: tiered upgrades for each helper, achievements (each one
## adds a little to all earnings), and the big Indian number milestones that
## make the kadai grander and get it into the papers.

## A helper's upgrade tiers unlock at these counts owned. Each doubles them.
const TIER_COUNTS: Array[int] = [1, 10, 25, 50, 100]
## Each tier costs the helper's base price times this.
const TIER_COST_TIMES: Array[int] = [10, 50, 500, 5000, 50000]
const TIER_NAMES: Array[String] = ["Better tea", "Faster feet", "Regular rounds", "Famous name", "Legend of Chennai"]

## Every achievement adds this much to helper income and tips.
const ACHIEVEMENT_BONUS := 0.01

## Lifetime earnings milestones, in the Indian number system.
const BIG_NUMBERS: Array[Dictionary] = [
	{"amount": 100000, "name": "one lakh", "line": "Local kadai crosses one lakh! Owner says \"just tea, sir\"."},
	{"amount": 1000000, "name": "ten lakh", "line": "Ten lakh rupees of tea: the kadai is the talk of the street."},
	{"amount": 10000000, "name": "one crore", "line": "Tea kadai owner is a crorepati! Still pours every glass by hand."},
	{"amount": 100000000, "name": "ten crore", "line": "Ten crore! Economists study the \"kadai effect\" on the city."},
	{"amount": 1000000000, "name": "one arab", "line": "One arab rupees. Chennai's tea now has its own stock ticker."},
	{"amount": 100000000000, "name": "one kharab", "line": "One kharab! ISRO asks if the tea can go to space."},
	{"amount": 10000000000000, "name": "one neel", "line": "One neel rupees. The moon has requested a branch."},
	{"amount": 1000000000000000, "name": "one padma", "line": "One padma. Scientists confirm: the universe runs on tea."},
]

## Achievements. "stat" is what's measured, "at" the target. Stats come from
## KadaiState.stat(): served, perfect, poured, fried, golden, frenzies,
## earned, helpers, branches, days, best_streak, staff, boosts, or
## "helper:<id>" for how many of one helper you own.
const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "earn_1k", "name": "Kai raasi", "about": "Earn ₹1,000 in all.", "stat": "earned", "at": 1000},
	{"id": "earn_10k", "name": "Small change", "about": "Earn ₹10,000 in all.", "stat": "earned", "at": 10000},
	{"id": "earn_lakh", "name": "Lakh club", "about": "Earn one lakh in all.", "stat": "earned", "at": 100000},
	{"id": "earn_10lakh", "name": "Ten lakh tea", "about": "Earn ten lakh in all.", "stat": "earned", "at": 1000000},
	{"id": "earn_crore", "name": "Crorepati", "about": "Earn one crore in all.", "stat": "earned", "at": 10000000},
	{"id": "earn_10crore", "name": "Tea tycoon", "about": "Earn ten crore in all.", "stat": "earned", "at": 100000000},
	{"id": "earn_arab", "name": "Arab of tea", "about": "Earn one arab in all.", "stat": "earned", "at": 1000000000},
	{"id": "earn_kharab", "name": "Kharab king", "about": "Earn one kharab in all.", "stat": "earned", "at": 100000000000},
	{"id": "served_100", "name": "Regular face", "about": "Serve 100 customers.", "stat": "served", "at": 100},
	{"id": "served_1000", "name": "Whole street", "about": "Serve 1,000 customers.", "stat": "served", "at": 1000},
	{"id": "served_10000", "name": "Half of Chennai", "about": "Serve 10,000 customers.", "stat": "served", "at": 10000},
	{"id": "perfect_50", "name": "Steady hand", "about": "Pour 50 perfect glasses.", "stat": "perfect", "at": 50},
	{"id": "perfect_500", "name": "Meter-tea master", "about": "Pour 500 perfect glasses.", "stat": "perfect", "at": 500},
	{"id": "perfect_5000", "name": "The pour", "about": "Pour 5,000 perfect glasses.", "stat": "perfect", "at": 5000},
	{"id": "poured_1000", "name": "Thousand glasses", "about": "Pour 1,000 glasses of anything.", "stat": "poured", "at": 1000},
	{"id": "fried_100", "name": "Oil and fire", "about": "Fry 100 batches.", "stat": "fried", "at": 100},
	{"id": "streak_5", "name": "On a roll", "about": "Pour 5 perfect glasses in a row.", "stat": "best_streak", "at": 5},
	{"id": "streak_10", "name": "Untouchable", "about": "Pour 10 perfect glasses in a row.", "stat": "best_streak", "at": 10},
	{"id": "golden_1", "name": "Golden glass", "about": "Click a golden glass.", "stat": "golden", "at": 1},
	{"id": "golden_10", "name": "Eagle eyes", "about": "Click 10 golden glasses.", "stat": "golden", "at": 10},
	{"id": "golden_50", "name": "Gold rush", "about": "Click 50 golden glasses.", "stat": "golden", "at": 50},
	{"id": "frenzy_1", "name": "Frenzy!", "about": "Start a helper frenzy.", "stat": "frenzies", "at": 1},
	{"id": "helpers_10", "name": "Small team", "about": "Own 10 helpers.", "stat": "helpers", "at": 10},
	{"id": "helpers_50", "name": "Tea network", "about": "Own 50 helpers.", "stat": "helpers", "at": 50},
	{"id": "helpers_100", "name": "Tea empire", "about": "Own 100 helpers.", "stat": "helpers", "at": 100},
	{"id": "helpers_250", "name": "Everyone works for you", "about": "Own 250 helpers.", "stat": "helpers", "at": 250},
	{"id": "flask_25", "name": "Flask army", "about": "Own 25 flask boys.", "stat": "helper:flask_boy", "at": 25},
	{"id": "runner_25", "name": "Every floor", "about": "Own 25 office tea runners.", "stat": "helper:office_runner", "at": 25},
	{"id": "cart_25", "name": "Bus stand boss", "about": "Own 25 bus stand carts.", "stat": "helper:bus_cart", "at": 25},
	{"id": "college_25", "name": "Exam season", "about": "Own 25 college gate stalls.", "stat": "helper:college_stall", "at": 25},
	{"id": "train_25", "name": "Chai chai coffee", "about": "Own 25 train vendors.", "stat": "helper:train_vendor", "at": 25},
	{"id": "film_10", "name": "Lights, camera, tea", "about": "Own 10 film set caterers.", "stat": "helper:film_catering", "at": 10},
	{"id": "staff_all", "name": "Family business", "about": "Hire all three staff.", "stat": "staff", "at": 3},
	{"id": "boosts_all", "name": "Fully boosted", "about": "Buy every boost.", "stat": "boosts", "at": 3},
	{"id": "branch_1", "name": "Second kadai", "about": "Open a branch.", "stat": "branches", "at": 1},
	{"id": "branch_3", "name": "Chain of kadais", "about": "Open 3 branches.", "stat": "branches", "at": 3},
	{"id": "branch_10", "name": "All over Chennai", "about": "Open 10 branches.", "stat": "branches", "at": 10},
	{"id": "days_7", "name": "One week in", "about": "Run the kadai for 7 days.", "stat": "days", "at": 7},
	{"id": "days_30", "name": "A month of mornings", "about": "Run the kadai for 30 days.", "stat": "days", "at": 30},
	{"id": "days_100", "name": "Hundred days", "about": "Run the kadai for 100 days.", "stat": "days", "at": 100},
]


## How many big-number milestones this lifetime total has passed.
static func big_numbers_passed(earned: int) -> int:
	var count := 0
	for milestone in BIG_NUMBERS:
		if earned >= int(milestone["amount"]):
			count += 1
	return count


static func achievement(id: String) -> Dictionary:
	for entry in ACHIEVEMENTS:
		if entry["id"] == id:
			return entry
	return {}


static func tier_cost(helper: String, tier: int) -> int:
	return int(Catalog.HELPERS[helper]["cost"]) * TIER_COST_TIMES[tier]
