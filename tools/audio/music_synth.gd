class_name MusicSynth
## Dev-only (tools/, never exported): renders a MusicRecipes track into a seamless loop of 16-bit mono PCM.
## Voices: a pulse/triangle/saw lead and arpeggio, a triangle bass, a soft pad, and noise/sine drums. Notes
## are written into a circular buffer, so a tail that passes the loop's end wraps to its start and the
## loop has no seam. Chords are built from the scale (root, third and fifth by scale degree).

const RATE: int = 16000
const TARGET_RMS: float = 0.16
const PEAK: float = 0.85


static func render(recipe: Dictionary) -> PackedFloat32Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(recipe["seed"])
	var bpm: float = float(recipe["bpm"])
	var beat: float = 60.0 / bpm
	var bars: int = int(recipe["bars"])
	var length: int = roundi(bars * 4 * beat * RATE)
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(length)
	var scale: Array = MusicRecipes.SCALES[recipe["scale"]]
	var chords: Array = recipe["chords"]
	for bar: int in bars:
		var degree: int = int(chords[bar % chords.size()])
		var start: float = bar * 4 * beat
		_bass(buffer, recipe, scale, degree, start, beat)
		_arp(buffer, recipe, scale, degree, start, beat)
		_lead(buffer, recipe, scale, degree, start, beat, bar)
		if recipe.get("pad", false):
			_pad(buffer, recipe, scale, degree, start, beat)
		_drums(buffer, String(recipe.get("drums", "none")), start, beat, rng, bar)
	_echo(buffer, beat * 0.75, 0.22)
	return _normalize(buffer, float(recipe.get("level", 0.8)))


## The MIDI note of scale degree `degree` (may exceed 6: the next octave up) above the recipe's root.
static func note_of(recipe: Dictionary, scale: Array, degree: int) -> int:
	var octave: int = floori(float(degree) / scale.size())
	return int(recipe["root"]) + 12 * octave + int(scale[posmod(degree, scale.size())])


static func _chord(recipe: Dictionary, scale: Array, degree: int) -> Array[int]:
	return [note_of(recipe, scale, degree), note_of(recipe, scale, degree + 2), note_of(recipe, scale, degree + 4)]


static func _bass(buffer: PackedFloat32Array, recipe: Dictionary, scale: Array, degree: int, start: float, beat: float) -> void:
	var low: int = note_of(recipe, scale, degree) - 24
	match String(recipe["bass"]):
		"long":
			_note(buffer, "triangle", low, start, beat * 3.6, 0.5, 0.02)
		"root8":
			for i: int in 8:
				_note(buffer, "triangle", low + (12 if i % 4 == 3 else 0), start + i * beat * 0.5, beat * 0.45, 0.5, 0.01)
		"pulse":
			for i: int in 4:
				_note(buffer, "square", low + 12, start + i * beat, beat * 0.3, 0.2, 0.005, 0.25)
		"walk":
			var steps: Array[int] = [0, 2, 4, 2, 0, 4, 5, 4]
			for i: int in 8:
				var walk: int = note_of(recipe, scale, degree + steps[i] - (0 if i < 7 else 1)) - 24
				_note(buffer, "triangle", walk, start + i * beat * 0.5, beat * 0.45, 0.5, 0.01)


static func _arp(buffer: PackedFloat32Array, recipe: Dictionary, scale: Array, degree: int, start: float, beat: float) -> void:
	var style: String = String(recipe.get("arp", "none"))
	if style == "none":
		return
	var tones: Array[int] = _chord(recipe, scale, degree)
	var rate: int = int(recipe.get("arp_rate", 2))
	var count: int = 4 * rate
	for i: int in count:
		var index: int
		match style:
			"updown":
				index = [0, 1, 2, 1][i % 4]
			"broken":
				index = [0, 2, 1, 2][i % 4]
			_:
				index = i % 3
		var pitch: int = tones[index] + 12
		_note(buffer, "square", pitch, start + i * beat / rate, beat / rate * 0.8, 0.13, 0.004, 0.125)


static func _lead(buffer: PackedFloat32Array, recipe: Dictionary, scale: Array, degree: int, start: float, beat: float, bar: int) -> void:
	var style: String = String(recipe.get("lead", "none"))
	if style == "none":
		return
	var wave: String = String(recipe.get("lead_wave", "square"))
	var duty: float = float(recipe.get("lead_duty", 0.5))
	# The melody's phrases repeat every 4 bars (the seed fixes them), so the loop has a shape.
	var phrase: RandomNumberGenerator = RandomNumberGenerator.new()
	phrase.seed = int(recipe["seed"]) * 100 + bar % 4
	var rhythm: Array
	match style:
		"sparse":
			rhythm = [[0.0, 2.0], [2.0, 1.0], [3.0, 1.0]] if bar % 2 == 0 else [[0.0, 3.0]]
		"flowing":
			rhythm = [[0.0, 1.0], [1.0, 1.0], [2.0, 1.0], [3.0, 1.0]]
		_:
			rhythm = [[0.0, 0.5], [0.5, 0.5], [1.0, 0.5], [1.5, 0.5], [2.0, 1.0], [3.0, 0.5], [3.5, 0.5]]
	var at: int = phrase.randi_range(0, 2)
	for step: int in rhythm.size():
		var entry: Array = rhythm[step]
		# Chord tones on the beat, passing notes between: a walk through the scale.
		if float(entry[0]) == floorf(float(entry[0])):
			at = _nearest_tone(scale, degree, at + phrase.randi_range(-2, 2))
		else:
			at += phrase.randi_range(-1, 1)
		var pitch: int = note_of(recipe, scale, clampi(at, 0, 9)) + 12
		_note(buffer, wave, pitch, start + float(entry[0]) * beat, float(entry[1]) * beat * 0.92, 0.2, 0.01, duty)


