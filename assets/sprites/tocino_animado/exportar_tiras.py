"""Empaqueta los atlas generados en tiras horizontales para Godot.

El arte se genera fuera de este script. Aquí solo se separan los cuadros,
se conserva el canal alfa y se igualan los lienzos para la importación.
"""

from __future__ import annotations

import json
from pathlib import Path
from statistics import median

from PIL import Image


ROOT = Path(__file__).resolve().parent
ATLAS = ROOT / "atlases"
OUT = ROOT / "tiras"
FRAME_SIZE = 320
CAN_FRAME_SIZE = 160
DIRECTIONS = ("down", "up", "left", "right")

# Los límites caen dentro de los canales transparentes reales de cada atlas.
BOUNDS = {
    "walk": ([0, 324, 626, 938, 1254], [0, 318, 611, 909, 1254]),
    "run": ([0, 376, 722, 1064, 1402], [0, 278, 555, 824, 1122]),
    "idle": ([0, 512, 1024], [0, 374, 740, 1121, 1536]),
    "pickup": ([0, 360, 669, 980, 1278], [0, 339, 628, 910, 1230]),
    "throw": ([0, 319, 627, 1015, 1278], [0, 320, 608, 891, 1230]),
    "throw_front": ([0, 543, 1086, 1629, 2172], [0, 724]),
    "pickup_side": ([0, 494, 905, 1335, 1774], [0, 448, 887]),
    "throw_side": ([0, 414, 847, 1344, 1774], [0, 445, 887]),
    "jump": ([0, 331, 651, 962, 1278], [0, 335, 625, 911, 1230]),
    "dodge": ([0, 319, 646, 1005, 1278], [0, 337, 628, 918, 1230]),
    "hurt": ([0, 308, 638, 962, 1263], [0, 321, 609, 909, 1246]),
    "hide": ([0, 338, 656, 973, 1287], [0, 321, 598, 883, 1222]),
    "victory_defeat": ([0, 453, 866, 1294, 1774], [0, 460, 887]),
    "can": ([0, 531, 1086, 1631, 2172], [0, 724]),
    "hold_walk": ([0, 347, 654, 958, 1284], [0, 304, 603, 900, 1225]),
    "hold_idle": ([0, 512, 1024], [0, 376, 751, 1132, 1536]),
}

# Fuente, fila y espejo horizontal. El arte lateral de recoger y lanzar
# proviene de atlas aparte para que el perfil sea legible.
MAP = {
    "idle": [("idle", 0, False), ("idle", 1, False), ("idle", 2, False), ("idle", 3, False)],
    "walk": [("walk", 0, False), ("walk", 1, False), ("walk", 2, False), ("walk", 3, False)],
    "run": [("run", 0, False), ("run", 1, False), ("run", 2, False), ("run", 3, False)],
    "jump": [("jump", 0, False), ("jump", 1, False), ("jump", 2, True), ("jump", 2, False)],
    "dodge": [("dodge", 0, False), ("dodge", 1, False), ("dodge", 3, True), ("dodge", 3, False)],
    "pickup": [("pickup", 0, False), ("pickup", 1, False), ("pickup_side", 0, False), ("pickup_side", 1, False)],
    "throw": [("throw_front", 0, False), ("throw", 1, False), ("throw_side", 1, True), ("throw_side", 1, False)],
    "hurt": [("hurt", 0, False), ("hurt", 1, False), ("hurt", 2, False), ("hurt", 3, False)],
    "hide": [("hide", 0, False), ("hide", 1, False), ("hide", 2, False), ("hide", 3, False)],
    "hold_idle": [("hold_idle", 0, False), ("hold_idle", 1, False), ("hold_idle", 3, False), ("hold_idle", 2, False)],
    "hold_walk": [("hold_walk", 0, False), ("hold_walk", 1, False), ("hold_walk", 2, False), ("hold_walk", 3, False)],
    "hold_run": [("hold_walk", 0, False), ("hold_walk", 1, False), ("hold_walk", 2, False), ("hold_walk", 3, False)],
}

FPS = {
    "idle": 3,
    "walk": 8,
    "run": 12,
    "jump": 10,
    "dodge": 14,
    "pickup": 10,
    "throw": 12,
    "hurt": 10,
    "hide": 9,
    "hold_idle": 3,
    "hold_walk": 8,
    "hold_run": 12,
    "victory": 8,
    "defeat": 8,
    "can_spin": 12,
}
LOOPING = {"idle", "walk", "run", "hold_idle", "hold_walk", "hold_run", "can_spin"}


