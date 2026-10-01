"""Generise assets/icon.ico i icon.png (zupcanik + kvacica = masinska obrada + odradjeno)."""
import math
from PIL import Image, ImageDraw

S = 1024
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
# podloga: zaobljeni kvadrat, tamnoplavi gradijent
bg = Image.new("RGBA", (S, S))
bd = ImageDraw.Draw(bg)
for y in range(S):
    t = y / S
    bd.line([(0, y), (S, y)], fill=(int(24 + 10 * t), int(70 + 30 * t), int(150 + 40 * t), 255))
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([20, 20, S - 20, S - 20], radius=210, fill=255)
img.paste(bg, (0, 0), mask)
d = ImageDraw.Draw(img)
# zupcanik
cx, cy, R, r, teeth = 470, 480, 330, 265, 10
pts = []
for i in range(teeth * 4):
    a = 2 * math.pi * i / (teeth * 4) - math.pi / 2
    rad = R if i % 4 in (1, 2) else r
    a0 = a + (0.0 if i % 4 else 0)
    pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
d.polygon(pts, fill=(255, 255, 255, 255))
d.ellipse([cx - r + 40, cy - r + 40, cx + r - 40, cy + r - 40], fill=(255, 255, 255, 255))
d.ellipse([cx - 120, cy - 120, cx + 120, cy + 120], fill=(31, 95, 191, 255))
# zelena kruznica sa kvacicom (donji desni ugao)
kx, ky, kr = 700, 700, 215
d.ellipse([kx - kr - 22, ky - kr - 22, kx + kr + 22, ky + kr + 22], fill=(31, 95, 191, 255))
d.ellipse([kx - kr, ky - kr, kx + kr, ky + kr], fill=(46, 170, 90, 255))
d.line([(kx - 105, ky + 5), (kx - 25, ky + 85), (kx + 110, ky - 80)], fill="white", width=58, joint="curve")
for p in [(kx - 105, ky + 5), (kx - 25, ky + 85), (kx + 110, ky - 80)]:
    d.ellipse([p[0] - 29, p[1] - 29, p[0] + 29, p[1] + 29], fill="white")
img.resize((512, 512), Image.LANCZOS).save("assets/icon.png")
img.save("assets/icon.ico", sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)])
