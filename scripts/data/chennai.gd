class_name Chennai
extends RefCounted
## The city around the kadai: festivals on the calendar, the film releasing
## each Friday, the morning kolam, what's on the radio, and the Tamil and
## Tanglish words customers use, with a glossary. All films, stars, songs and
## stations here are made up.

## Festival and special days, by game day (day 1 is Monday 3 November 2025).
const FESTIVALS := {
	12: {"name": "Children's Day", "line": "Children's Day! School kids everywhere."},
	32: {"name": "Karthigai Deepam", "line": "Karthigai Deepam: lamps on every doorstep tonight.", "lamps": true},
	53: {"name": "Christmas", "line": "Christmas! Stars hanging over the street."},
	60: {"name": "New Year", "line": "Happy New Year! Everyone's up early, somehow."},
	72: {"name": "Bhogi", "line": "Bhogi: out with the old, bonfires at dawn."},
	73: {"name": "Pongal", "line": "Pongal! Sugarcane at every corner. Pongalo pongal!", "sugarcane": true},
	74: {"name": "Mattu Pongal", "line": "Mattu Pongal: the cows have painted horns today."},
}
## Margazhi, the kolam month: every morning's kolam is a big one.
const MARGAZHI := Vector2i(44, 72)

## A new film every Friday. Titles and stars are invented.
const FILMS: Array[Dictionary] = [
	{"title": "VETTAI RAJA", "star": "Mass Star Kathir", "color": Color("c23b2c")},
	{"title": "AUTO KING", "star": "Young Star Arun", "color": Color("2f6db5")},
	{"title": "SINGA PAARVAI", "star": "Mass Star Kathir", "color": Color("d9822b")},
	{"title": "MADRAS MAGIC", "star": "Nila", "color": Color("8e44ad")},
	{"title": "THUNDER THAMBI", "star": "Young Star Arun", "color": Color("16a085")},
	{"title": "KADAL KAATRU", "star": "Nila", "color": Color("2c3e8f")},
]

## Kolam colours, one palette picked per day.
const KOLAM_PALETTES: Array = [
	[Color("e0604e"), Color("ffca3a"), Color("8ac926"), Color("c77dff")],
	[Color("ff6fa8"), Color("ffd166"), Color("06d6a0"), Color("118ab2")],
	[Color("f15bb5"), Color("fee440"), Color("00bbf9"), Color("9b5de5")],
	[Color("e76f51"), Color("f4a261"), Color("e9c46a"), Color("2a9d8f")],
]
const KOLAM_STYLES: Array[String] = ["petals", "dots", "star", "lotus"]

## What the radio plays: songs most days, cricket on match days.
const SONGS: Array[String] = [
	"a peppy kuthu number from Vettai Raja",
	"an old Ilaiyaraaja-style melody",
	"a gaana song about the beach",
	"the morning devotional hour",
	"a love song everyone half-knows",
	"a dappankuthu remix. The auto drivers are dancing.",
]
const CRICKET: Array[Dictionary] = [
	{"text": "FOUR! Through the covers!", "cheer": true},
	{"text": "SIX! Out of the stadium!", "cheer": true, "six": true},
	{"text": "OUT! Clean bowled. The street goes quiet.", "cheer": false},
	{"text": "Dot ball. The tension, anna.", "cheer": false},
	{"text": "Fifty up for the captain!", "cheer": true},
]
const CRICKET_REACTIONS: Array[String] = ["Super shot!", "Semma!", "Adichaan paaru!", "Ayyo, no!", "Vera level!"]

## Extra chatter, in Tanglish.
const TANGLISH: Array[String] = [
	"Anna, oru tea strong-a!", "Semma heat-u today, ayyo.", "Machan, match paathiya?",
	"Konjam sugar kammi, please.", "Saapteengala, anna?", "Enna anna, rate jaasthi aagiducha?",
	"Vera level tea, I'm telling you.", "Office-ku late aagudhu!", "Paati made idli, but tea is tea.",
	"Auto-la vandhen, fare paathiya? Ayyo!", "Rain varum pola, umbrella illa.",
]
const FRIDAY_LINES: Array[String] = [
	"FDFS ticket kedachidhu! 4 AM show!", "Cutout paathiya? Twenty feet!", "Hero padam, mass-u!",
]
const AUTO_LINES: Array[String] = ["Meter? Meter-ellam illa, sir.", "Central-ku? Hundred fifty.", "Saar, auto venuma?"]

