class_name Grayscale
## Screenshot helper (M8.5 readability check): a grayscale copy of an image by perceived luminance
## (Rec. 709), so what stands out only by its colour shows up.


static func convert(image: Image) -> Image:
	var gray: Image = image.duplicate() as Image
	gray.convert(Image.FORMAT_RGB8)
	for y: int in gray.get_height():
		for x: int in gray.get_width():
			var c: Color = gray.get_pixel(x, y)
			var l: float = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			gray.set_pixel(x, y, Color(l, l, l))
	return gray
