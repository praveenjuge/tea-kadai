class_name Story
extends RefCounted
## The regulars and their stories. Each regular has a look, a usual order, and
## a visit for each day of the first week. After the week they keep dropping by
## with their usual order and a friendly line.
##
## A day's visit can have:
##   minute    kadai clock minute they arrive (360 = 6:00 AM)
##   order     what they want; "usual" means their usual order, unnamed
##   arrive    what they say when they get to the counter
##   wait      what they say while waiting
##   ask       a question with two answers to pick from, each with a reply and
##             a friendship change
##   served    what they say once served
##   teach     a recipe they teach you on this visit (once friendly enough)
##   friends   how many friends they bring along (once friendly enough);
##             "arrive_alone" is what they say if you're not close enough yet
##   lucky     they want a perfect pour; "lucky_yes" / "lucky_no" replies
##   treat     they pay double tips for everyone for the rest of the evening
##   hook      the night screen's line about what happens next

const REGULARS := {
	"karthik": {
		"name": "Karthik",
		"about": "Final-year engineering student. Final year, again.",
		"patience": 60.0, "tip": 3,
		"shirt": Color("7b4fb8"), "legs": Color("2d3a5a"), "hair": Color("1a120d"), "bag": Color("c0392b"),
		"skin": Color("8d5a3b"), "glasses": true, "hair_style": "long",
		"usual": {"tea": 1, "bun": 1},
		"usual_from_day": 3,
		## Seconds his usual order stays hidden before the bubble gives a hint.
		"usual_hint_after": 12.0,
		"usual_hint": "Tea and a bun, anna. Same as always!",
		## Friendship needed for each unlock.
		"big_tips_at": 30, "teach_at": 20, "friends_at": 40,
		## The recipe he teaches once friendly enough, from this day, and the
		## stock his amma sends along with it.
		"teaches": "ginger_tea", "teach_from_day": 3, "teach_gift": {"ginger": 20},
		"teach_line": "Anna, crush some ginger into the decoction. My amma's trick!",
		"friend_type": "student",
		"days": {
			1: {
				"minute": 430, "order": {"tea": 1, "bun": 1},
				"arrive": "Anna, one tea. Strong-a. I'm Karthik. Final year… well, final year again.",
				"wait": "Professor says I'm \"very creative in exams\". I think it's a compliment.",
				"served": "Pay you tomorrow anna! …Joking, joking. Here.",
				"hook": "Karthik mentioned \"one small arrear\". How small, you wonder.",
			},
			2: {
				"minute": 445, "order": {"tea": 1, "bun": 1},
				"arrive": "Anna! Same as yesterday. You remember, no?",
				"ask": {
					"q": "Anna, big match tonight. Should I study or watch?",
					"options": [
						{"text": "Study, da!", "reply": "Okay okay… I'll study. During the ad breaks.", "friendship": 8},
						{"text": "Match first!", "reply": "Correct answer! You're my kind of anna.", "friendship": 5},
					],
				},
				"served": "If I fail, I'm blaming your tea. If I pass, I'm crediting it.",
				"hook": "Karthik left his notes on your bench. The first page just says \"HOPE\".",
			},
			3: {
				"minute": 425, "order": "usual",
				"arrive": "The usual, anna. You know it.",
				"teach": "ginger_tea",
				"wait": "My amma crushes ginger into the decoction. Try it! Customers will love it.",
				"served": "Ginger tea next time, okay? I'll be your first customer.",
				"hook": "Karthik's exam is on Saturday. He looked… calm? Suspiciously calm.",
			},
			4: {
				"minute": 450, "order": "usual", "friends": 2,
				"arrive": "Anna, my friends. I told them your tea is better than my future.",
				"arrive_alone": "My friends were supposed to come. They're \"busy\". The usual, anna.",
				"ask": {
					"q": "Anna, can you lend me ten rupees for photocopies?",
					"options": [
						{"text": "Here, take it", "reply": "Anna, you're a legend. Pay you tomorrow. For real.", "friendship": 10, "money": -10},
						{"text": "Pay you tomorrow?", "reply": "Using my own line on me?! Respect.", "friendship": 6},
					],
				},
				"served": "College, then library. Don't tell anyone, it'll ruin my image.",
				"hook": "His friends swear Karthik was in the library all day. Nobody believes them.",
			},
			5: {
				"minute": 435, "order": {"tea": 2},
				"arrive": "Studied till 3 AM. Two teas. The strongest in Chennai.",
				"ask": {
					"q": "Quiz me, anna. Anything!",
					"options": [
						{"text": "What's Ohm's law?", "reply": "V equals I R! …Anna, are you secretly an engineer?", "friendship": 8},
						{"text": "Just drink your tea", "reply": "Peace. Correct. Tea first, Ohm later.", "friendship": 4},
					],
				},
				"served": "Tomorrow is the exam. Make tomorrow's tea lucky, okay?",
				"hook": "Tomorrow is the exam. Karthik wants a lucky tea before he goes.",
			},
			6: {
				"minute": 450, "order": {"tea": 1}, "lucky": true,
				"arrive": "Exam today, anna. One lucky tea. Perfect froth only!",
				"lucky_yes": "Perfect froth! Now I can't fail. Science.",
				"lucky_no": "It's fine… luck is overrated. Right? RIGHT?",
				"hook": "Results come out tomorrow evening. The whole street is nervous for him.",
			},
			7: {
				"minute": 610, "order": "usual", "treat": true,
				"arrive": "ANNA! Results just came out! PASSED! ALL CLEAR! Tea for everyone, on me!",
				"wait": "…Okay, on you. I'll pay tomorrow. JOKING. Here's the money!",
				"served": "Engineer Karthik will still come here every morning. Promise.",
				"hook": "Karthik passed! He'll be back every morning, now as an engineer who drinks too much tea.",
			},
		},
		## After the first week.
		"later": {
			"minute": 440, "order": "usual",
			"lines": [
				"Office work is just exams that pay, anna.",
				"My manager wants a report. I want tea.",
				"Still can't believe I passed. Neither can my professor.",
				"Amma says hi. She wants your vadai recipe.",
			],
		},
	},
	"murugan": {
		"name": "Murugan",
		"about": "Auto driver, cricket mad. Rents his auto, dreams of owning one.",
		"patience": 55.0, "tip": 3,
		"shirt": Color("d9b44a"), "legs": Color("6b5a3a"), "hair": Color("1e1612"),
		"skin": Color("6e4329"), "mustache": true,
		"usual": {"tea": 1, "vadai": 1},
		"usual_from_day": 10,
		"usual_hint_after": 12.0,
		"usual_hint": "Strong tea and one vadai, like always!",
		"big_tips_at": 30, "friends_at": 40,
		"friend_type": "auto_driver",
		"days": {
			8: {
				"minute": 400, "order": {"tea": 1, "vadai": 1},
				"arrive": "Vanakkam! Murugan, from the auto stand at the corner. One strong tea, less sugar.",
				"wait": "Twelve years driving someone else's auto. One day, my own. You'll see.",
				"served": "Good tea! I'll tell all the auto stand fellows.",
				"hook": "Murugan rents his auto by the day. He's been saving for his own for years.",
			},
			9: {
				"minute": 395, "order": {"tea": 1, "vadai": 1},
				"arrive": "Anna! India batting first today!",
				"ask": {
					"q": "Three hundred runs today, anna? Yes or no?",
					"options": [
						{"text": "Easily!", "reply": "That's the spirit! Free ride to the beach if we win!", "friendship": 6},
						{"text": "Pray first", "reply": "Ha! Correct. Prayer first, then runs.", "friendship": 8},
					],
				},
				"served": "If we lose, I'm blaming the bowling. Never the tea.",
				"hook": "Murugan's savings tin is almost full. He shakes it for luck every night.",
			},
			10: {
				"minute": 405, "order": "usual",
				"arrive": "The usual, anna. Rain or shine, autos run.",
				"wait": "Tea first, then customers. That's my rule.",
				"served": "Perfect. Now I can drive till lunch.",
				"hook": "Murugan saw an auto for sale. Second-hand, green, a little dented. Perfect.",
			},
			11: {
				"minute": 400, "order": "usual", "friends": 2,
				"arrive": "Anna, the auto stand fellows. I told them, best tea in the area!",
				"arrive_alone": "The usual, anna. My friends are still asleep, lazy fellows.",
				"ask": {
					"q": "Two thousand short for the auto. Should I take a loan?",
					"options": [
						{"text": "Save a bit longer", "reply": "You're right. Slow and steady, like my old auto.", "friendship": 8},
						{"text": "Go for it!", "reply": "Bold! I'll think about it over one more tea.", "friendship": 5},
					],
				},
				"served": "Extra hours this week. Every ride counts.",
				"hook": "He's driving extra hours this week. His eyes are tired, but he's smiling.",
			},
			12: {
				"minute": 390, "order": {"tea": 2},
				"arrive": "Night shift, morning shift. Two teas, anna. Strong.",
				"wait": "Just one more week of this. One more week.",
				"served": "Tomorrow I go to see the auto again.",
				"hook": "Tomorrow Murugan goes to buy the auto.",
			},
			13: {
				"minute": 395, "order": {"tea": 1}, "lucky": true,
				"arrive": "Today's the day, anna! Buying the auto! One lucky tea!",
				"lucky_yes": "Look at that froth! Today is a good day.",
				"lucky_no": "Hmm. It's fine. The auto doesn't care about froth.",
				"hook": "Murugan signed the papers. Tomorrow he picks up his very own auto.",
			},
			14: {
				"minute": 420, "order": "usual", "treat": true,
				"arrive": "ANNA! MY OWN AUTO! Look outside! First ride is free for you, always!",
				"wait": "Tea for everyone today. Murugan is paying!",
				"served": "Same time tomorrow. In my own auto!",
				"hook": "Murugan drives his own auto now. He parks it right outside your kadai.",
			},
		},
		"later": {
			"minute": 400, "order": "usual",
			"lines": [
				"My auto, my rules. Rule one: tea first.",
				"Took a foreigner to the beach. He loved your tea story.",
				"India won! I told you, prayer first!",
				"Petrol up again. But tea is still the same price, no anna?",
			],
		},
	},
}
## The order regulars appear in the game.
const REGULAR_ORDER: Array[String] = ["karthik", "murugan"]


## Today's visit for a regular, or an empty Dictionary if they don't come.
static func visit(id: String, day: int) -> Dictionary:
	var regular: Dictionary = REGULARS[id]
	var days: Dictionary = regular["days"]
	if days.has(day):
		return days[day]
	if day > days.keys().max():
		var later: Dictionary = regular["later"]
		var lines: Array = later["lines"]
		return {
			"minute": later["minute"], "order": later["order"],
			"arrive": "The usual, anna!", "served": lines[day % lines.size()],
		}
	return {}


## The first day a regular comes by.
static func first_day(id: String) -> int:
	return REGULARS[id]["days"].keys().min()


## The night screen's line about this regular after today.
static func hook(id: String, day: int) -> String:
	return visit(id, day).get("hook", "")