## The scale degree near `wanted` that belongs to the chord on `degree` (its root, third or fifth).
static func _nearest_tone(scale: Array, degree: int, wanted: int) -> int:
	var best: int = degree
	var best_distance: int = 99
	for candidate: int in range(0, 10):
		var from_root: int = posmod(candidate - degree, scale.size())
		if from_root in [0, 2, 4] and absi(candidate - wanted) < best_distance:
			best = candidate
			best_distance = absi(candidate - wanted)
	return best


static func _pad(buffer: PackedFloat32Array, recipe: Dictionary, scale: Array, degree: int, start: float, beat: float) -> void:
	for tone: int in _chord(recipe, scale, degree):
		_note(buffer, "triangle", tone, start, beat * 4.0, 0.1, 0.4)


static func _drums(buffer: PackedFloat32Array, style: String, start: float, beat: float, rng: RandomNumberGenerator, bar: int) -> void:
	if style == "none":
		return
	for i: int in 4:
		var at: float = start + i * beat
		match style:
			"soft":
				_hat(buffer, at + beat * 0.5, 0.05, rng)
				if i == 0:
					_kick(buffer, at, 0.35)
			"drive", "boss":
				_kick(buffer, at, 0.6)
				if style == "boss":
					_kick(buffer, at + beat * 0.75, 0.4)
				if i % 2 == 1:
					_snare(buffer, at, rng)
				_hat(buffer, at, 0.07, rng)
				_hat(buffer, at + beat * 0.5, 0.05, rng)
	if style == "boss" and bar % 4 == 3:
		for i: int in 4:
			_snare(buffer, start + (3.0 + i * 0.25) * beat, rng)


static func _kick(buffer: PackedFloat32Array, at: float, volume: float) -> void:
	var count: int = roundi(0.16 * RATE)
	for i: int in count:
		var t: float = float(i) / RATE
		var freq: float = 50.0 + 110.0 * exp(-t * 28.0)
		_add(buffer, at, i, sin(TAU * freq * t) * exp(-t * 18.0) * volume)


static func _snare(buffer: PackedFloat32Array, at: float, rng: RandomNumberGenerator) -> void:
	var count: int = roundi(0.14 * RATE)
	for i: int in count:
		var t: float = float(i) / RATE
		_add(buffer, at, i, (rng.randf_range(-1.0, 1.0) * 0.6 + sin(TAU * 190.0 * t) * 0.3) * exp(-t * 26.0) * 0.45)


static func _hat(buffer: PackedFloat32Array, at: float, volume: float, rng: RandomNumberGenerator) -> void:
	var count: int = roundi(0.04 * RATE)
	var previous: float = 0.0
	for i: int in count:
		var t: float = float(i) / RATE
		var white: float = rng.randf_range(-1.0, 1.0)
		_add(buffer, at, i, (white - previous) * 0.5 * exp(-t * 90.0) * volume)  # first difference: a high-passed noise
		previous = white


## One pitched note: `wave` at MIDI `pitch` from `start` s for `length` s, with a short attack and a release.
static func _note(buffer: PackedFloat32Array, wave: String, pitch: int, start: float, length: float, volume: float, attack: float, duty: float = 0.5) -> void:
	var freq: float = 440.0 * pow(2.0, (pitch - 69) / 12.0)
	var release: float = minf(0.12, length * 0.5)
	var count: int = roundi((length + release) * RATE)
	var phase: float = 0.0
	for i: int in count:
		var t: float = float(i) / RATE
		var envelope: float = minf(t / maxf(attack, 0.003), 1.0)
		if t > length:
			envelope *= maxf(0.0, 1.0 - (t - length) / release)
		phase += freq / RATE
		phase -= floorf(phase)
		var x: float
		match wave:
			"square":
				x = 1.0 if phase < duty else -1.0
			"saw":
				x = 2.0 * phase - 1.0
			_:
				x = 1.0 - 4.0 * absf(phase - 0.5)
		_add(buffer, start, i, x * envelope * volume)


static func _add(buffer: PackedFloat32Array, start: float, offset: int, value: float) -> void:
	var index: int = (roundi(start * RATE) + offset) % buffer.size()
	buffer[index] += value


## A feedback echo `delay` s long, wrapping around the loop (so the seam stays seamless).
static func _echo(buffer: PackedFloat32Array, delay: float, feedback: float) -> void:
	var shift: int = roundi(delay * RATE)
	var copy: PackedFloat32Array = buffer.duplicate()
	for i: int in buffer.size():
		buffer[i] += copy[posmod(i - shift, buffer.size())] * feedback + copy[posmod(i - shift * 2, buffer.size())] * feedback * 0.5


static func _normalize(buffer: PackedFloat32Array, level: float) -> PackedFloat32Array:
	var sum: float = 0.0
	var top: float = 0.0
	for s: float in buffer:
		sum += s * s
		top = maxf(top, absf(s))
	var rms: float = sqrt(sum / buffer.size())
	var gain: float = minf(TARGET_RMS * level / maxf(rms, 0.0001), PEAK / maxf(top, 0.0001))
	var out: PackedFloat32Array = buffer.duplicate()
	for i: int in out.size():
		out[i] *= gain
	return out


## `samples` as a looping 16-bit mono stream.
static func to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i: int in samples.size():
		bytes.encode_s16(i * 2, clampi(roundi(samples[i] * 32767.0), -32768, 32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples.size()
	return stream
