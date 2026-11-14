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
		## Friendship needed for each unlock.
		"big_tips_at": 30, "teach_at": 20, "friends_at": 40,
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
}


## Today's visit for a regular, or an empty Dictionary if they don't come.
static func visit(id: String, day: int) -> Dictionary:
	var regular: Dictionary = REGULARS[id]
	var days: Dictionary = regular["days"]
	if days.has(day):
		return days[day]
	if day > days.size():
		var later: Dictionary = regular["later"]
		var lines: Array = later["lines"]
		return {
			"minute": later["minute"], "order": later["order"],
			"arrive": "The usual, anna!", "served": lines[day % lines.size()],
		}
	return {}


## The night screen's line about this regular after today.
static func hook(id: String, day: int) -> String:
	return visit(id, day).get("hook", "")
