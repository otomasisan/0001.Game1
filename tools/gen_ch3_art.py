"""第3章「ひみつの部屋」の絵を作る。
- 台所・居間・子ども部屋・兄の部屋: 前の章の絵から、色をうすくして(灰色)、壁紙のはがれ
  (下から段ボールと板が見える)と、床に散らばる藁を足す。台所はれいぞうこ(段ボールの絵)が
  倒れて、うしろに両親の部屋のドアが現れる。
- 両親の部屋・地下室: 第3章から入る新しい部屋(このスクリプトの中に絵がある)
使い方: python3 tools/gen_ch3_art.py  → そのあと tools/render_svg.js で PNG に書き出す
"""
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "art" / "src"
MARK = "  <!-- ===== 紙の質感 ===== -->"
INK = "#5A4636"

# 色をうすくする(彩度を落として、冷たい灰色の光をかぶせる)
GREY = """  <!-- ===== 第3章: 色があせて灰色に ===== -->
  <rect width="1920" height="1080" fill="#8A8A8A" opacity="0.62" style="mix-blend-mode:saturation"/>
  <defs>
    <linearGradient id="ch3_grey" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#B9C2CC" stop-opacity="0.38"/>
      <stop offset="1" stop-color="#8C8A94" stop-opacity="0.30"/>
    </linearGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#ch3_grey)" style="mix-blend-mode:multiply"/>
"""


