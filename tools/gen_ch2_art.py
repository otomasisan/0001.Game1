"""第1章の部屋の絵(art/src/*_ch1.svg)から、第2章「ながい夕方」の差分(*_ch2.svg)を作る。
夕焼けの光を重ね、部屋ごとの変化(伸びた植木鉢、ソファの上の小箱など)を足す。
使い方: python3 tools/gen_ch2_art.py  → そのあと tools/render_svg.js で PNG に書き出す
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "art" / "src"
MARK = "  <!-- ===== 紙の質感 ===== -->"

EVENING = """  <!-- ===== 第2章: 夕焼けの光 ===== -->
  <defs>
    <linearGradient id="ch2_evening" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#F59A62" stop-opacity="0.34"/>
      <stop offset="0.6" stop-color="#E9877A" stop-opacity="0.22"/>
      <stop offset="1" stop-color="#7E5E96" stop-opacity="0.2"/>
    </linearGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#ch2_evening)" style="mix-blend-mode:multiply"/>
"""

SUNSET_WINDOW = """  <!-- 窓の外も夕焼けに -->
  <g clip-path="url(#{clip})" filter="url(#wc)">
    <rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#F4A47C" opacity="0.82"/>
    <circle cx="{sx}" cy="{sy}" r="26" fill="#F06A3C" opacity="0.85"/>
  </g>
"""

EXTRA = {
    "kitchen": SUNSET_WINDOW.format(clip="glass", x=160, y=280, w=320, h=280, sx=420, sy=470),
    "kids_room": SUNSET_WINDOW.format(clip="glass2", x=1300, y=240, w=300, h=300, sx=1540, sy=470),
    "living_room": """  <!-- 植木鉢が、ありえないほど伸びている -->
  <g filter="url(#wobble)" stroke="#5A4636" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none">
    <path d="M605 660 C 590 560, 650 520, 620 440 S 560 300, 610 200 S 700 90, 660 -10" stroke="#6F9A5A" stroke-width="7"/>
    <g fill="#9CC47F" stroke-width="3">
      <ellipse cx="585" cy="590" rx="22" ry="11" transform="rotate(-30 585 590)"/>
      <ellipse cx="640" cy="520" rx="22" ry="11" transform="rotate(25 640 520)"/>
      <ellipse cx="598" cy="430" rx="22" ry="11" transform="rotate(-35 598 430)"/>
      <ellipse cx="572" cy="330" rx="22" ry="11" transform="rotate(-10 572 330)"/>
      <ellipse cx="636" cy="250" rx="22" ry="11" transform="rotate(30 636 250)"/>
      <ellipse cx="612" cy="160" rx="22" ry="11" transform="rotate(-25 612 160)"/>
      <ellipse cx="690" cy="80" rx="22" ry="11" transform="rotate(20 690 80)"/>
    </g>
  </g>
  <!-- さっきまで なかった 小箱(ソファの上) (1210,640)-(1340,740) -->
  <g filter="url(#wc)">
    <rect x="1216" y="664" width="118" height="72" rx="8" fill="#C99A6B"/>
    <rect x="1210" y="646" width="130" height="24" rx="8" fill="#B98258"/>
  </g>
  <g filter="url(#wobble)" stroke="#5A4636" stroke-width="5" stroke-linejoin="round" fill="none">
    <rect x="1216" y="664" width="118" height="72" rx="8"/>
    <rect x="1210" y="646" width="130" height="24" rx="8"/>
    <g fill="#FFF8E8" stroke-width="3">
      <rect x="1230" y="684" width="24" height="30" rx="4"/><rect x="1263" y="684" width="24" height="30" rx="4"/><rect x="1296" y="684" width="24" height="30" rx="4"/>
    </g>
  </g>
""",
}


def main():
    for room, extra in EXTRA.items():
        src = (ROOT / f"{room}_ch1.svg").read_text(encoding="utf-8")
        assert MARK in src, room
        out = src.replace("(第1章「通常」)", "(第2章「ながい夕方」: tools/gen_ch2_art.py で生成)")
        out = out.replace(MARK, extra + EVENING + "\n" + MARK)
        (ROOT / f"{room}_ch2.svg").write_text(out, encoding="utf-8")
        print("wrote", room)


if __name__ == "__main__":
    main()
