class_name SfxSynth
## Dev-only (tools/, never exported): an sfxr-style synthesizer that renders the game's retro sound
## effects from a recipe (SfxRecipes) into 16-bit mono PCM. A sound is one or more layers mixed
## together, each a simple oscillator with an envelope:
##   wave: "square" | "saw" | "triangle" | "sine" | "noise"
##   freq, freq_end (Hz; an exponential slide between them over the layer), delay (s before it starts)
##   attack, sustain, decay (s), punch (extra level at the start of the sustain, 0..1)
##   duty, duty_end (square: pulse width 0..1), vibrato (depth, share of the pitch), vibrato_speed (Hz)
##   arp (a pitch ratio from arp_time on: the classic sfxr jump), arp_time (s)
##   lowpass, lowpass_end (one-pole cutoff 0..1, 1 = open), highpass (0..1, 0 = off)
##   volume (the layer's share of the mix), crush (bits to keep, 0 = all: the 8-bit grit)
## The noise is seeded (SfxRecipes gives each sound its seed), so a regenerated sound is the same.

const RATE: int = 22050
## Every layer fades in over at least this long (s), so no sound starts with a click.
const MIN_ATTACK: float = 0.003
## The DC blocker's pole: removes the offset an uneven pulse wave leaves (about 20 Hz).
const DC_POLE: float = 0.995


## The layers of a recipe mixed into one buffer of samples (-1..1), not normalised yet.
static func render(layers: Array, seed_value: int) -> PackedFloat32Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var mix: PackedFloat32Array = PackedFloat32Array()
	for layer: Dictionary in layers:
		var samples: PackedFloat32Array = _layer(layer, rng)
		var offset: int = roundi(float(layer.get("delay", 0.0)) * RATE)
		if mix.size() < offset + samples.size():
			mix.resize(offset + samples.size())
		for i: int in samples.size():
			mix[offset + i] += samples[i]
	return _block_dc(mix)


## Scales `samples` to `target_rms` (so every sound starts equally loud), never past `peak`.
static func normalize(samples: PackedFloat32Array, target_rms: float, peak: float) -> PackedFloat32Array:
	var sum: float = 0.0
	var top: float = 0.0
	for s: float in samples:
		sum += s * s
		top = maxf(top, absf(s))
	if top <= 0.0:
		return samples
	var rms: float = sqrt(sum / samples.size())
	var gain: float = minf(target_rms / maxf(rms, 0.0001), peak / top)
	var out: PackedFloat32Array = samples.duplicate()
	for i: int in out.size():
		out[i] *= gain
	return out


## `samples` as a 16-bit mono WAV stream (save_to_wav writes it).
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
	return stream


static func _layer(p: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var attack: float = maxf(p.get("attack", 0.0), MIN_ATTACK)
	var sustain: float = p.get("sustain", 0.1)
	var decay: float = p.get("decay", 0.2)
	var length: float = attack + sustain + decay
	var count: int = maxi(1, roundi(length * RATE))
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(count)
	var wave: String = p.get("wave", "square")
	var f0: float = p.get("freq", 440.0)
	var f1: float = p.get("freq_end", f0)
	var duty0: float = p.get("duty", 0.5)
	var duty1: float = p.get("duty_end", duty0)
	var lp0: float = p.get("lowpass", 1.0)
	var lp1: float = p.get("lowpass_end", lp0)
	var hp: float = p.get("highpass", 0.0)
	var punch: float = p.get("punch", 0.0)
	var volume: float = p.get("volume", 1.0)
	var crush: int = p.get("crush", 0)
	var phase: float = 0.0
	var noise_value: float = rng.randf_range(-1.0, 1.0)
	var low: float = 0.0
	var high_prev_in: float = 0.0
	var high: float = 0.0
	for i: int in count:
		var t: float = float(i) / RATE
		var u: float = t / length
		var freq: float = f0 * pow(f1 / f0, u) if f0 > 0.0 and f1 > 0.0 else lerpf(f0, f1, u)
		if p.has("arp") and t >= float(p.get("arp_time", 0.05)):
			freq *= float(p["arp"])
		if p.has("vibrato"):
			freq *= 1.0 + float(p["vibrato"]) * sin(TAU * float(p.get("vibrato_speed", 8.0)) * t)
		phase += freq / RATE
		if phase >= 1.0:
			phase -= floorf(phase)
			noise_value = rng.randf_range(-1.0, 1.0)
		var x: float = _wave(wave, phase, lerpf(duty0, duty1, u), noise_value)
		var cutoff: float = clampf(lerpf(lp0, lp1, u), 0.001, 1.0)
		low += cutoff * cutoff * (x - low)
		x = low
		if hp > 0.0:
			high = (1.0 - hp) * (high + x - high_prev_in)
			high_prev_in = x
			x = high
		if crush > 0:
			var steps: float = pow(2.0, crush - 1)
			x = roundf(x * steps) / steps
		out[i] = x * _envelope(t, attack, sustain, decay, punch) * volume
	return out


## A one-pole high-pass at a few Hz: the mix's average back to 0.
static func _block_dc(samples: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = samples.duplicate()
	var previous_in: float = 0.0
	var previous_out: float = 0.0
	for i: int in out.size():
		var y: float = samples[i] - previous_in + DC_POLE * previous_out
		previous_in = samples[i]
		previous_out = y
		out[i] = y
	return out


static func _wave(wave: String, phase: float, duty: float, noise_value: float) -> float:
	match wave:
		"square":
			return 1.0 if phase < duty else -1.0
		"saw":
			return 2.0 * phase - 1.0
		"triangle":
			return 1.0 - 4.0 * absf(phase - 0.5)
		"sine":
			return sin(TAU * phase)
		"noise":
			return noise_value
	return 0.0


static func _envelope(t: float, attack: float, sustain: float, decay: float, punch: float) -> float:
	if t < attack:
		return t / attack
	t -= attack
	if t < sustain:
		return 1.0 + punch * (1.0 - t / sustain)
	t -= sustain
	if t < decay:
		var left: float = 1.0 - t / decay
		return left * left
	return 0.0
