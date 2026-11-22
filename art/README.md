# 絵の作り方(絵柄お試し版のメモ)

`art/src/` の SVG が元絵、`assets/` の PNG がゲームで使う書き出し結果です。
第1章の3部屋(台所・居間・子ども部屋)、第2章の兄の部屋、モコ、ポッポを絵本風の本番に近い絵柄で描いてあります。
1章の部屋の2章以降の差分(異変・真実)はこれからです。

## 絵柄のルール

| 項目 | 決めごと |
|------|----------|
| 線 | こげ茶 `#5A4636`、太さ 5px(細部は 3px)。少しゆらがせて手描き風に |
| 塗り | 水彩風: にじみ+ざらつき、ベタ塗りの上に明るい色を少し重ねる |
| 紙 | 全体に紙の繊維とうすいムラを重ねる |
| 2章の色 | 夕焼け: 壁 `#F7DEC2`、夕日 `#F28C5C`、全体にオレンジ〜紫の薄い光を重ねる |
| 1章の色 | クリーム `#FBF0DC`、桜色 `#F4BFC3`、若草色 `#DCE7C6`、木 `#C8956A`。部屋ごとに壁紙の柄を変える(台所=花、居間=葉、子ども部屋=星) |
| モコ | 丸いもこもこの体、こげ茶の顔、点の目、ピンクのほっぺ。左向き |
| サイズ | 背景 1920×1080、モコ 400×400(透明背景) |

## 背景とクリック位置

背景の物の位置は、`tools/gen_rooms.py` のクリック範囲に合わせて描いてあります
(例: メモ (640,330)-(820,450)、テーブル (880,700)-(1440,900))。
絵の配置を変えたら、`tools/gen_rooms.py` の座標も直して `python3 tools/gen_rooms.py` を実行してください。

背景の絵がある部屋では、クリックできる場所は普段は見えず、マウスでなぞったときだけ光って名前の札が出ます。

## 書き出し

```
node tools/render_svg.js art/src/kitchen_ch1.svg assets/rooms/kitchen_ch1.png
node tools/render_svg.js art/src/living_room_ch1.svg assets/rooms/living_room_ch1.png
node tools/render_svg.js art/src/kids_room_ch1.svg assets/rooms/kids_room_ch1.png
node tools/render_svg.js art/src/brother_room_ch2.svg assets/rooms/brother_room_ch2.png
node tools/render_svg.js art/src/moko.svg assets/characters/moko.png
node tools/render_svg.js art/src/poppo.svg assets/characters/poppo.png
```

背景(幅1920)は不透明、キャラクターは透明背景で書き出されます。
会話ウィンドウでは、話し手(モコ・ポッポ)の立ち絵が右上に出ます。

フィルタ(線のゆらぎ `wobble`・水彩 `wc`・紙 `paper`/`blotch`)は全部屋で同じ定義を使います。

手描き(クリスタ等)に切り替える場合は、同じサイズ・同じファイル名で PNG を書き出して上書きするだけで差し替わります。

## 章ごとの差分

部屋シーンの `backgrounds` に章の順で絵を並べます(1章=通常、2章=異変、3章=真実…)。
絵がない章は仮の塗りで表示されます。

2章(ながい夕方)の絵は、1章の絵に夕焼けの色を重ねて作ります。`tools/gen_ch2_art.py` が
`*_ch1.svg` から `*_ch2.svg` を作るので、1章の絵を直したら次を実行してください。

```
python3 tools/gen_ch2_art.py
for r in kitchen living_room kids_room; do node tools/render_svg.js art/src/${r}_ch2.svg assets/rooms/${r}_ch2.png; done
```

- 台所・子ども部屋: 窓の外が夕焼けに、部屋全体に夕方の色
- 居間: 夕方の色に加えて、つるが伸び、ソファにダイヤルの小箱(謎4)が現れる
- ラムの部屋は2章から入れるので、2章の絵だけ(`brother_room_ch2.svg`)

3章(ひみつの部屋)の絵は `tools/gen_ch3_art.py` が作ります。

```
python3 tools/gen_ch3_art.py
for r in kitchen living_room kids_room brother_room parents_room basement; do node tools/render_svg.js art/src/${r}_ch3.svg assets/rooms/${r}_ch3.png; done
```

- 台所・居間・子ども部屋・ラムの部屋: 前の章の絵の色をうすくして(灰色)、壁紙のはがれ(下に段ボールと板)と床の藁を足す
- 台所: れいぞうこ(段ボールに描いた絵)が倒れて、うしろに両親の部屋のドアが現れる
- 両親の部屋・地下室は3章から入れる新しい部屋。絵はスクリプトの中にある(`PARENTS` / `BASEMENT`)