def cell(name: str, row: int, col: int) -> Image.Image:
    image = IMAGES[name]
    xs, ys = BOUNDS[name]
    return image.crop((xs[col], ys[row], xs[col + 1], ys[row + 1]))


def art_box(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A").point(lambda value: 255 if value > 12 else 0)
    box = alpha.getbbox()
    if box is None:
        raise ValueError("Cuadro vacío en atlas")
    return box


def body_box(image: Image.Image) -> tuple[int, int, int, int]:
    # El rojo del tocino da un ancla horizontal estable, incluso si la lata
    # se desplaza a un lado durante el lanzamiento.
    rgba = image.convert("RGBA")
    red = Image.new("L", rgba.size, 0)
    src = rgba.load()
    dst = red.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = src[x, y]
            if a > 80 and r > 95 and r > g * 1.22 and r > b * 1.2:
                dst[x, y] = 255
    return red.getbbox() or art_box(image)


def make_strip(frames: list[Image.Image], output: Path, *, projectile: bool = False) -> None:
    size = CAN_FRAME_SIZE if projectile else FRAME_SIZE
    boxes = [art_box(frame) for frame in frames]
    body_boxes = [art_box(frame) if projectile else body_box(frame) for frame in frames]
    if projectile:
        max_w = max(box[2] - box[0] for box in boxes)
        max_h = max(box[3] - box[1] for box in boxes)
        scale = min(128 / max_w, 128 / max_h)
    else:
        body_heights = [box[3] - box[1] for box in body_boxes]
        max_side = max(
            max((body[0] + body[2]) / 2 - box[0], box[2] - (body[0] + body[2]) / 2)
            for body, box in zip(body_boxes, boxes)
        )
        max_h = max(box[3] - box[1] for box in boxes)
        scale = min(230 / median(body_heights), 144 / max_side, 282 / max_h)

    strip = Image.new("RGBA", (size * len(frames), size), (0, 0, 0, 0))
    for index, (frame, box, body) in enumerate(zip(frames, boxes, body_boxes)):
        width = max(1, round(frame.width * scale))
        height = max(1, round(frame.height * scale))
        scaled = frame.resize((width, height), Image.Resampling.LANCZOS)
        if projectile:
            cx = (box[0] + box[2]) * scale / 2
            cy = (box[1] + box[3]) * scale / 2
            x = round(size / 2 - cx)
            y = round(size / 2 - cy)
        else:
            body_cx = (body[0] + body[2]) * scale / 2
            x = round(size / 2 - body_cx)
            y = round(size - 20 - box[3] * scale)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        canvas.paste(scaled, (x, y))
        if canvas.getchannel("A").getbbox() is None:
            raise ValueError(f"Cuadro vacío al exportar: {output.name} {index}")
        strip.paste(canvas, (index * size, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    strip.save(output)


def main() -> None:
    global IMAGES
    IMAGES = {name: Image.open(ATLAS / f"{name}.png").convert("RGBA") for name in BOUNDS}
    manifest = {"frame_size": FRAME_SIZE, "directions": DIRECTIONS, "animations": {}}
    for animation, mapping in MAP.items():
        for direction, (source, row, mirror) in zip(DIRECTIONS, mapping):
            frames = [cell(source, row, col) for col in range(len(BOUNDS[source][0]) - 1)]
            if mirror:
                frames = [frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in frames]
            name = f"{animation}_{direction}"
            output = OUT / f"{name}.png"
            make_strip(frames, output)
            manifest["animations"][name] = {
                "file": f"tiras/{name}.png",
                "frames": len(frames),
                "fps": FPS[animation],
                "loop": animation in LOOPING,
            }

    for animation, row in (("victory", 0), ("defeat", 1)):
        frames = [cell("victory_defeat", row, col) for col in range(4)]
        make_strip(frames, OUT / f"{animation}.png")
        manifest["animations"][animation] = {
            "file": f"tiras/{animation}.png",
            "frames": 4,
            "fps": FPS[animation],
            "loop": False,
        }

    can_frames = [cell("can", 0, col) for col in range(4)]
    make_strip(can_frames, OUT / "can_spin.png", projectile=True)
    manifest["animations"]["can_spin"] = {
        "file": "tiras/can_spin.png",
        "frames": 4,
        "frame_size": CAN_FRAME_SIZE,
        "fps": FPS["can_spin"],
        "loop": True,
    }
    (ROOT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Exportadas {len(manifest['animations'])} tiras en {OUT}")


if __name__ == "__main__":
    main()
