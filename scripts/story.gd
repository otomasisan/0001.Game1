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
##   ["run", ルールID]        別のルール(条件つき)を実行する
##
## 謎が解けたときは RULES["solved:<謎ID>"] が実行される。

const ROOMS := {
	"kitchen": "res://scenes/rooms/kitchen.tscn",
	"living_room": "res://scenes/rooms/living_room.tscn",
	"kids_room": "res://scenes/rooms/kids_room.tscn",
	"brother_room": "res://scenes/rooms/brother_room.tscn",
	"parents_room": "res://scenes/rooms/parents_room.tscn",
	"basement": "res://scenes/rooms/basement.tscn",
}

const PUZZLES := {
	"plates": "res://scenes/puzzles/plates_puzzle.tscn",
	"clock": "res://scenes/puzzles/clock_puzzle.tscn",
	"books": "res://scenes/puzzles/books_puzzle.tscn",
	"box": "res://scenes/puzzles/box_lock.tscn",
	"drawer": "res://scenes/puzzles/drawer_lock.tscn",
	"window": "res://scenes/puzzles/window_puzzle.tscn",
	"radio": "res://scenes/puzzles/radio_puzzle.tscn",
	"tag": "res://scenes/puzzles/tag_puzzle.tscn",
	"fences": "res://scenes/puzzles/fences_puzzle.tscn",
	"letter": "res://scenes/puzzles/letter_puzzle.tscn",
}

## 章の始めに流れる場面(前の章の終わりのあと、そのまま続く)
const CHAPTER_START := {
	2: [
		["say", "CH2_INTRO", ""],
		["say", "CH2_INTRO_MOKO", "moko"],
		["say", "CH2_INTRO_POPPO", "poppo"],
	],
	3: [
		["say", "CH3_INTRO", ""],
		["say", "CH3_INTRO_MOKO", "moko"],
		["say", "CH3_INTRO_POPPO", "poppo"],
	],
}

