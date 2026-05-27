from collections import deque
from pathlib import Path
import sys
from PIL import Image


SOURCE = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("Resources/AppIconSource.png")
DESTINATION = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("Resources/AppIconSource.png")


def is_external_background(pixel):
    red, green, blue, alpha = pixel
    if alpha == 0:
        return True

    # The source has an off-white page/background and a faint gray shadow.
    # The white lock is enclosed by blue pixels, so a border flood-fill removes
    # only exterior background pixels while keeping the lock untouched.
    return red >= 210 and green >= 210 and blue >= 210


image = Image.open(SOURCE).convert("RGBA")
width, height = image.size
pixels = image.load()
visited = bytearray(width * height)
queue = deque()


def enqueue(x, y):
    index = y * width + x
    if visited[index]:
        return
    if not is_external_background(pixels[x, y]):
        return
    visited[index] = 1
    queue.append((x, y))


for x in range(width):
    enqueue(x, 0)
    enqueue(x, height - 1)
for y in range(height):
    enqueue(0, y)
    enqueue(width - 1, y)

while queue:
    x, y = queue.popleft()
    if x > 0:
        enqueue(x - 1, y)
    if x < width - 1:
        enqueue(x + 1, y)
    if y > 0:
        enqueue(x, y - 1)
    if y < height - 1:
        enqueue(x, y + 1)

output = image.copy()
out_pixels = output.load()
for y in range(height):
    for x in range(width):
        if visited[y * width + x]:
            red, green, blue, alpha = out_pixels[x, y]
            out_pixels[x, y] = (red, green, blue, 0)

bbox = output.getbbox()
if bbox is None:
    raise SystemExit("No icon content found after background removal.")

output = output.crop(bbox)

# Center the cropped rounded square on a transparent square canvas with a little
# breathing room, so the icon does not look chopped off in the Dock/header.
side = int(max(output.size) * 1.12)
canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
canvas.alpha_composite(output, ((side - output.width) // 2, (side - output.height) // 2))

DESTINATION.parent.mkdir(parents=True, exist_ok=True)
canvas.save(DESTINATION)