def peel(x, y, w, h, seed):
    """壁紙がはがれた穴。下から段ボールと板が見え、はがれた壁紙がめくれている"""
    rnd = random.Random(seed)
    pts = []
    n = 9
    for i in range(n):
        a = i / n
        if a < 0.25:
            px, py = x + w * (a / 0.25), y
        elif a < 0.5:
            px, py = x + w, y + h * ((a - 0.25) / 0.25)
        elif a < 0.75:
            px, py = x + w * (1 - (a - 0.5) / 0.25), y + h
        else:
            px, py = x, y + h * (1 - (a - 0.75) / 0.25)
        pts.append(f"{px + rnd.randint(-14, 14):.0f},{py + rnd.randint(-14, 14):.0f}")
    poly = " ".join(pts)
    lines = "".join(
        f'<path d="M{x + 10 + i * 18} {y + 4} V{y + h - 4}"/>' for i in range(max(1, (w - 16) // 18))
    )
    planks = f'<path d="M{x} {y + h * 0.5:.0f} H{x + w}"/>'
    fx, fy = x + w, y + h
    flap = f"M{fx - 6} {fy - 40} Q{fx + 30} {fy - 30} {fx + 26} {fy + 8} Q{fx} {fy - 4} {fx - 30} {fy - 4} Z"
    return f"""  <!-- 壁紙のはがれ -->
  <defs><clipPath id="peel{seed}"><polygon points="{poly}"/></clipPath></defs>
  <g filter="url(#wc)">
    <polygon points="{poly}" fill="#C4A77F"/>
    <g clip-path="url(#peel{seed})" stroke="#A98C66" stroke-width="5" opacity="0.8">{lines}</g>
    <path d="{flap}" fill="#EFE4D2"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="4" stroke-linejoin="round" fill="none">
    <polygon points="{poly}"/>
    <g clip-path="url(#peel{seed})" stroke-width="3" opacity="0.55">{planks}</g>
    <path d="{flap}"/>
  </g>
"""


def straw(cx, cy, spread, n, seed):
    """床に散らばった藁"""
    rnd = random.Random(seed)
    strokes = []
    for _ in range(n):
        x = cx + rnd.uniform(-spread, spread)
        y = cy + rnd.uniform(-spread * 0.18, spread * 0.18)
        ang = rnd.uniform(-0.5, 0.5)
        ln = rnd.uniform(26, 60)
        x2 = x + ln
        y2 = y + ln * ang
        strokes.append(f'<path d="M{x:.0f} {y:.0f} Q{(x + x2) / 2:.0f} {y - 6:.0f} {x2:.0f} {y2:.0f}"/>')
    return f"""  <!-- 藁 -->
  <g filter="url(#wobble)" stroke-linecap="round" fill="none">
    <g stroke="#9C8546" stroke-width="7">{''.join(strokes)}</g>
    <g stroke="#E3CB82" stroke-width="4">{''.join(strokes)}</g>
  </g>
"""


# 台所: れいぞうこ(段ボールの絵)が倒れて、うしろにドアが現れる (600,240)-(860,780)
KITCHEN_DOOR = f"""  <!-- ===== れいぞうこが あった ばしょ: 両親の部屋への ドア (600,240)-(860,780) ===== -->
  <g filter="url(#wc)">
    <rect x="590" y="210" width="280" height="572" fill="#C4A77F"/>
    <path d="M626 776 V330 Q626 262 730 262 Q834 262 834 330 V776 Z" fill="#B48A64"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="590" y="210" width="280" height="572"/>
    <g stroke="#A98C66" stroke-width="4" opacity="0.8"><path d="M606 220 V770"/><path d="M852 220 V770"/></g>
    <path d="M626 776 V330 Q626 262 730 262 Q834 262 834 330 V776 Z"/>
    <g stroke-width="3" opacity="0.6"><path d="M676 280 V776"/><path d="M730 262 V776"/><path d="M784 280 V776"/></g>
    <circle cx="812" cy="540" r="10" fill="{INK}"/>
    <!-- だれかが かいた ひょうさつ -->
    <rect x="672" y="350" width="116" height="48" rx="8" fill="#F3E6CF" stroke-width="3"/>
    <g stroke-width="3"><circle cx="702" cy="374" r="10"/><circle cx="758" cy="374" r="10"/><path d="M712 374 h36"/></g>
  </g>
  <!-- たおれた れいぞうこ(段ボールに かいた え) -->
  <g filter="url(#wc)">
    <polygon points="520,880 860,860 930,960 560,990" fill="#D9D2C2"/>
    <polygon points="545,895 640,889 690,972 580,980" fill="#E8E2D4" opacity="0.8"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" fill="none">
    <polygon points="520,880 860,860 930,960 560,990"/>
    <path d="M700 870 L752 974" stroke-width="4"/>
    <g stroke="#A98C66" stroke-width="3" opacity="0.8"><path d="M524 888 L566 984"/><path d="M856 866 L924 958"/></g>
  </g>
"""

EXTRA = {
    # 部屋: (元の絵, 追加する絵)
    "kitchen": ("kitchen_ch1.svg", lambda: KITCHEN_DOOR + peel(510, 90, 150, 150, 31) + peel(1420, 120, 240, 200, 32)
                + straw(1150, 980, 300, 26, 33) + straw(300, 860, 160, 12, 34)),
    "living_room": ("living_room_ch2.svg", lambda: peel(170, 70, 160, 140, 41) + peel(895, 150, 90, 300, 42)
                    + peel(1700, 70, 190, 220, 43) + straw(700, 1000, 380, 30, 44) + straw(1600, 860, 160, 12, 45)),
    "kids_room": ("kids_room_ch1.svg", lambda: peel(720, 70, 160, 190, 51) + peel(1660, 140, 220, 260, 52)
                  + peel(190, 120, 90, 250, 53) + straw(900, 980, 340, 26, 54)),
    "brother_room": ("brother_room_ch2.svg", lambda: peel(410, 120, 150, 240, 61) + peel(1400, 470, 160, 130, 62)
                     + peel(1750, 110, 150, 300, 63) + straw(700, 1000, 320, 24, 64)),
}


def remove_block(src, start, end):
    i = src.index(start)
    j = src.index(end)
    return src[:i] + src[j:]


def derive(room, base, extra):
    src = (ROOT / base).read_text(encoding="utf-8")
    assert MARK in src, room
    src = re.sub(r"\(第[12]章[^)]*\)", "(第3章「ひみつの部屋」: tools/gen_ch3_art.py で生成)", src, count=1)
    if room == "kitchen":
        src = remove_block(src, "  <!-- ===== れいぞうこ", "  <!-- ===== しょっきだな")
    # 2章の夕焼けの光は消す(居間は2章の伸びた植木鉢と小箱を引きつぐ)
    src = src.replace('  <rect width="1920" height="1080" fill="url(#ch2_evening)" style="mix-blend-mode:multiply"/>\n', "")
    if room == "brother_room":
        # 夕焼けの光は消す
        src = src.replace('  <rect width="1920" height="1080" fill="url(#evening)" style="mix-blend-mode:multiply"/>\n', "")
        src = re.sub(r'  <polygon points="1020,220[^\n]*filter="url\(#soft\)"/>\n', "", src)
    return src.replace(MARK, extra + GREY + "\n" + MARK)


def header(title):
    """kitchen_ch1.svg と共通のフィルタ(線のゆらぎ・水彩・紙)"""
    src = (ROOT / "kitchen_ch1.svg").read_text(encoding="utf-8")
    defs = src[src.index("  <defs>"):src.index("  </defs>") + len("  </defs>")]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">\n'
            f"  <!-- ひつじのおるすばん / {title}\n       tools/gen_ch3_art.py で生成。フィルタは kitchen_ch1.svg と共通 -->\n"
            + defs + "\n")


FOOTER = MARK + """
  <rect width="1920" height="1080" filter="url(#blotch)"/>
  <rect width="1920" height="1080" filter="url(#paper)"/>
</svg>
"""

PARENTS = f"""  <defs>
    <pattern id="wallpaper5" width="140" height="140" patternUnits="userSpaceOnUse">
      <rect width="140" height="140" fill="#EFE3D3"/>
      <path d="M70 20 q20 20 0 40 q-20 20 0 40 q20 20 0 40" stroke="#D9C3B8" stroke-width="6" fill="none"/>
      <circle cx="20" cy="70" r="6" fill="#D8C9D9"/><circle cx="120" cy="70" r="6" fill="#D8C9D9"/>
    </pattern>
    <linearGradient id="lamp" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#FFF3D6" stop-opacity="0.35"/><stop offset="1" stop-color="#FFF3D6" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <!-- ===== 壁と床 ===== -->
  <g filter="url(#wc)">
    <rect x="-20" y="-20" width="1960" height="680" fill="url(#wallpaper5)"/>
    <rect x="-20" y="640" width="1960" height="150" fill="#D8C8B4"/>
    <rect x="-20" y="780" width="1960" height="320" fill="#B99A7A"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-linecap="round" fill="none">
    <path d="M-10 640 H1930" stroke-width="5"/>
    <path d="M-10 780 H1930" stroke-width="6"/>
    <g stroke-width="3" opacity="0.45">
      <path d="M-10 840 H1930"/><path d="M-10 920 H1930"/><path d="M-10 1010 H1930"/>
      <path d="M300 840 L280 920"/><path d="M980 920 L960 1010"/><path d="M1700 780 L1690 840"/><path d="M640 1010 L620 1080"/>
    </g>
  </g>
{peel(560, 40, 140, 170, 71)}{peel(900, 90, 110, 260, 72)}{peel(1500, 60, 120, 180, 73)}
  <!-- ===== だいどころへのドア (10,380)-(160,780) ===== -->
  <g filter="url(#wc)"><path d="M16 776 V450 Q16 386 85 386 Q154 386 154 450 V776 Z" fill="#B48A64"/></g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" fill="none">
    <path d="M16 776 V450 Q16 386 85 386 Q154 386 154 450 V776 Z"/>
    <g stroke-width="3" opacity="0.6"><path d="M62 400 V776"/><path d="M108 400 V776"/></g>
    <circle cx="140" cy="610" r="9" fill="{INK}"/>
  </g>

  <!-- ===== ようふくだんす (240,220)-(520,780) ===== -->
  <g filter="url(#wc)">
    <rect x="244" y="226" width="272" height="550" rx="10" fill="#B98258"/>
    <rect x="262" y="250" width="114" height="440" rx="6" fill="#C8956A"/>
    <rect x="384" y="250" width="114" height="440" rx="6" fill="#C8956A"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="244" y="226" width="272" height="550" rx="10"/>
    <rect x="262" y="250" width="114" height="440" rx="6"/>
    <rect x="384" y="250" width="114" height="440" rx="6"/>
    <path d="M362 450 v40 M398 450 v40" stroke-width="7"/>
    <path d="M244 712 H516" stroke-width="4"/>
    <!-- すこし あいた すきまから えりまき(かあさんの もの?) -->
    <path d="M376 520 q14 30 0 70" stroke="#C97A84" stroke-width="8"/>
    <path d="M262 776 v14 M498 776 v14" stroke-width="10"/>
  </g>

  <!-- ===== かぞくの しゃしん (620,260)-(860,440) ===== -->
  <g filter="url(#wc)">
    <rect x="626" y="266" width="228" height="168" rx="6" fill="#D9B48A"/>
    <rect x="644" y="284" width="192" height="132" fill="#E9F0E2"/>
    <ellipse cx="740" cy="410" rx="100" ry="26" fill="#B9D3A6"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="626" y="266" width="228" height="168" rx="6" stroke-width="5"/>
    <rect x="644" y="284" width="192" height="132"/>
    <!-- とうさんと かあさん(大きい ひつじ)。耳に きいろい ふだ -->
    <g fill="#FFFFFF"><circle cx="690" cy="372" r="24"/><circle cx="706" cy="360" r="20"/><circle cx="776" cy="372" r="24"/><circle cx="792" cy="360" r="20"/></g>
    <g fill="{INK}"><ellipse cx="672" cy="352" rx="11" ry="14"/><ellipse cx="758" cy="352" rx="11" ry="14"/></g>
    <g fill="#E8C267" stroke-width="2"><rect x="656" y="334" width="10" height="12" rx="2"/><rect x="742" y="334" width="10" height="12" rx="2"/></g>
    <path d="M690 396 v12 M706 396 v12 M776 396 v12 M792 396 v12" stroke-width="3"/>
  </g>
  <path d="M740 266 L700 230 L780 230 Z" fill="none" stroke="{INK}" stroke-width="3" filter="url(#wobble)"/>

  <!-- ===== とうさんの どうぐばこ (600,660)-(900,800) ===== -->
  <g filter="url(#wc)">
    <rect x="610" y="700" width="280" height="96" rx="10" fill="#B85C52"/>
    <rect x="604" y="684" width="292" height="30" rx="8" fill="#C96E62"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="610" y="700" width="280" height="96" rx="10"/>
    <rect x="604" y="684" width="292" height="30" rx="8"/>
    <path d="M700 684 V662 H800 V684" stroke-width="7"/>
    <rect x="736" y="722" width="28" height="20" rx="4" fill="#E8C267" stroke-width="3"/>
    <!-- はみだした かなづちの え -->
    <path d="M880 690 l40 -50" stroke-width="8"/>
    <rect x="906" y="622" width="40" height="22" rx="4" transform="rotate(-50 926 633)" fill="#9AA0A6" stroke-width="4"/>
  </g>

  <!-- ===== ふたりの ベッド (980,540)-(1560,860) ===== -->
  <g filter="url(#wc)">
    <rect x="990" y="520" width="60" height="330" rx="22" fill="#B98258"/>
    <rect x="1500" y="600" width="56" height="250" rx="22" fill="#B98258"/>
    <rect x="1040" y="660" width="470" height="150" rx="18" fill="#F6EFE3"/>
    <path d="M1040 700 Q1270 640 1510 700 V810 H1040 Z" fill="#C9B6D6"/>
    <ellipse cx="1120" cy="660" rx="64" ry="30" fill="#FFFFFF"/>
    <ellipse cx="1250" cy="656" rx="64" ry="30" fill="#FFFFFF"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="990" y="520" width="60" height="330" rx="22"/>
    <rect x="1500" y="600" width="56" height="250" rx="22"/>
    <rect x="1040" y="660" width="470" height="150" rx="18"/>
    <path d="M1040 700 Q1270 640 1510 700 V810 H1040 Z"/>
    <ellipse cx="1120" cy="660" rx="64" ry="30"/>
    <ellipse cx="1250" cy="656" rx="64" ry="30"/>
    <g stroke="#FFFFFF" stroke-width="4" opacity="0.7"><path d="M1100 740 h60"/><path d="M1300 730 h60"/><path d="M1200 770 h60"/></g>
    <path d="M1000 850 v24 M1546 850 v24" stroke-width="12"/>
  </g>

  <!-- ===== ぬのを かけた かがみと たんす (1620,260)-(1880,800) ===== -->
  <g filter="url(#wc)">
    <rect x="1626" y="560" width="250" height="236" rx="10" fill="#B98258"/>
    <path d="M1660 560 V300 Q1660 266 1750 266 Q1840 266 1840 300 V560 Z" fill="#9AA6B0"/>
    <path d="M1650 290 Q1750 240 1852 290 L1866 520 Q1820 545 1790 520 Q1750 550 1712 522 Q1676 548 1638 520 Z" fill="#E6E0D6"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="1626" y="560" width="250" height="236" rx="10"/>
    <path d="M1626 640 H1876 M1626 718 H1876" stroke-width="4"/>
    <g fill="{INK}"><rect x="1736" y="594" width="30" height="10" rx="4"/><rect x="1736" y="674" width="30" height="10" rx="4"/><rect x="1736" y="750" width="30" height="10" rx="4"/></g>
    <path d="M1660 560 V300 Q1660 266 1750 266 Q1840 266 1840 300 V560"/>
    <path d="M1650 290 Q1750 240 1852 290 L1866 520 Q1820 545 1790 520 Q1750 550 1712 522 Q1676 548 1638 520 Z"/>
    <g stroke-width="3" opacity="0.5"><path d="M1700 300 q10 100 0 210"/><path d="M1790 290 q-12 110 0 220"/></g>
  </g>

  <!-- ===== ゆかの かくしとびら (1060,900)-(1420,1040) ===== -->
  <g filter="url(#wc)">
    <polygon points="1080,910 1400,910 1424,1036 1056,1036" fill="#9C7A5A"/>
  </g>
  <g filter="url(#wobble)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <polygon points="1080,910 1400,910 1424,1036 1056,1036"/>
    <g stroke-width="3" opacity="0.6"><path d="M1160 910 L1152 1036"/><path d="M1240 910 L1240 1036"/><path d="M1320 910 L1328 1036"/></g>
    <rect x="1360" y="950" width="40" height="14" rx="6" fill="{INK}"/>
    <!-- みみの ふだの かたちの くぼみ -->
    <path d="M1206 944 h56 q12 0 12 12 v36 q0 12 -12 12 h-56 q-12 0 -12 -12 v-36 q0 -12 12 -12 Z" fill="#6F563F" stroke-width="4"/>
    <circle cx="1234" cy="956" r="6" fill="#9C7A5A" stroke-width="3"/>
  </g>
{straw(1700, 960, 180, 16, 74)}{straw(400, 1000, 220, 14, 75)}
  <rect width="1920" height="700" fill="url(#lamp)"/>
"""

BASEMENT = f"""  <defs>
    <linearGradient id="dark" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3E352E" stop-opacity="0.55"/><stop offset="0.6" stop-color="#3E352E" stop-opacity="0.15"/><stop offset="1" stop-color="#3E352E" stop-opacity="0.4"/>
    </linearGradient>
    <radialGradient id="shaft" cx="0.5" cy="0" r="1">
      <stop offset="0" stop-color="#FFF4D6" stop-opacity="0.55"/><stop offset="1" stop-color="#FFF4D6" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- ===== いたかべ と つちの ゆか ===== -->
  <g filter="url(#wc)">
    <rect x="-20" y="-20" width="1960" height="740" fill="#8E7660"/>
    <rect x="-20" y="700" width="1960" height="400" fill="#7A6450"/>
    <ellipse cx="1220" cy="900" rx="620" ry="150" fill="#A68C5E" opacity="0.7"/>
  </g>
  <g filter="url(#wobble)" stroke="#3E3026" stroke-linecap="round" fill="none">
    <g stroke-width="4" opacity="0.6">
      {''.join(f'<path d="M{x} -10 V700"/>' for x in range(60, 1920, 130))}
    </g>
    <path d="M-10 700 H1930" stroke-width="6"/>
    <g stroke-width="3" opacity="0.4"><path d="M200 220 q20 4 30 -6"/><path d="M1300 160 q20 4 30 -6"/><path d="M820 520 q20 4 30 -6"/></g>
  </g>
  <!-- たかい ところの ちいさな まど(ひかりが さしこむ) -->
  <g filter="url(#wc)"><rect x="1120" y="60" width="200" height="60" fill="#DCE4E6"/></g>
  <g filter="url(#wobble)" stroke="#3E3026" stroke-width="5" fill="none"><rect x="1120" y="60" width="200" height="60"/><path d="M1186 60 v60 M1252 60 v60"/></g>
  <polygon points="1120,120 1320,120 1520,900 900,900" fill="url(#shaft)" filter="url(#soft)"/>

  <!-- ===== うえへの はしご (80,120)-(300,820) ===== -->
  <g filter="url(#wc)"><rect x="60" y="-20" width="260" height="120" fill="#C9B79A"/></g>
  <g filter="url(#wobble)" stroke="#3E3026" stroke-width="7" stroke-linecap="round" fill="none">
    <path d="M110 40 L130 820 M270 40 L250 820"/>
    <g stroke-width="6">{''.join(f'<path d="M{114 + i * 0.4:.0f} {100 + i * 90} H{266 - i * 0.4:.0f}"/>' for i in range(8))}</g>
    <path d="M60 100 H320" stroke-width="5"/>
  </g>

  <!-- ===== さくと とびら(謎9) (520,300)-(1000,760) ===== -->
  <g filter="url(#wc)">
    <rect x="530" y="420" width="460" height="300" fill="#B08E66" opacity="0.6"/>
  </g>
  <g filter="url(#wobble)" stroke="#3E3026" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <g stroke="#C9A877" stroke-width="16">
      <path d="M540 440 H980"/><path d="M540 560 H980"/><path d="M540 680 H980"/>
      <path d="M560 400 V740"/><path d="M700 400 V740"/><path d="M840 400 V740"/><path d="M970 400 V740"/>
    </g>
    <path d="M540 440 H980 M540 560 H980 M540 680 H980" stroke-width="4"/>
    <path d="M560 400 V740 M700 400 V740 M840 400 V740 M970 400 V740" stroke-width="4"/>
    <!-- ななめの とびら(かんぬき) -->
    <path d="M700 440 L840 680" stroke="#C9A877" stroke-width="16"/>
    <path d="M700 440 L840 680" stroke-width="4"/>
    <!-- さくに かけられた いたの ずめん -->
    <rect x="600" y="300" width="300" height="110" rx="6" fill="#E7DCC6" stroke-width="5"/>
    <g stroke-width="3"><rect x="620" y="318" width="80" height="34"/><rect x="700" y="318" width="80" height="34"/><rect x="780" y="318" width="100" height="34"/><rect x="620" y="352" width="120" height="40"/><rect x="740" y="352" width="140" height="40"/></g>
  </g>

  <!-- ===== かいばおけ (1100,560)-(1380,700) ===== -->
  <g filter="url(#wc)"><polygon points="1110,580 1370,580 1340,690 1140,690" fill="#9C7A5A"/></g>
  <g filter="url(#wobble)" stroke="#3E3026" stroke-width="6" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <polygon points="1110,580 1370,580 1340,690 1140,690"/>
    <path d="M1150 690 v30 M1330 690 v30" stroke-width="9"/>
    <g stroke="#E3CB82" stroke-width="4"><path d="M1130 584 q30 -20 60 -4"/><path d="M1200 582 q40 -24 70 0"/><path d="M1280 584 q30 -18 70 -2"/></g>
  </g>

  <!-- ===== わらの やま (1060,760)-(1400,960) かあさんの リボンが のぞく ===== -->
  <g filter="url(#wc)">
    <path d="M1060 950 Q1080 800 1230 770 Q1380 790 1400 950 Z" fill="#D9C27A"/>
  </g>
{straw(1230, 880, 150, 40, 81)}  <g filter="url(#wobble)" stroke="#3E3026" stroke-width="5" stroke-linejoin="round" fill="none">
    <path d="M1060 950 Q1080 800 1230 770 Q1380 790 1400 950 Z"/>
    <path d="M1300 860 q22 -10 34 6 q-10 18 -34 -6 Z" fill="#D9707E" stroke-width="3"/>
    <path d="M1304 864 q-6 24 -20 34" stroke="#D9707E" stroke-width="6"/>
  </g>

  <!-- ===== ふるい トランク (1460,560)-(1800,800) ===== -->
  <g filter="url(#wc)">
    <rect x="1470" y="620" width="320" height="176" rx="12" fill="#8F6A4C"/>
    <path d="M1470 640 Q1630 560 1790 640 Z" fill="#9F7A58"/>
  </g>
  <g filter="url(#wobble)" stroke="#3E3026" stroke-width="6" stroke-linejoin="round" stroke-linecap="round" fill="none">
    <rect x="1470" y="620" width="320" height="176" rx="12"/>
    <path d="M1470 640 Q1630 560 1790 640"/>
    <path d="M1540 600 V796 M1720 600 V796" stroke="#C9A877" stroke-width="12"/>
    <path d="M1540 600 V796 M1720 600 V796" stroke-width="3"/>
    <rect x="1612" y="660" width="36" height="40" rx="6" fill="#C9A877" stroke-width="4"/>
    <!-- すきまから はみでた てがみの きれはし -->
    <path d="M1580 636 l30 -20 l14 16 l-30 18 Z" fill="#F3EAD8" stroke-width="3"/>
  </g>
{straw(500, 940, 340, 30, 82)}{straw(1650, 900, 200, 16, 83)}
  <rect width="1920" height="1080" fill="url(#dark)" style="mix-blend-mode:multiply"/>
"""


def main():
    for room, (base, extra) in EXTRA.items():
        (ROOT / f"{room}_ch3.svg").write_text(derive(room, base, extra()), encoding="utf-8")
        print("wrote", room)
    (ROOT / "parents_room_ch3.svg").write_text(
        header("両親の部屋(第3章「ひみつの部屋」)") + "\n" + PARENTS + GREY + "\n" + FOOTER, encoding="utf-8")
    print("wrote parents_room")
    (ROOT / "basement_ch3.svg").write_text(
        header("地下室(第3章「ひみつの部屋」)") + "\n" + BASEMENT + GREY + "\n" + FOOTER, encoding="utf-8")
    print("wrote basement")


if __name__ == "__main__":
    main()
