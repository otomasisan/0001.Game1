class_name Story
extends RefCounted
## 物語と謎の進行データ。コードを触らずに謎の流れを入れ替えられるよう、
## 「どこをクリックしたら何が起きるか」はすべてここに書く。
##
## RULES[ホットスポットID] = 上から順に調べ、最初に条件を満たしたルールを実行する。
##   "if":  条件の配列(GameState.check の書式)。省略可
##   "use": この持ち物を選んでクリックしたときだけ一致する。省略可
##   "do":  アクションの配列
##
## アクション:
##   ["say", テキストキー, 話し手("" / "moko" / "poppo")]
##   ["set", フラグ]         ["clear", フラグ]
##   ["give", 持ち物]        ["take", 持ち物]
##   ["goto", 部屋ID]        ["puzzle", 謎ID]
##   ["end_chapter", 章番号]
##
## 謎が解けたときは RULES["solved:<謎ID>"] が実行される。

const ROOMS := {
	"kitchen": "res://scenes/rooms/kitchen.tscn",
	"living_room": "res://scenes/rooms/living_room.tscn",
	"kids_room": "res://scenes/rooms/kids_room.tscn",
}

const PUZZLES := {
	"plates": "res://scenes/puzzles/plates_puzzle.tscn",
	"clock": "res://scenes/puzzles/clock_puzzle.tscn",
	"books": "res://scenes/puzzles/books_puzzle.tscn",
}

## 持ち物ID → 表示名キー
const ITEMS := {
	"plates": "ITEM_PLATES",
	"winding_key": "ITEM_WINDING_KEY",
	"kids_key": "ITEM_KIDS_KEY",
}

const RULES := {
	# ---- 台所 ----
	"kitchen_memo": [
		{"do": [["say", "KITCHEN_MEMO", ""], ["set", "read_memo"]]},
	],
	"kitchen_cupboard": [
		{"if": ["!got_plates"], "do": [
			["say", "KITCHEN_CUPBOARD", ""],
			["give", "plates"],
			["set", "got_plates"],
		]},
		{"do": [["say", "KITCHEN_CUPBOARD_EMPTY", ""]]},
	],
	"kitchen_table": [
		{"if": ["solved_plates"], "do": [["say", "KITCHEN_TABLE_DONE", "moko"]]},
		{"use": "plates", "do": [["puzzle", "plates"]]},
		{"if": ["got_plates"], "do": [["puzzle", "plates"]]},
		{"do": [["say", "KITCHEN_TABLE", ""]]},
	],
	"kitchen_window": [
		{"do": [["say", "KITCHEN_WINDOW", ""]]},
	],
	"kitchen_stove": [
		{"do": [["say", "KITCHEN_STOVE", ""]]},
	],
	"kitchen_to_living": [
		{"do": [["goto", "living_room"]]},
	],
	"solved:plates": [
		{"do": [
			["take", "plates"],
			["set", "solved_plates"],
			["say", "PLATES_SOLVED", "moko"],
			["say", "PLATES_DRAWER", ""],
			["give", "winding_key"],
		]},
	],

	# ---- 居間 ----
	"living_clock": [
		{"if": ["solved_clock"], "do": [["say", "CLOCK_STOPPED", ""]]},
		{"use": "winding_key", "do": [
			["take", "winding_key"],
			["set", "clock_wound"],
			["say", "CLOCK_WIND", ""],
			["say", "POPPO_HELLO", "poppo"],
		]},
		{"if": ["clock_wound"], "do": [["puzzle", "clock"]]},
		{"do": [["say", "CLOCK_UNWOUND", ""]]},
	],
	"living_calendar": [
		{"do": [["say", "LIVING_CALENDAR", ""]]},
	],
	"living_photo": [
		{"do": [["say", "LIVING_PHOTO", "moko"]]},
	],
	"living_sofa": [
		{"do": [["say", "LIVING_SOFA", ""]]},
	],
	"living_to_kitchen": [
		{"do": [["goto", "kitchen"]]},
	],
	"living_to_kids": [
		{"if": ["kids_door_open"], "do": [["goto", "kids_room"]]},
		{"if": ["has:kids_key"], "do": [
			["take", "kids_key"],
			["set", "kids_door_open"],
			["say", "KIDS_DOOR_UNLOCK", ""],
			["goto", "kids_room"],
		]},
		{"do": [["say", "KIDS_DOOR_LOCKED", ""]]},
	],
	"solved:clock": [
		{"do": [
			["set", "solved_clock"],
			["say", "CLOCK_SOLVED", "poppo"],
			["say", "CLOCK_KEY_FALLS", ""],
			["give", "kids_key"],
			["say", "CLOCK_TRUTH", ""],
		]},
	],

	# ---- 子ども部屋 ----
	"kids_shelf": [
		{"if": ["solved_books"], "do": [["say", "KIDS_SHELF_DONE", ""]]},
		{"do": [["puzzle", "books"]]},
	],
	"kids_poster": [
		{"do": [["say", "KIDS_POSTER", ""], ["set", "saw_poster"]]},
	],
	"kids_bed": [
		{"do": [["say", "KIDS_BED", "moko"]]},
	],
	"kids_window": [
		{"do": [["say", "KIDS_WINDOW", ""]]},
	],
	"kids_to_living": [
		{"do": [["goto", "living_room"]]},
	],
	"solved:books": [
		{"do": [
			["set", "solved_books"],
			["say", "BOOKS_SOLVED", ""],
			["say", "BOOKS_POPPO", "poppo"],
			["end_chapter", 1],
		]},
	],
}

## ポッポのヒント。上から順に "until" のフラグが立っていない最初の段階を使う。
## 1回押すごとに1段ずつ具体的になる(最大3段)。
const HINTS := [
	{"until": "read_memo", "keys": ["HINT_MEMO_1", "HINT_MEMO_2", "HINT_MEMO_3"]},
	{"until": "got_plates", "keys": ["HINT_PLATES_GET_1", "HINT_PLATES_GET_2", "HINT_PLATES_GET_3"]},
	{"until": "solved_plates", "keys": ["HINT_PLATES_1", "HINT_PLATES_2", "HINT_PLATES_3"]},
	{"until": "clock_wound", "keys": ["HINT_WIND_1", "HINT_WIND_2", "HINT_WIND_3"]},
	{"until": "solved_clock", "keys": ["HINT_CLOCK_1", "HINT_CLOCK_2", "HINT_CLOCK_3"]},
	{"until": "kids_door_open", "keys": ["HINT_DOOR_1", "HINT_DOOR_2", "HINT_DOOR_3"]},
	{"until": "solved_books", "keys": ["HINT_BOOKS_1", "HINT_BOOKS_2", "HINT_BOOKS_3"]},
]