## Lines for the news ticker, sillier the bigger the kadai has grown. Each
## list adds to the ones before, by big-number milestones passed.
const TICKER: Array = [
	["Corporation fixes one pothole; residents hold a small function", "Auto meter spotted working in Egmore, experts baffled",
		"Filter coffee or tea? City split down the middle again", "Marina beach sundal prices steady, say vendors"],
	["Local kadai's flask boys now seen in three neighbourhoods", "\"Best tea on the street,\" says man who has tried two",
		"Office lifts slowed by tea runners, managers not complaining"],
	["Kadai tea served at a film launch; hero asks for second glass", "College exams postponed? No. Tea consumption up 300%",
		"Train passengers now plan journeys around the tea vendor"],
	["Economists propose the tumbler as a unit of currency", "Kadai owner declines Bollywood biopic: \"busy pouring\"",
		"Satellites detect steam rising over Chennai every morning", "Bay of Bengal 2% sweeter, scientists blame sugar spillage"],
]

## Tamil and Tanglish words heard at the kadai.
const GLOSSARY: Array[Array] = [
	["Anna / Akka", "Elder brother / sister. How you call the person at the counter."],
	["Machan", "Mate, buddy."],
	["Semma", "Awesome. \"Semma tea!\""],
	["Super-a irukku", "It's really good."],
	["Vera level", "On another level. High praise."],
	["Ayyo", "Oh no! For heat, rain, traffic and prices."],
	["Saapteengala?", "Have you eaten? A friendly hello."],
	["Konjam", "A little."],
	["Kammi / Jaasthi", "Less / more."],
	["Nandri", "Thank you."],
	["Kadai", "Shop. A tea kadai is a tea stall."],
	["Kolam", "Rice-flour patterns drawn at the doorstep every morning."],
	["Tumbler & davara", "The steel cup and bowl filter coffee is poured between."],
	["Decoction", "The strong coffee brew from a filter, mixed with hot milk."],
	["FDFS", "First Day First Show. Fans queue at dawn for a new film."],
	["Margazhi", "The cool month of big kolams and early music."],
	["Pongal", "The harvest festival in January, with sweet pongal and sugarcane."],
	["Karthigai Deepam", "The festival of lamps, lit on every doorstep."],
]


## Ticker lines unlocked at this many big-number milestones.
static func ticker(level: int) -> Array[String]:
	var lines: Array[String] = []
	for i in mini(level + 1, TICKER.size()):
		for line in TICKER[i]:
			lines.append(line)
	return lines


static func festival(day: int) -> Dictionary:
	return FESTIVALS.get(day, {})


static func is_margazhi(day: int) -> bool:
	return day >= MARGAZHI.x and day <= MARGAZHI.y


## Friday is release day.
static func is_release_day(day: int) -> bool:
	return (day - 1) % 7 == 4


## Saturday and Sunday are match days on the radio.
static func is_match_day(day: int) -> bool:
	return (day - 1) % 7 >= 5


## The film showing this week (it changes every Friday).
static func film(day: int) -> Dictionary:
	return FILMS[((day + 2) / 7) % FILMS.size()]


## How big today's kolam is: bigger on Sundays, festivals and in Margazhi.
static func kolam_size(day: int) -> float:
	if not festival(day).is_empty():
		return 1.6
	if is_margazhi(day):
		return 1.4
	if (day - 1) % 7 == 6:
		return 1.3
	return 1.0


## A headline for special days, or "" to use the usual one.
static func headline(day: int) -> String:
	var special := festival(day)
	if not special.is_empty():
		return special["line"]
	if is_release_day(day):
		var showing := film(day)
		return "%s's %s releases today; fans line up for the 4 AM show" % [showing["star"], showing["title"].capitalize()]
	return ""
