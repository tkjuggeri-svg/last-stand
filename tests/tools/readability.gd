class_name Readability
## The grayscale readability check (M8.5, ART_DIRECTION 14): how much a sprite stands out from a
## ground by brightness alone (no colour), as a contrast ratio of relative luminances, like WCAG's:
## (lighter + 0.05) / (darker + 0.05). A sprite is measured on its opaque pixels without the dark
## outline (its body); a ground on all of it.

const OUTLINE: Color = Color("1a141f")


## Relative luminance (linear sRGB, Rec. 709 weights).
static func luminance(c: Color) -> float:
	var lin: Color = c.srgb_to_linear()
	return 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b


## The mean luminance of `image`'s opaque, non-outline pixels (every `step`-th pixel, for speed).
static func body_luminance(image: Image, step: int = 1) -> float:
	var total: float = 0.0
	var count: int = 0
	for y: int in range(0, image.get_height(), step):
		for x: int in range(0, image.get_width(), step):
			var c: Color = image.get_pixel(x, y)
			if c.a > 0.9 and not Color(c.r, c.g, c.b).is_equal_approx(OUTLINE):
				total += luminance(c)
				count += 1
	return total / maxi(count, 1)


static func contrast(a: float, b: float) -> float:
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)
