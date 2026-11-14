from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
BG = ASSETS / "backgrounds"
CHAR = ASSETS / "character"
UI = ASSETS / "ui"
for folder in (BG, CHAR, UI):
    folder.mkdir(parents=True, exist_ok=True)

random.seed(26)


def textured_polygon(image, points, base, variation=18, step=9):
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(points, fill=base)
    pixels = layer.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a:
                delta = random.randint(-variation, variation)
                pixels[x, y] = (max(0, min(255, r + delta)), max(0, min(255, g + delta)), max(0, min(255, b + delta)), a)
    image.alpha_composite(layer)


def create_backdrops():
    w, h = 1920, 1080
    sky = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(sky)
    for y in range(h):
        t = y / h
        d.line((0, y, w, y), fill=(int(34 + 218 * (1 - t)), int(47 + 143 * (1 - t)), int(83 + 67 * (1 - t)), 255))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for radius in range(220, 0, -4):
        alpha = int(3 + 22 * radius / 220)
        gd.ellipse((1450 - radius, 170 - radius, 1690 + radius, 410 + radius), outline=(255, 213, 160, alpha), width=4)
    gd.ellipse((1450, 170, 1690, 410), fill=(255, 213, 159, 255))
    gd.ellipse((1492, 205, 1645, 358), fill=(255, 170, 111, 130))
    sky.alpha_composite(glow.filter(ImageFilter.GaussianBlur(12)))
    sky.save(BG / "sky_backdrop.png")

    def ridge_asset(name, size, layers, base_y, palette, sharpness):
        image = Image.new("RGBA", size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        width, height = size
        for row in range(layers):
            offset = row * 95
            points = [(-100, height)]
            for x in range(-100, width + 120, 12):
                wave = 0.52 * __import__("math").sin(x * 0.0025 + row * 1.4)
                wave += 0.27 * __import__("math").sin(x * 0.0061 + row * 2.3)
                wave += 0.12 * __import__("math").sin(x * 0.013 + row * 0.7)
                peak = base_y - offset - 130 - 115 * wave + random.randint(-5, 5)
                points.append((x, peak))
            points.extend([(width + 120, height), (-100, height)])
            color = palette[row % len(palette)]
            draw.polygon(points, fill=color)
            # Warm edge planes and eroded strata give the raster art more depth.
            for i in range(36):
                x = random.randint(0, width - 80)
                y = random.randint(max(0, base_y - offset - 120), min(height - 30, base_y - offset + 180))
                line_w = random.randint(50, 250)
                draw.line((x, y, x + line_w, y + random.randint(-5, 7)), fill=(*palette[(row + 1) % len(palette)][:3], random.randint(15, 55)), width=random.randint(2, 5))
        image = image.filter(ImageFilter.GaussianBlur(1.4 if "far" in name else 0.6))
        image.save(BG / name)

    ridge_asset("mountain_far.png", (1920, 720), 3, 560, [(91, 73, 83, 210), (121, 84, 83, 195), (146, 98, 88, 175)], 260)
    ridge_asset("mountain_mid.png", (1920, 760), 3, 660, [(151, 99, 79, 230), (186, 128, 93, 220), (205, 146, 106, 200)], 210)

    dunes = Image.new("RGBA", (1920, 600), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dunes)
    for layer in range(5):
        points = [(-100, 600)]
        for x in range(-100, 2100, 20):
            y = 255 + layer * 55 + int(44 * __import__("math").sin(x * 0.004 + layer * 1.7)) + int(15 * __import__("math").sin(x * 0.013 + layer))
            points.append((x, y))
        points.append((2020, 600))
        color = [(238, 175, 119, 225), (213, 143, 101, 225), (186, 117, 87, 230), (152, 91, 73, 235), (109, 65, 64, 245)][layer]
        dd.polygon(points, fill=color)
        for _ in range(130):
            x = random.randrange(1920)
            y = random.randrange(250 + layer * 30, 600)
            dd.line((x, y, x + random.randrange(10, 65), y + random.randrange(-2, 3)), fill=(255, 219, 171, random.randrange(18, 54)), width=random.choice((1, 2, 3)))
    dunes = dunes.filter(ImageFilter.GaussianBlur(0.7))
    dunes.save(BG / "dune_front.png")

    terrain = Image.new("RGBA", (512, 512), (91, 47, 53, 255))
    td = ImageDraw.Draw(terrain)
    for y in range(512):
        light = max(0, 40 - y // 13)
        td.line((0, y, 512, y), fill=(91 + light, 47 + light // 2, 53 + light // 3, 255))
    for _ in range(6500):
        x, y = random.randrange(512), random.randrange(512)
        base = random.choice(((205, 137, 108), (58, 34, 45), (166, 93, 82), (124, 66, 70)))
        td.point((x, y), fill=(*base, 255))
    for stripe in range(30):
        y = random.randrange(25, 512)
        x = random.randrange(-120, 512)
        length = random.randrange(100, 440)
        color = random.choice(((228, 157, 111, 255), (125, 68, 69, 255), (185, 112, 91, 255)))
        td.line((x, y, x + length, y + random.randrange(-9, 10)), fill=color, width=random.randrange(2, 8))
    terrain = terrain.filter(ImageFilter.GaussianBlur(0.5))
    terrain.save(BG / "terrain_paint.png")

    ruins = Image.new("RGBA", (1920, 620), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ruins)
    sandstone = (97, 60, 53, 225)
    lit_stone = (177, 115, 82, 220)
    for x in (100, 530, 990, 1510):
        base = 570
        tower_w = random.randint(92, 155)
        tower_h = random.randint(250, 390)
        rd.rectangle((x, base - tower_h, x + tower_w, base), fill=sandstone)
        rd.polygon([(x - 18, base - tower_h), (x + tower_w // 2, base - tower_h - 34), (x + tower_w + 18, base - tower_h)], fill=lit_stone)
        rd.line((x + 12, base - tower_h + 18, x + tower_w - 8, base - tower_h + 18), fill=(237, 174, 123, 170), width=5)
        for wy in range(base - tower_h + 58, base - 25, 72):
            rd.rounded_rectangle((x + tower_w // 2 - 13, wy, x + tower_w // 2 + 13, wy + 48), radius=13, fill=(45, 37, 45, 200))
            rd.line((x + tower_w // 2 - 16, wy, x + tower_w // 2 + 16, wy), fill=(227, 157, 110, 150), width=3)
    # Broken archways and colonnades
    for x in (300, 760, 1240, 1740):
        base = 580
        rd.rectangle((x, base - 150, x + 24, base), fill=lit_stone)
        rd.rectangle((x + 134, base - 175, x + 158, base), fill=sandstone)
        rd.arc((x + 2, base - 238, x + 156, base - 98), 180, 360, fill=(202, 143, 104, 220), width=18)
        rd.rectangle((x - 2, base - 173, x + 8, base - 145), fill=sandstone)
        rd.rectangle((x + 148, base - 193, x + 162, base - 166), fill=lit_stone)
        rd.line((x - 18, base, x + 180, base), fill=(227, 157, 111, 190), width=7)
    # Painted surface wear and windblown dust
    for _ in range(1400):
        x = random.randrange(1920)
        y = random.randrange(150, 590)
        rd.point((x, y), fill=(255, 208, 154, random.randrange(12, 72)))
    ruins = ruins.filter(ImageFilter.GaussianBlur(0.8))
    ruins.save(BG / "ruins_silhouette.png")


def character_sheet():
    cell, frames = 256, 6
    sheet = Image.new("RGBA", (cell * frames, cell * 7), (0, 0, 0, 0))
    for row in range(7):
        for col in range(frames):
            image = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
            d = ImageDraw.Draw(image)
            cx, cy = 128, 125
            bob = (col % 3) * 2 - 2
            # Board, bindings and cast shadow are painted into each frame.
            d.ellipse((30, 204, 224, 239), fill=(35, 24, 31, 62))
            d.polygon([(38, 196, ), (201, 188), (229, 204), (42, 217)], fill=(77, 42, 40, 255))
            d.polygon([(43, 192), (194, 185), (217, 198), (45, 209)], fill=(238, 169, 91, 255))
            d.line((55, 198, 185, 192), fill=(255, 230, 177, 220), width=3)
            d.line((90, 189, 89, 205), fill=(81, 45, 45, 255), width=5)
            d.line((152, 186, 155, 201), fill=(81, 45, 45, 255), width=5)

            if row == 0:  # running cycle, six distinct poses
                phase = col / 6 * 6.283
                stride = int(18 * __import__("math").sin(phase))
                head_x, head_y = 135, 57 + bob
                # Rear leg and boot
                d.line((122, 135, 109 - stride, 171), fill=(63, 47, 48, 255), width=15)
                d.line((109 - stride, 171, 83 - stride, 185), fill=(45, 34, 39, 255), width=13)
                # Coat silhouette and lit panels
                d.polygon([(104, 83), (143, 81), (166, 133), (147, 155), (99, 147), (91, 111)], fill=(94, 54, 51, 255))
                d.polygon([(109, 83), (142, 84), (155, 131), (137, 142), (107, 134)], fill=(204, 113, 78, 255))
                d.polygon([(115, 91), (137, 89), (147, 123), (132, 130)], fill=(236, 153, 101, 255))
                # Forward leg and boot
                d.line((143, 137, 151 + stride, 171), fill=(72, 49, 48, 255), width=15)
                d.line((151 + stride, 171, 178 + stride, 183), fill=(44, 34, 39, 255), width=13)
                # Face profile, hair, head wrap and flying scarf
                d.polygon([(118, 32), (137, 27), (154, 38), (158, 53), (150, 66), (132, 69), (118, 59)], fill=(240, 189, 144, 255))
                d.polygon([(116, 46), (119, 29), (138, 21), (155, 31), (152, 39), (135, 36), (125, 45)], fill=(40, 28, 32, 255))
                d.polygon([(118, 39), (144, 34), (158, 39), (154, 47), (128, 48)], fill=(47, 34, 39, 255))
                d.line((149, 49, 155, 50), fill=(40, 29, 32, 255), width=3)
                d.polygon([(106, 69), (131, 76), (150, 90), (138, 95), (111, 82), (80, 95), (103, 78)], fill=(226, 138, 90, 255))
                # Arms with cuffs and hands
                d.line((105, 97, 82, 125 + stride // 2), fill=(88, 53, 49, 255), width=12)
                d.line((82, 125 + stride // 2, 72, 134 + stride // 2), fill=(236, 190, 145, 255), width=8)
                d.line((149, 98, 171, 119 - stride // 2), fill=(88, 53, 49, 255), width=12)
                d.line((171, 119 - stride // 2, 181, 125 - stride // 2), fill=(236, 190, 145, 255), width=8)
                d.line((106, 106, 100, 120), fill=(251, 191, 131, 220), width=3)
            elif row == 1:  # takeoff and glide
                tilt = (col - 2) * 5
                d.line((122, 135, 106, 169), fill=(68, 47, 49, 255), width=14)
                d.line((106, 169, 88, 179), fill=(44, 33, 39, 255), width=12)
                d.line((144, 134, 158, 165), fill=(68, 47, 49, 255), width=14)
                d.line((158, 165, 181, 170), fill=(44, 33, 39, 255), width=12)
                d.polygon([(104, 83), (145, 78), (161, 133), (142, 148), (101, 138)], fill=(207, 119, 79, 255))
                d.polygon([(117, 90), (138, 87), (150, 126), (132, 134)], fill=(239, 158, 103, 255))
                d.polygon([(120, 35), (139, 26), (156, 36), (159, 53), (149, 66), (130, 67), (118, 56)], fill=(240, 189, 144, 255))
                d.polygon([(115, 46), (120, 29), (140, 21), (155, 31), (152, 40), (131, 37)], fill=(40, 28, 32, 255))
                d.polygon([(108, 72), (134, 79), (154, 91), (140, 98), (108, 84), (77, 96), (103, 80)], fill=(231, 141, 91, 255))
                arm_raise = 20 if col > 2 else -8
                d.line((104, 97, 79, 82 - arm_raise), fill=(91, 55, 50, 255), width=12)
                d.line((79, 82 - arm_raise, 69, 73 - arm_raise), fill=(239, 190, 142, 255), width=8)
                d.line((149, 97, 174, 76 - arm_raise), fill=(91, 55, 50, 255), width=12)
                d.line((174, 76 - arm_raise, 184, 70 - arm_raise), fill=(239, 190, 142, 255), width=8)
            elif row == 2:  # low sliding silhouette
                d.line((78, 160, 184, 160), fill=(52, 38, 42, 255), width=17)
                d.line((94, 151, 188, 151), fill=(204, 113, 78, 255), width=25)
                d.polygon([(125, 115), (161, 101), (182, 128), (152, 154), (91, 154), (79, 141)], fill=(206, 117, 81, 255))
                d.polygon([(123, 120), (156, 109), (169, 130), (147, 143), (100, 145)], fill=(240, 158, 101, 255))
                d.polygon([(135, 80), (151, 75), (167, 87), (164, 103), (151, 115), (134, 106), (126, 93)], fill=(240, 189, 144, 255))
                d.polygon([(128, 90), (128, 77), (143, 68), (160, 77), (163, 85), (146, 81), (134, 91)], fill=(40, 28, 32, 255))
                d.line((143, 98, 151, 96), fill=(40, 29, 32, 255), width=3)
                d.polygon([(129, 106), (147, 108), (163, 122), (151, 128), (132, 117), (107, 125)], fill=(226, 138, 90, 255))
                d.line((110, 122, 84, 146), fill=(84, 51, 49, 255), width=10)
                d.line((84, 146, 74, 145), fill=(239, 190, 142, 255), width=7)
            elif row == 3:  # backflip frames
                angle = col * 60
                d.ellipse((45, 63, 211, 183), outline=(255, 194, 117, 80), width=4)
                d.arc((45, 63, 211, 183), angle, angle + 120, fill=(255, 215, 160, 230), width=5)
                d.ellipse((112, 62, 155, 104), fill=(240, 189, 144, 255))
                d.polygon([(110, 70), (113, 54), (134, 46), (154, 56), (151, 66), (129, 63)], fill=(40, 28, 32, 255))
                d.polygon([(106, 105), (147, 101), (161, 142), (131, 157), (96, 137)], fill=(211, 120, 80, 255))
                d.polygon([(116, 107), (141, 106), (151, 136), (130, 146)], fill=(240, 157, 102, 255))
                d.line((112, 132, 80, 161), fill=(72, 49, 48, 255), width=12)
                d.line((146, 132, 178, 160), fill=(72, 49, 48, 255), width=12)
                d.line((108, 107, 74, 91), fill=(87, 52, 49, 255), width=10)
                d.line((150, 108, 180, 87), fill=(87, 52, 49, 255), width=10)
            elif row == 4:  # landing compression and recovery
                d.polygon([(103, 89), (146, 84), (164, 137), (145, 151), (102, 146)], fill=(205, 114, 78, 255))
                d.polygon([(117, 97), (140, 95), (151, 130), (132, 138)], fill=(239, 157, 103, 255))
                d.polygon([(119, 42), (140, 34), (157, 45), (156, 63), (144, 74), (127, 68)], fill=(240, 189, 144, 255))
                d.polygon([(116, 50), (120, 35), (139, 28), (155, 37), (151, 47), (132, 44)], fill=(40, 28, 32, 255))
                d.line((112, 138, 98, 165), fill=(69, 47, 48, 255), width=13)
                d.line((145, 138, 161, 165), fill=(69, 47, 48, 255), width=13)
                d.line((99, 165, 80, 172), fill=(45, 34, 39, 255), width=12)
                d.line((161, 165, 181, 171), fill=(45, 34, 39, 255), width=12)
                d.arc((48, 165, 208, 233), 195, 345, fill=(255, 209, 146, 210), width=4)
            elif row == 5:  # Echo activation: windblown scarf, light on clothing
                d.ellipse((76, 62, 184, 174), outline=(113, 239, 255, 145), width=5)
                d.ellipse((89, 74, 171, 158), outline=(153, 246, 255, 100), width=3)
                d.polygon([(103, 84), (145, 79), (164, 137), (143, 150), (100, 141)], fill=(53, 126, 145, 255))
                d.polygon([(116, 92), (139, 88), (151, 129), (131, 136)], fill=(113, 217, 218, 255))
                d.polygon([(119, 38), (140, 30), (157, 41), (157, 60), (145, 72), (128, 66)], fill=(240, 189, 144, 255))
                d.polygon([(116, 47), (120, 31), (140, 24), (156, 34), (152, 44), (132, 41)], fill=(40, 28, 32, 255))
                d.polygon([(105, 72), (131, 80), (153, 94), (138, 102), (108, 88), (62, 105), (96, 79)], fill=(125, 246, 246, 255))
                d.line((108, 110, 76, 83), fill=(72, 141, 152, 255), width=11)
                d.line((148, 110, 184, 86), fill=(72, 141, 152, 255), width=11)
            else:  # Deployable amber wingsuit
                flutter = int(8 * __import__("math").sin(col / 6 * 6.283))
                d.polygon(
                    [(105, 93), (76, 92 + flutter), (35, 122 + flutter), (81, 137), (108, 126)],
                    fill=(120, 61, 53, 255),
                )
                d.polygon(
                    [(151, 92), (181, 90 - flutter), (221, 120 - flutter), (177, 139), (150, 126)],
                    fill=(120, 61, 53, 255),
                )
                d.polygon(
                    [(106, 98), (80, 99 + flutter), (52, 120 + flutter), (85, 127), (111, 121)],
                    fill=(235, 150, 83, 255),
                )
                d.polygon(
                    [(150, 98), (177, 97 - flutter), (204, 118 - flutter), (175, 129), (148, 121)],
                    fill=(235, 150, 83, 255),
                )
                d.line((83, 102 + flutter, 109, 112), fill=(255, 216, 157, 230), width=3)
                d.line((175, 101 - flutter, 149, 112), fill=(255, 216, 157, 230), width=3)
                d.polygon([(108, 91), (145, 87), (158, 133), (139, 151), (99, 138)], fill=(157, 79, 63, 255))
                d.polygon([(117, 97), (140, 94), (150, 127), (133, 138)], fill=(241, 161, 93, 255))
                d.line((122, 134, 111, 165), fill=(68, 47, 49, 255), width=13)
                d.line((111, 165, 94, 178), fill=(44, 33, 39, 255), width=11)
                d.line((143, 134, 155, 164), fill=(68, 47, 49, 255), width=13)
                d.line((155, 164, 177, 172), fill=(44, 33, 39, 255), width=11)
                d.polygon([(118, 40), (139, 31), (157, 42), (157, 60), (145, 73), (128, 67)], fill=(240, 189, 144, 255))
                d.polygon([(115, 49), (120, 33), (140, 25), (156, 35), (152, 45), (132, 42)], fill=(40, 28, 32, 255))
                d.line((106, 103, 79, 94 + flutter), fill=(92, 54, 51, 255), width=10)
                d.line((150, 103, 178, 94 - flutter), fill=(92, 54, 51, 255), width=10)

            # Fine tailoring: seam, patch, cuff and sunlit piping.
            d.line((137, 93, 145, 127), fill=(255, 201, 139, 190), width=2)
            d.polygon([(148, 115), (158, 113), (160, 125), (149, 127)], fill=(65, 48, 48, 200))
            d.line((106, 135, 117, 140), fill=(247, 185, 125, 160), width=2)
            sheet.alpha_composite(image, (col * cell, row * cell))
    sheet.save(CHAR / "echo_runner_sheet.png")


def ui_assets():
    # Textured plates are used as actual UI textures, not only CSS-like colors.
    for name, base, edge in (
        ("panel_frame.png", (43, 31, 45, 240), (235, 174, 117, 255)),
        ("button_gold.png", (222, 154, 94, 255), (255, 222, 169, 255)),
        ("button_dark.png", (62, 50, 64, 245), (197, 149, 116, 255)),
        ("hud_plate.png", (38, 31, 48, 220), (255, 195, 124, 245)),
    ):
        width, height = (512, 512) if name == "panel_frame.png" else (512, 128)
        im = Image.new("RGBA", (width, height), base)
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((2, 2, width - 3, height - 3), radius=30, outline=edge, width=4)
        d.line((30, 12, width - 30, 12), fill=(*edge[:3], 90), width=2)
        for _ in range(420):
            x, y = random.randrange(width), random.randrange(height)
            d.point((x, y), fill=(255, 222, 178, random.randrange(8, 34)))
        im.save(UI / name)


create_backdrops()
character_sheet()
ui_assets()
print("Generated character, environment, and UI artwork in", ASSETS)
