"""仮素材の部屋シーン(scenes/rooms/*.tscn)を生成する補助スクリプト。
本番の絵に置き換えたあとは、Godot エディタで直接編集してよい(再生成すると上書きされるので注意)。
使い方: python3 tools/gen_rooms.py
"""
from pathlib import Path

WALLS = "[Color(0.99, 0.94, 0.86, 1), Color(0.98, 0.82, 0.68, 1), Color(0.82, 0.8, 0.78, 1), Color(0.9, 0.84, 0.62, 1)]"
SHAPE = {"rect": 0, "ellipse": 1, "door": 2}

ROOMS = {
    "kitchen": {
        "name_key": "ROOM_KITCHEN",
        "floor": "Color(0.86, 0.72, 0.55, 1)",
        "moko": (200, 640, 520, 960),
        "backgrounds": ["res://assets/rooms/kitchen_ch1.png"],
        "spots": [
            ("Window", "kitchen_window", "LBL_WINDOW", (140, 260, 500, 580), "Color(0.72, 0.87, 0.96, 1)", "rect"),
            ("Fridge", "", "", (600, 240, 860, 780), "Color(0.95, 0.95, 0.93, 1)", "rect"),
            ("Memo", "kitchen_memo", "LBL_MEMO", (640, 330, 820, 450), "Color(1, 0.93, 0.6, 1)", "rect"),
            ("Cupboard", "kitchen_cupboard", "LBL_CUPBOARD", (1000, 200, 1380, 640), "Color(0.8, 0.62, 0.45, 1)", "rect"),
            ("Stove", "kitchen_stove", "LBL_STOVE", (1460, 460, 1740, 780), "Color(0.66, 0.66, 0.68, 1)", "rect"),
            ("Table", "kitchen_table", "LBL_TABLE", (880, 700, 1440, 900), "Color(0.72, 0.52, 0.36, 1)", "rect"),
            ("DoorLiving", "kitchen_to_living", "LBL_TO_LIVING", (1770, 380, 1910, 780), "Color(0.9, 0.78, 0.62, 1)", "door"),
        ],
    },
    "living_room": {
        "name_key": "ROOM_LIVING",
        "floor": "Color(0.8, 0.66, 0.52, 1)",
        "moko": (300, 660, 620, 980),
        "backgrounds": ["res://assets/rooms/living_room_ch1.png"],
        "spots": [
            ("DoorKitchen", "living_to_kitchen", "LBL_TO_KITCHEN", (10, 380, 160, 780), "Color(0.9, 0.78, 0.62, 1)", "door"),
            ("Clock", "living_clock", "LBL_CLOCK", (260, 240, 520, 600), "Color(0.62, 0.42, 0.28, 1)", "rect"),
            ("Calendar", "living_calendar", "LBL_CALENDAR", (640, 260, 880, 500), "Color(1, 1, 1, 1)", "rect"),
            ("Photo", "living_photo", "LBL_PHOTO", (1000, 260, 1240, 440), "Color(0.95, 0.85, 0.75, 1)", "rect"),
            ("Sofa", "living_sofa", "LBL_SOFA", (900, 580, 1500, 860), "Color(0.85, 0.55, 0.55, 1)", "rect"),
            ("DoorKids", "living_to_kids", "LBL_TO_KIDS", (1700, 330, 1880, 780), "Color(0.95, 0.8, 0.85, 1)", "door"),
        ],
    },
    "kids_room": {
        "name_key": "ROOM_KIDS",
        "floor": "Color(0.88, 0.78, 0.62, 1)",
        "moko": (700, 700, 1000, 980),
        "backgrounds": ["res://assets/rooms/kids_room_ch1.png"],
        "spots": [
            ("DoorLiving", "kids_to_living", "LBL_TO_LIVING", (10, 380, 160, 780), "Color(0.9, 0.78, 0.62, 1)", "door"),
            ("Shelf", "kids_shelf", "LBL_SHELF", (300, 250, 700, 780), "Color(0.7, 0.5, 0.34, 1)", "rect"),
            ("Poster", "kids_poster", "LBL_POSTER", (820, 220, 1160, 500), "Color(0.98, 0.96, 0.85, 1)", "rect"),
            ("Window", "kids_window", "LBL_FOGGY_WINDOW", (1280, 220, 1620, 560), "Color(0.86, 0.9, 0.92, 1)", "rect"),
            ("Bed", "kids_bed", "LBL_BED", (1100, 640, 1800, 900), "Color(0.75, 0.85, 0.7, 1)", "rect"),
        ],
    },
    # 第2章から入れる部屋(まだ入口はつないでいない)
    "brother_room": {
        "name_key": "ROOM_BROTHER",
        "floor": "Color(0.77, 0.59, 0.44, 1)",
        "moko": (640, 700, 940, 980),
        "backgrounds": [None, "res://assets/rooms/brother_room_ch2.png"],
        "spots": [
            ("DoorLiving", "brother_to_living", "LBL_TO_LIVING", (10, 380, 160, 780), "Color(0.9, 0.78, 0.62, 1)", "door"),
            ("Pillar", "brother_pillar", "LBL_PILLAR", (260, 120, 380, 780), "Color(0.78, 0.58, 0.42, 1)", "rect"),
            ("Desk", "brother_desk", "LBL_DESK", (480, 500, 900, 780), "Color(0.72, 0.52, 0.36, 1)", "rect"),
            ("Window", "brother_window", "LBL_WINDOW", (1000, 200, 1360, 540), "Color(0.97, 0.75, 0.6, 1)", "rect"),
            ("Kite", "brother_kite", "LBL_KITE", (1480, 200, 1720, 440), "Color(0.97, 0.87, 0.55, 1)", "rect"),
            ("GiftBox", "brother_gift", "LBL_GIFT_BOX", (1000, 640, 1180, 780), "Color(0.96, 0.9, 0.79, 1)", "rect"),
            ("Bed", "brother_bed", "LBL_BED", (1300, 620, 1860, 900), "Color(0.48, 0.61, 0.78, 1)", "rect"),
        ],
    },
}


