extends Node
## 第1章〜第3章を最初から最後まで自動で遊ぶ通しテスト。
##   godot --headless --path . res://tests/smoke_test.tscn
## 画面つきで起動し "-- --shots=<dir>" を付けると、要所でスクリーンショットを保存する。

var main: Node
var failures := 0
var shots_dir := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.substr(8)
	await get_tree().process_frame
	await run()
	print("SMOKE TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func expect(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		printerr("  FAIL ", what)


func wait_idle(max_frames: int = 2000) -> void:
	for i in max_frames:
		await get_tree().process_frame
		if not is_instance_valid(main):
			return
		var d: DialogueBox = main.get_node("Dialogue")
		if d.is_active():
			d.advance()
		elif not main.busy:
			return


## 会話を進めずに止める(スクリーンショット用)
func wait_text(frames: int = 90) -> void:
	for i in frames:
		await get_tree().process_frame


func shot(n: String) -> void:
	if shots_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(shots_dir)
	img.save_png(shots_dir.path_join(n + ".png"))
	print("  shot ", n)


func click(id: String) -> void:
	main.on_hotspot(id)
	await wait_idle()


func hotspot(id: String) -> Control:
	for h in main.room_node.find_children("*", "Hotspot", true, false):
		if h.hotspot_id == id:
			return h
	return null


func run() -> void:
	# 1) テキストの抜けがないか
	var missing: Array[String] = []
	for locale in ["ja", "en"]:
		TranslationServer.set_locale(locale)
		var keys: Array[String] = []
		for rules in Story.RULES.values():
			for rule in rules:
				for a in rule.get("do", []):
					if a[0] == "say":
						keys.append(a[1])
		for stage in Story.HINTS:
			keys.append_array(stage["keys"])
		keys.append_array(Story.ITEMS.values())
		for k in keys:
			if tr(k) == k:
				missing.append("%s:%s" % [locale, k])
	expect(missing.is_empty(), "全テキストが日英そろっている %s" % [missing])
	TranslationServer.set_locale("ja")

	# 2) 第1章の通しプレイ
	GameState.delete_save()
	GameState.new_game()
	main = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	get_tree().current_scene = main
	await wait_text()
	await shot("01_intro")
	await wait_idle()
	expect(GameState.room == "kitchen", "台所から始まる")
	await shot("02_kitchen")
	var memo: Hotspot = main.room_node.get_node("Memo")
	expect(memo.art_mode, "背景の絵がある部屋では仮の図形を描かない")
	memo._hover = true
	memo.queue_redraw()
	await shot("02b_kitchen_hover")
	memo._hover = false
	memo.queue_redraw()

	main.show_hint()
	await wait_idle()
	expect(GameState.hint_tier == 1, "ポッポのヒント1段目")

	await click("kitchen_memo")
	expect(GameState.has_flag("read_memo"), "メモを読んだ")
	await click("kitchen_table")
	expect(main.puzzle_node == null, "お皿がないと謎1は始まらない")
	await click("kitchen_cupboard")
	expect(GameState.has_item("plates"), "お皿を手に入れた")
	await click("kitchen_table")
	expect(main.puzzle_node != null, "謎1(お皿)が開く")
	var plates = main.puzzle_node
	plates.set_seats(["mother", "ram", "moko", "", "father"])
	expect(not plates.is_solved, "まちがった並びでは解けない")
	plates.set_seats(["father", "ram", "", "", "mother"])
	plates.cycle_seat(2)
	plates.cycle_seat(2)
	expect(plates.seats[2] == "moko", "椅子クリックで未使用のお皿が順に置かれる")
	await shot("03_plates_puzzle")
	await wait_idle()
	await get_tree().create_timer(1.2).timeout
	await wait_idle()
	expect(GameState.has_flag("solved_plates"), "謎1が解けた")
	expect(GameState.has_item("winding_key") and not GameState.has_item("plates"), "ねじまきを入手、お皿は消費")

	await click("kitchen_to_living")
	expect(GameState.room == "living_room", "居間へ移動")
	expect(GameState.has_save(), "部屋移動でオートセーブ")
	await click("living_clock")
	expect(not GameState.has_flag("clock_wound"), "選ばずにクリックしても使わない")
	main.get_node("HUD/Inventory").selected = "winding_key"
	await click("living_clock")
	expect(GameState.has_flag("clock_wound"), "ねじまきを使った")
	await click("living_clock")
	expect(main.puzzle_node != null, "謎2(ハト時計)が開く")
	var clock = main.puzzle_node
	clock.set_time(6, 0)
	clock.add_minutes(35)
	clock.confirm()
	expect(not clock.is_solved, "6:35 では解けない")
	clock.add_minutes(5)
	await shot("04_clock_puzzle")
	clock.confirm()
	expect(clock.is_solved, "6:40 で解ける")
	await shot("04b_clock_poppo")
	await get_tree().create_timer(1.3).timeout
	await wait_text(60)
	await shot("04c_poppo_talks")
	await get_tree().create_timer(1.2).timeout
	await wait_idle()
	expect(GameState.has_item("kids_key"), "小さな鍵を入手")

	main.get_node("HUD/Inventory").selected = "kids_key"
	await click("living_sofa")
	expect(main.get_node("HUD/Inventory").selected == "", "使えない場所では選択が外れる")
	await shot("05_living")
	await click("living_to_kids")
	expect(GameState.room == "kids_room" and GameState.has_flag("kids_door_open"), "子ども部屋の鍵を開けて入る")
	await click("kids_poster")
	await shot("06_kids_room")
	await click("kids_shelf")
	var books = main.puzzle_node
	expect(books != null, "謎3(絵本)が開く")
	books.select_book(0)
	books.select_book(2)
	await shot("07_books_puzzle")
	books.select_book(1)
	books.select_book(3)
	expect(books.is_solved, "絵本を並べ替えて解ける")
	await get_tree().create_timer(1.2).timeout
	await wait_idle(4000)
	await wait_text(200)
	await shot("08_chapter_end")
	await wait_idle(4000)
	await get_tree().create_timer(0.5).timeout
	expect(GameState.chapter == 2 and GameState.has_flag("chapter1_clear"), "第1章クリアで章が進む")

	# 3) 第2章: 第1章のあとそのまま続く
	expect(main.get_node("Dialogue").is_active() == false and GameState.room == "kids_room", "第1章のあと子ども部屋で第2章が始まる")
	await shot("10_ch2_kids_room")
	# 会話中は部屋のモコが消えて、会話ウィンドウと重ならない
	main.on_hotspot("kids_bed")
	await wait_text(30)
	var moko: CanvasItem = main.room_node.get_node("Moko")
	expect(moko.modulate.a < 0.05, "会話中は部屋のモコを隠す")
	await shot("10b_dialogue_no_overlap")
	await wait_idle()
	await wait_text(30)
	expect(moko.modulate.a > 0.95, "会話が終わるとモコが戻る")

	# 謎6: くもった窓
	await click("kids_window")
	var win = main.puzzle_node
	expect(win != null, "謎6(くもった窓)が開く")
	expect(not win.is_sorted(), "窓の文字は最初はばらばら")
	await shot("11_window_puzzle")
	win.solve_by_swaps()
	expect(win.is_solved, "窓の文字を並べて解ける")
	await get_tree().create_timer(1.2).timeout
	await wait_idle()
	expect(GameState.has_flag("solved_window") and GameState.chapter == 2, "謎6だけでは章は終わらない")

	# 謎4: 居間の小箱
	await click("kids_to_living")
	await shot("12_living_ch2")
	await click("living_to_brother")
	expect(GameState.room == "living_room", "兄の部屋は最初は開かない")
	await click("living_radio")
	expect(main.puzzle_node == null, "つまみがないとラジオは回せない")
	await click("living_box")
	var box = main.puzzle_node
	expect(box != null, "謎4(小箱)が開く")
	box.set_values([3, 17, 23])
	box.try_open()
	expect(not box.is_solved, "まちがった日付では開かない")
	box.set_values([3, 17, 24])
	await shot("13_box_puzzle")
	box.try_open()
	expect(box.is_solved, "カレンダーの日付で小箱が開く")
	await get_tree().create_timer(1.2).timeout
	await wait_idle()
	expect(GameState.has_item("brother_key"), "兄の部屋の鍵を入手")

	# 謎5: 兄の部屋の引き出し
	await click("living_to_brother")
	expect(GameState.room == "brother_room" and not GameState.has_item("brother_key"), "兄の部屋に入る")
	await click("brother_pillar")
	await shot("14_brother_room")
	await click("brother_desk")
	var drawer = main.puzzle_node
	expect(drawer != null, "謎5(引き出し)が開く")
	drawer.set_values([4, 5])
	await shot("15_drawer_puzzle")
	drawer.try_open()
	expect(drawer.is_solved, "柱の背比べの数字で引き出しが開く")
	await get_tree().create_timer(1.2).timeout
	await wait_idle()
	expect(GameState.has_item("radio_knob") and GameState.has_item("marble"), "つまみとビー玉を入手")

	# 謎7: ラジオ
	await click("brother_to_living")
	main.get_node("HUD/Inventory").selected = "radio_knob"
	await click("living_radio")
	var radio = main.puzzle_node
	expect(radio != null and GameState.has_flag("radio_fixed"), "つまみを付けてラジオが開く")
	radio.listen_now()
	expect(not radio.is_solved, "雑音の多い周波数では聞こえない")
	radio.set_pos(radio.TARGET)
	await shot("16_radio_puzzle")
	radio.listen_now()
	expect(radio.is_solved, "85.5MHz で放送が聞こえる")
	await get_tree().create_timer(1.2).timeout
	await wait_idle(4000)
	await wait_text(200)
	await shot("17_chapter2_end")
	await wait_idle(4000)
	await get_tree().create_timer(0.5).timeout
	expect(GameState.chapter == 3 and GameState.has_flag("chapter2_clear"), "第2章クリアで章が進む")

	# 4) 第3章: 第2章のあとそのまま続く
	await shot("18_ch3_start")
	expect(main.current_hint_stage().get("until", "") == "parents_door_open", "第3章のヒントは台所のドアから")
	await click("living_to_kitchen")
	expect(not hotspot("kitchen_memo").visible and hotspot("kitchen_to_parents").visible, "台所: れいぞうこが倒れてドアが現れる")
	await shot("19_kitchen_ch3")
	await click("kitchen_to_parents")
	expect(GameState.room == "parents_room", "両親の部屋に入る")
	await shot("20_parents_room")
	await click("parents_hatch")
	expect(GameState.room == "parents_room", "ゆかの とびらは最初は開かない")
	await click("parents_mirror")

	# 謎8: 工具箱の板
	await click("parents_toolbox")
	var tag = main.puzzle_node
	expect(tag != null and not tag.is_sorted(), "謎8(工具箱の板)が開く")
	await shot("21_tag_puzzle")
	tag.solve_by_swaps()
	expect(tag.is_solved, "板を並べて No.0217 が読める")
	await get_tree().create_timer(1.2).timeout
	await wait_idle()
	expect(GameState.has_item("ear_tag") and GameState.has_flag("found_glasses"), "ふだと、とうさんのめがねを入手")

	main.get_node("HUD/Inventory").selected = "ear_tag"
	await click("parents_hatch")
	expect(GameState.room == "basement" and not GameState.has_item("ear_tag"), "ふだを使って地下室へ")
	await shot("22_basement")
	await click("basement_trunk")
	expect(main.puzzle_node == null, "さくが じゃまで トランクに近づけない")
	await click("basement_straw")
	expect(GameState.has_item("mother_ribbon"), "わらの中から かあさんのリボン")

	# 謎9: 柵のスライド
	await click("basement_fences")
	var fences = main.puzzle_node
	expect(fences != null and not fences.is_sorted(), "謎9(柵)が開く")
	await shot("23_fences_puzzle")
	var corner_far: int = 0 if fences.cells.find(fences.EMPTY) != 0 and not fences._neighbors(fences.cells.find(fences.EMPTY)).has(0) else -1
	if corner_far == 0:
		expect(not fences.slide(0), "空きのとなりでない区画は動かない")
	fences.solve_by_undo()
	expect(fences.is_solved, "道をつなげて柵が解ける")
	await get_tree().create_timer(1.2).timeout
	await wait_idle()

	# 謎10: やぶれた手紙
	await click("basement_trunk")
	var letter = main.puzzle_node
	expect(letter != null and not letter.is_done(), "謎10(やぶれた手紙)が開く")
	await shot("24_letter_puzzle")
	letter.select_strip(1)
	letter.select_strip(1)
	expect(not letter.flipped[1], "同じ切れはしを2回で ひっくり返る")
	letter.solve_all()
	expect(letter.is_solved, "手紙をつなぎ合わせて読める")
	await get_tree().create_timer(1.2).timeout
	await wait_idle(4000)
	await wait_text(200)
	await shot("25_chapter3_end")
	await wait_idle(4000)
	await get_tree().create_timer(0.5).timeout
	expect(GameState.chapter == 4 and GameState.has_flag("chapter3_clear"), "第3章クリアで章が進む")

	# デバッグ用: 第2章からすぐ始められる
	GameState.debug_start_chapter(2)
	expect(GameState.chapter == 2 and GameState.room == "kids_room" and GameState.has_flag("solved_books"), "第2章から始める確認用の状態")
	GameState.debug_start_chapter(3)
	expect(GameState.chapter == 3 and GameState.has_flag("solved_radio") and GameState.has_item("marble"), "第3章から始める確認用の状態")

	# 5) セーブ/ロード
	GameState.new_game()
	expect(GameState.load_game(), "セーブを読み込める")
	expect(GameState.chapter == 4 and GameState.has_flag("solved_letter"), "読み込んだ内容が正しい")
	await shot("09_title")
	GameState.delete_save()