## 持ち物ID → 表示名キー
const ITEMS := {
	"plates": "ITEM_PLATES",
	"winding_key": "ITEM_WINDING_KEY",
	"kids_key": "ITEM_KIDS_KEY",
	"brother_key": "ITEM_BROTHER_KEY",
	"radio_knob": "ITEM_RADIO_KNOB",
	"ram_note": "ITEM_RAM_NOTE",
	"marble": "ITEM_MARBLE",
	"ear_tag": "ITEM_EAR_TAG",
	"father_glasses": "ITEM_GLASSES",
	"mother_ribbon": "ITEM_RIBBON",
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
		{"if": ["chapter>=3"], "do": [["say", "KITCHEN_WINDOW_CH3", ""]]},
		{"if": ["chapter>=2"], "do": [["say", "KITCHEN_WINDOW_CH2", ""]]},
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
		{"if": ["chapter>=3"], "do": [["say", "LIVING_CALENDAR_CH3", ""]]},
		{"if": ["chapter>=2"], "do": [["say", "LIVING_CALENDAR_CH2", ""]]},
		{"do": [["say", "LIVING_CALENDAR", ""]]},
	],
	"living_photo": [
		{"if": ["chapter>=3"], "do": [["say", "LIVING_PHOTO_CH3", "moko"]]},
		{"do": [["say", "LIVING_PHOTO", "moko"]]},
	],
	"living_sofa": [
		{"if": ["chapter>=2"], "do": [["say", "LIVING_SOFA_CH2", ""]]},
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
		{"if": ["solved_window"], "do": [["say", "WINDOW_DONE", ""]]},
		{"if": ["chapter>=2"], "do": [["say", "WINDOW_BREATH", ""], ["puzzle", "window"]]},
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

	# ==== 第2章「ながい夕方」 ====
	# ---- 居間: 謎4(小箱)・謎7(ラジオ)・兄の部屋のドア ----
	"living_box": [
		{"if": ["solved_box"], "do": [["say", "BOX_EMPTY", ""]]},
		{"do": [["say", "BOX_LOOK", "moko"], ["puzzle", "box"]]},
	],
	"solved:box": [
		{"do": [
			["set", "solved_box"],
			["say", "BOX_SOLVED", ""],
			["say", "BOX_TRUTH", "moko"],
			["give", "brother_key"],
		]},
	],
	"living_to_brother": [
		{"if": ["brother_door_open"], "do": [["goto", "brother_room"]]},
		{"if": ["has:brother_key"], "do": [
			["take", "brother_key"],
			["set", "brother_door_open"],
			["say", "BROTHER_DOOR_UNLOCK", ""],
			["goto", "brother_room"],
		]},
		{"do": [["say", "BROTHER_DOOR_LOCKED", ""]]},
	],
	"living_radio": [
		{"if": ["solved_radio"], "do": [["say", "RADIO_DONE", ""]]},
		{"use": "radio_knob", "do": [
			["take", "radio_knob"],
			["set", "radio_fixed"],
			["say", "RADIO_FIX", ""],
			["puzzle", "radio"],
		]},
		{"if": ["radio_fixed"], "do": [["puzzle", "radio"]]},
		{"do": [["say", "RADIO_NO_KNOB", ""]]},
	],
	"solved:radio": [
		{"do": [
			["set", "solved_radio"],
			["say", "RADIO_BROADCAST", ""],
			["say", "RADIO_MOKO", "moko"],
			["say", "RADIO_POPPO", "poppo"],
			["run", "ch2_finale"],
		]},
	],

	# ---- 兄の部屋: 謎5(引き出し) ----
	"brother_pillar": [
		{"do": [["say", "PILLAR_LOOK", ""], ["set", "saw_pillar"]]},
	],
	"brother_desk": [
		{"if": ["solved_drawer"], "do": [["say", "DESK_EMPTY", ""]]},
		{"do": [["say", "DESK_LOOK", ""], ["puzzle", "drawer"]]},
	],
	"solved:drawer": [
		{"do": [
			["set", "solved_drawer"],
			["say", "DRAWER_SOLVED", ""],
			["say", "DRAWER_TRUTH", "moko"],
			["give", "ram_note"],
			["give", "radio_knob"],
			["say", "DRAWER_MARBLE", ""],
			["give", "marble"],
			["set", "found_marble"],
		]},
	],
	"brother_window": [
		{"do": [["say", "BROTHER_WINDOW", ""]]},
	],
	"brother_kite": [
		{"do": [["say", "BROTHER_KITE", "moko"]]},
	],
	"brother_gift": [
		{"do": [["say", "BROTHER_GIFT", ""]]},
	],
	"brother_bed": [
		{"do": [["say", "BROTHER_BED", "moko"]]},
	],
	"brother_to_living": [
		{"do": [["goto", "living_room"]]},
	],

	# ---- 子ども部屋: 謎6(くもった窓) ----
	"solved:window": [
		{"do": [
			["set", "solved_window"],
			["say", "WINDOW_SOLVED", ""],
			["say", "WINDOW_POPPO", "poppo"],
			["run", "ch2_finale"],
		]},
	],

	# ---- 2章の終わり: 謎6と謎7の両方が解けたら ----
	"ch2_finale": [
		{"if": ["solved_window", "solved_radio"], "do": [
			["say", "CH2_FINALE", ""],
			["say", "CH2_FINALE_MOKO", "moko"],
			["end_chapter", 2],
		]},
	],

	# ==== 第3章「ひみつの部屋」 ====
	# ---- 台所: れいぞうこが倒れて、両親の部屋のドアが現れる ----
	"kitchen_to_parents": [
		{"if": ["parents_door_open"], "do": [["goto", "parents_room"]]},
		{"do": [
			["say", "PARENTS_DOOR_FOUND", ""],
			["say", "PARENTS_DOOR_POPPO", "poppo"],
			["set", "parents_door_open"],
			["goto", "parents_room"],
		]},
	],

	# ---- 両親の部屋: 謎8(とうさんの工具箱)・地下への とびら ----
	"parents_to_kitchen": [
		{"do": [["goto", "kitchen"]]},
	],
	"parents_toolbox": [
		{"if": ["solved_tag"], "do": [["say", "TOOLBOX_EMPTY", ""]]},
		{"do": [["say", "TOOLBOX_LOOK", ""], ["puzzle", "tag"]]},
	],
	"solved:tag": [
		{"do": [
			["set", "solved_tag"],
			["say", "TAG_SOLVED", ""],
			["say", "TAG_TRUTH", "moko"],
			["give", "ear_tag"],
			["say", "TAG_POPPO", "poppo"],
			["say", "GLASSES_FOUND", ""],
			["give", "father_glasses"],
			["set", "found_glasses"],
		]},
	],
	"parents_hatch": [
		{"if": ["basement_open"], "do": [["goto", "basement"]]},
		{"use": "ear_tag", "do": [
			["take", "ear_tag"],
			["set", "basement_open"],
			["say", "HATCH_OPEN", ""],
			["goto", "basement"],
		]},
		{"do": [["say", "HATCH_LOCKED", ""]]},
	],
	"parents_photo": [
		{"do": [["say", "PARENTS_PHOTO", "moko"]]},
	],
	"parents_wardrobe": [
		{"do": [["say", "PARENTS_WARDROBE", ""]]},
	],
	"parents_bed": [
		{"do": [["say", "PARENTS_BED", "moko"]]},
	],
	"parents_mirror": [
		{"do": [["say", "PARENTS_MIRROR", ""], ["say", "PARENTS_MIRROR_POPPO", "poppo"]]},
	],

	# ---- 地下室: 謎9(柵のスライド)・謎10(やぶれた手紙) ----
	"basement_ladder": [
		{"do": [["goto", "parents_room"]]},
	],
	"basement_fences": [
		{"if": ["solved_fences"], "do": [["say", "FENCES_DONE", ""]]},
		{"do": [["say", "FENCES_LOOK", ""], ["puzzle", "fences"]]},
	],
	"solved:fences": [
		{"do": [
			["set", "solved_fences"],
			["say", "FENCES_SOLVED", ""],
			["say", "FENCES_TRUTH", "moko"],
		]},
	],
	"basement_trough": [
		{"do": [["say", "BASEMENT_TROUGH", ""]]},
	],
	"basement_straw": [
		{"if": ["found_ribbon"], "do": [["say", "STRAW_EMPTY", ""]]},
		{"do": [
			["say", "STRAW_LOOK", ""],
			["give", "mother_ribbon"],
			["set", "found_ribbon"],
			["say", "RIBBON_MOKO", "moko"],
		]},
	],
	"basement_trunk": [
		{"if": ["solved_letter"], "do": [["say", "TRUNK_EMPTY", ""]]},
		{"if": ["solved_fences"], "do": [["say", "TRUNK_OPEN", ""], ["puzzle", "letter"]]},
		{"do": [["say", "TRUNK_BLOCKED", ""]]},
	],
	"solved:letter": [
		{"do": [
			["set", "solved_letter"],
			["say", "LETTER_READ", ""],
			["say", "LETTER_MOKO", "moko"],
			["say", "LETTER_POPPO", "poppo"],
			["say", "CH3_FINALE", ""],
			["end_chapter", 3],
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
	{"until": "solved_box", "keys": ["HINT_BOX_1", "HINT_BOX_2", "HINT_BOX_3"]},
	{"until": "brother_door_open", "keys": ["HINT_BDOOR_1", "HINT_BDOOR_2", "HINT_BDOOR_3"]},
	{"until": "solved_drawer", "keys": ["HINT_DRAWER_1", "HINT_DRAWER_2", "HINT_DRAWER_3"]},
	{"until": "solved_window", "keys": ["HINT_WINDOW_1", "HINT_WINDOW_2", "HINT_WINDOW_3"]},
	{"until": "radio_fixed", "keys": ["HINT_KNOB_1", "HINT_KNOB_2", "HINT_KNOB_3"]},
	{"until": "solved_radio", "keys": ["HINT_RADIO_1", "HINT_RADIO_2", "HINT_RADIO_3"]},
	{"until": "parents_door_open", "keys": ["HINT_PDOOR_1", "HINT_PDOOR_2", "HINT_PDOOR_3"]},
	{"until": "solved_tag", "keys": ["HINT_TAG_1", "HINT_TAG_2", "HINT_TAG_3"]},
	{"until": "basement_open", "keys": ["HINT_HATCH_1", "HINT_HATCH_2", "HINT_HATCH_3"]},
	{"until": "solved_fences", "keys": ["HINT_FENCES_1", "HINT_FENCES_2", "HINT_FENCES_3"]},
	{"until": "solved_letter", "keys": ["HINT_LETTER_1", "HINT_LETTER_2", "HINT_LETTER_3"]},
]