def node(name, l, t, r, b, extra):
    lines = [
        f'[node name="{name}" type="Control" parent="."]',
        "layout_mode = 0",
        f"offset_left = {l}.0",
        f"offset_top = {t}.0",
        f"offset_right = {r}.0",
        f"offset_bottom = {b}.0",
    ]
    return "\n".join(lines + extra) + "\n"


MOKO_TEXTURE = "res://assets/characters/moko.png"


def build(room_id, d):
    bgs = d.get("backgrounds", [])
    res = [
        '[ext_resource type="Script" path="res://scripts/room.gd" id="1"]',
        '[ext_resource type="Script" path="res://scripts/hotspot.gd" id="2"]',
        '[ext_resource type="Script" path="res://scripts/moko.gd" id="3"]',
        f'[ext_resource type="Texture2D" path="{MOKO_TEXTURE}" id="4"]',
    ]
    for i, bg in enumerate(bgs):
        if bg:
            res.append(f'[ext_resource type="Texture2D" path="{bg}" id="bg{i + 1}"]')
    bg_line = []
    if bgs:
        refs = ", ".join(f'ExtResource("bg{i + 1}")' if bg else "null" for i, bg in enumerate(bgs))
        bg_line = [f"backgrounds = Array[Texture2D]([{refs}])"]
    out = [
        f"[gd_scene load_steps={len(res) + 1} format=3]\n",
        *res,
        "",
        f'[node name="{"".join(p.capitalize() for p in room_id.split("_"))}" type="Control"]',
        "layout_mode = 3",
        "anchors_preset = 15",
        "anchor_right = 1.0",
        "anchor_bottom = 1.0",
        "grow_horizontal = 2",
        "grow_vertical = 2",
        'script = ExtResource("1")',
        f'room_id = "{room_id}"',
        f'name_key = "{d["name_key"]}"',
        f"wall_colors = Array[Color]({WALLS})",
        f"floor_color = {d['floor']}",
        *bg_line,
        "",
    ]
    text = "\n".join(out) + "\n"
    for name, hid, label, (l, t, r, b), color, shape in d["spots"]:
        extra = ['script = ExtResource("2")']
        if hid:
            extra.append(f'hotspot_id = "{hid}"')
        if label:
            extra.append(f'label_key = "{label}"')
        extra.append(f"fill_color = {color}")
        if SHAPE[shape]:
            extra.append(f"shape = {SHAPE[shape]}")
        if shape == "door":
            extra.append("label_size = 24")
        text += "\n" + node(name, l, t, r, b, extra)
    l, t, r, b = d["moko"]
    text += "\n" + node("Moko", l, t, r, b, ['script = ExtResource("3")', 'texture = ExtResource("4")'])
    return text


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent / "scenes" / "rooms"
    root.mkdir(parents=True, exist_ok=True)
    for rid, d in ROOMS.items():
        (root / f"{rid}.tscn").write_text(build(rid, d), encoding="utf-8")
        print("wrote", rid)
