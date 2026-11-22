extends Node
## 本物のマウス入力(画面座標のクリック)でタイトルから遊ぶテスト(第1章・第2章・第3章)。
##   godot --path . res://tests/click_test.tscn -- --shots=<dir>

var shots_dir := ""
var failures := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.substr(8)
	await get_tree().process_frame
	await run()
	print("CLICK TEST: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	get_tree().quit(1 if failures > 0 else 0)


func expect(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		printerr("  FAIL ", what)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func click_at(p: Vector2) -> void:
	var vp := get_viewport()
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	vp.push_input(mv)
	await frames(2)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = p
		e.global_position = p
		vp.push_input(e)
		await frames(2)


func scene() -> Node:
	return get_tree().current_scene


func center_of(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


## 会話が出ている間、画面をクリックして送る
func click_through_dialogue(max_clicks := 60) -> void:
	for i in max_clicks:
		await frames(5)
		var d = scene().get_node_or_null("Dialogue")
		if d == null or not d.is_active():
			if not scene().busy:
				return
			continue
		await click_at(Vector2(960, 900))


func shot(n: String) -> void:
	if shots_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(shots_dir)
	img.save_png(shots_dir.path_join(n + ".png"))


func hotspot(id: String) -> Control:
	for h in scene().find_children("*", "Hotspot", true, false):
		if h.hotspot_id == id:
			return h
	return null


func run() -> void:
	GameState.delete_save()
	# このテスト自身はシーン切り替えで消えないよう、current_scene から外しておく
	get_tree().current_scene = null
	get_tree().change_scene_to_file("res://scenes/title.tscn")
	await frames(10)
	await shot("c00_title")
	await click_at(center_of(scene().find_child("new", true, false)))
	await frames(20)
	expect(scene().name == "Main", "「はじめから」でゲームが始まる")
	await shot("c01_start")
	await click_through_dialogue()
	await frames(20)
	await shot("c02_after_intro")
	var moko: CanvasItem = scene().room_node.get_node("Moko")
	expect(moko.modulate.a > 0.9, "会話のあとモコが見える (a=%.2f)" % moko.modulate.a)
	expect(not scene().busy, "会話のあと操作できる")
	await click_at(center_of(hotspot("kitchen_memo")))
	await frames(10)
	expect(scene().get_node("Dialogue").is_active(), "メモをクリックすると会話が出る")
	await click_through_dialogue()
	expect(GameState.has_flag("read_memo"), "メモを読んだ")
	await click_at(center_of(scene().get_node("HUD").get_child(scene().get_node("HUD").get_child_count() - 1)))
	await frames(20)
	expect(scene().name == "Title", "「タイトルへ」でタイトルに戻る")
	await shot("c03_back_to_title")

	# 第2章(テスト用ボタン)
	var dbg = scene().find_child("debug_ch2", true, false)
	expect(dbg != null, "第2章ボタンがある")
	if dbg:
		await click_at(center_of(dbg))
		await frames(20)
		await click_through_dialogue()
		await frames(20)
		await shot("c04_ch2")
		expect(GameState.chapter == 2 and not scene().busy, "第2章で操作できる")
		await click_at(center_of(hotspot("kids_window")))
		await frames(10)
		await click_through_dialogue()
		expect(scene().puzzle_node != null, "第2章で窓をクリックすると謎が開く")
		await shot("c05_ch2_window")
		scene().close_puzzle()
		await frames(5)
		await click_at(center_of(scene().get_node("HUD").get_child(scene().get_node("HUD").get_child_count() - 1)))
		await frames(20)
		expect(scene().name == "Title", "第2章で「タイトルへ」でタイトルに戻る")

	# 第3章(テスト用ボタン)。謎の中も本物のクリックで操作する
	var dbg3 = scene().find_child("debug_ch3", true, false)
	expect(dbg3 != null, "第3章ボタンがある")
	if dbg3:
		await click_at(center_of(dbg3))
		await frames(20)
		await click_through_dialogue()
		await frames(20)
		expect(GameState.chapter == 3 and not scene().busy, "第3章で操作できる")
		await click_at(center_of(hotspot("living_to_kitchen")))
		await frames(60)
		await click_at(center_of(hotspot("kitchen_to_parents")))
		await click_through_dialogue()
		await frames(60)
		expect(GameState.room == "parents_room", "台所のドアから両親の部屋へ")
		await click_at(center_of(hotspot("parents_toolbox")))
		await click_through_dialogue()
		var tag = scene().puzzle_node
		expect(tag != null, "工具箱をクリックすると謎8が開く")
		if tag:
			# 板をクリックして正しい並びにする
			for i in tag.order.size():
				var j: int = tag.order.find(i)
				if j != i:
					await click_at(center_of(tag._boards[i]))
					await click_at(center_of(tag._boards[j]))
			await shot("c06_tag_solved")
			expect(tag.is_solved, "板をクリックで並べて謎8が解ける")
			await frames(90)
			await click_through_dialogue()
			expect(GameState.has_item("ear_tag"), "ふだを入手")
		# 持ち物の ふだ を選んで、ゆかの とびらへ
		var inv = scene().get_node("HUD/Inventory")
		for b in inv.find_children("*", "BaseButton", true, false):
			if b.get_meta("item", "") == "ear_tag":
				await click_at(center_of(b))
		expect(inv.selected == "ear_tag", "持ち物の ふだ を選べる")
		await click_at(center_of(hotspot("parents_hatch")))
		await click_through_dialogue()
		await frames(60)
		expect(GameState.room == "basement", "ふだを使って地下室へ")
		await click_at(center_of(hotspot("basement_fences")))
		await click_through_dialogue()
		var fences = scene().puzzle_node
		expect(fences != null, "柵をクリックすると謎9が開く")
		if fences:
			var e: int = fences.cells.find(fences.EMPTY)
			var p: int = fences._neighbors(e)[0]
			var before: int = fences.cells[p]
			var cell: Vector2 = fences._board.global_position + (Vector2(p % 3, p / 3) + Vector2(0.5, 0.5)) * fences.CELL
			await click_at(cell)
			expect(fences.cells[e] == before, "区画をクリックで すべらせられる")
			fences.solve_by_undo()
			await frames(90)
			await click_through_dialogue()
		await click_at(center_of(hotspot("basement_trunk")))
		await click_through_dialogue()
		var letter = scene().puzzle_node
		expect(letter != null, "トランクをクリックすると謎10が開く")
		if letter:
			var was: bool = letter.flipped[0]
			await click_at(center_of(letter._strips[0]))
			await click_at(center_of(letter._strips[0]))
			expect(letter.flipped[0] != was, "切れはしを2回クリックで ひっくり返る")
			await shot("c07_letter")
			await click_at(center_of(letter.find_child("BackButton", true, false)))
			await frames(10)
			expect(scene().puzzle_node == null, "「もどる」で謎を閉じる")
		await click_at(center_of(scene().get_node("HUD").get_child(scene().get_node("HUD").get_child_count() - 1)))
		await frames(20)
		expect(scene().name == "Title", "第3章で「タイトルへ」でタイトルに戻る")
	GameState.delete_save()
