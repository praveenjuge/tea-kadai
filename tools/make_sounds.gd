extends SceneTree
## Makes the placeholder sound effects, ambience and music as WAV files in
## assets/sounds, all synthesized here. Any file can later be replaced by a
## real recording with the same name; the game just loads the files.
## Run: godot --headless --path . -s tools/make_sounds.gd
## Then: godot --headless --path . --import

const RATE := 22050
const OUT := "res://assets/sounds"
## Mohanam, a five-note scale: Sa Ri Ga Pa Dha, then the octave above.
const SCALE := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 7
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("fill", _fill())
	_save("perfect", _perfect())
	_save("good", _good())
	_save("flat", _flat())
	_save("spill", _spill())
	_save("pour_loop", _pour_loop())
	_save("sizzle_loop", _sizzle_loop())
	_save("golden", _golden())
	_save("lift", _lift())
	_save("burnt", _burnt())
	_save("coin", _coin())
	_save("arrive", _arrive())
	_save("grumble", _grumble())
	_save("crow", _crow())
	_save("horn", _horn())
	_save("bell", _bell())
	_save("street_loop", _street_loop())
	_save("rain_loop", _rain_loop())
	_save("rush_loop", _rush_loop())
	_save("clink", _clink())
	_save("shutter", _shutter())
	_save("temple_bell", _temple_bell())
	_save("murmur_loop", _murmur_loop())
	_save("pop", _pop())
	_save("splash", _splash())
	_save("music_day", _music(
		[0, 2, 4, -1, 5, 4, 2, -1, 1, 2, 4, 2, 0, -1, -1, -1,
		 2, 4, 5, 7, 5, 4, 2, -1, 4, 2, 1, 0, -1, -1, 0, -1], 0.6, 261.63, 0.0))
	_save("music_night", _music(
		[0, -1, 2, -1, 4, -1, -1, -1, 3, -1, 2, -1, 0, -1, -1, -1,
		 2, -1, 4, 5, 4, -1, 2, -1], 0.8, 130.81, 0.55))
	quit()


# --- Sounds -----------------------------------------------------------------

func _fill() -> PackedFloat32Array:
	var b := _buf(0.45)
	for i in 3:
		_tone(b, i * 0.12, 0.1, 260.0 + i * 30.0, 430.0 + i * 30.0, 1.0, 30.0)
	_noise(b, 0.0, 0.4, 0.08, 6.0, 0.7)
	return b


func _perfect() -> PackedFloat32Array:
	var b := _buf(0.9)
	_tone(b, 0.0, 0.9, 880.0, 880.0, 1.0, 5.0)
	_tone(b, 0.0, 0.9, 1760.0, 1760.0, 0.25, 8.0)
	_tone(b, 0.08, 0.8, 1318.5, 1318.5, 0.7, 5.0)
	return b


func _good() -> PackedFloat32Array:
	var b := _buf(0.4)
	_tone(b, 0.0, 0.4, 659.3, 659.3, 1.0, 10.0)
	_tone(b, 0.0, 0.4, 988.0, 988.0, 0.3, 12.0)
	return b


func _flat() -> PackedFloat32Array:
	var b := _buf(0.35)
	_tone(b, 0.0, 0.35, 330.0, 290.0, 1.0, 12.0)
	return b


func _spill() -> PackedFloat32Array:
	var b := _buf(0.6)
	_noise(b, 0.0, 0.6, 1.0, 9.0, 0.6)
	_tone(b, 0.0, 0.3, 90.0, 60.0, 0.6, 15.0)
	return b


## A steady trickle with little bubbles, for as long as the pour is held.
func _pour_loop() -> PackedFloat32Array:
	var b := _buf(1.2)
	_noise(b, 0.0, 1.2, 0.45, 0.0, 0.5)
	for i in 28:
		var at := rng.randf_range(0.0, 1.15)
		var f := rng.randf_range(700.0, 1400.0)
		_tone(b, at, 0.04, f, f * 1.3, 0.35, 60.0)
	return b


## Hiss plus random crackles of hot oil.
func _sizzle_loop() -> PackedFloat32Array:
	var b := _buf(2.0)
	var low := 0.0
	for i in b.size():
		var white := rng.randf_range(-1.0, 1.0)
		low += (white - low) * 0.3
		b[i] += (white - low) * 0.25
	for i in 140:
		_noise(b, rng.randf_range(0.0, 1.99), 0.004, rng.randf_range(0.3, 0.9), 0.0, 0.1)
	return b


func _golden() -> PackedFloat32Array:
	var b := _buf(0.8)
	_tone(b, 0.0, 0.5, 784.0, 784.0, 1.0, 6.0)
	_tone(b, 0.14, 0.66, 1046.5, 1046.5, 1.0, 5.0)
	return b


func _lift() -> PackedFloat32Array:
	var b := _buf(0.3)
	_tone(b, 0.0, 0.3, 1800.0, 1800.0, 0.6, 25.0)
	_tone(b, 0.0, 0.3, 2700.0, 2700.0, 0.4, 30.0)
	_noise(b, 0.0, 0.02, 0.5, 0.0, 0.3)
	return b


func _burnt() -> PackedFloat32Array:
	var b := _buf(0.6)
	_tone(b, 0.0, 0.6, 150.0, 90.0, 0.5, 4.0, true)
	_smooth(b, 0.6)
	return b


func _coin() -> PackedFloat32Array:
	var b := _buf(0.45)
	_tone(b, 0.0, 0.08, 1568.0, 1568.0, 0.5, 10.0, true)
	_tone(b, 0.08, 0.37, 2093.0, 2093.0, 0.5, 7.0, true)
	_smooth(b, 0.35)
	return b


func _arrive() -> PackedFloat32Array:
	var b := _buf(0.15)
	_tone(b, 0.0, 0.15, 520.0, 340.0, 1.0, 25.0)
	return b


func _grumble() -> PackedFloat32Array:
	var b := _buf(0.45)
	_tone(b, 0.0, 0.45, 170.0, 120.0, 0.7, 5.0)
	_tone(b, 0.0, 0.45, 170.0, 120.0, 0.2, 5.0, true)
	_smooth(b, 0.7)
	return b


func _crow() -> PackedFloat32Array:
	var b := _buf(0.7)
	for start in [0.0, 0.3]:
		var n := int(0.22 * RATE)
		var phase := 0.0
		for i in n:
			var x := float(i) / n
			var t := float(i) / RATE
			var f := lerpf(640.0, 520.0, x) + sin(t * 60.0) * 30.0
			phase += TAU * f / RATE
			var v := 0.0
			for h in range(1, 6):
				v += sin(phase * h) / h
			v += rng.randf_range(-0.3, 0.3)
			b[int(start * RATE) + i] += v * sqrt(sin(PI * x)) * 0.6
	_smooth(b, 0.4)
	return b


## An auto rickshaw's two-tone "pom-pom".
func _horn() -> PackedFloat32Array:
	var b := _buf(0.55)
	for start in [0.0, 0.22]:
		_tone(b, start, 0.16, 415.0, 415.0, 0.35, 3.0, true)
		_tone(b, start, 0.16, 523.0, 523.0, 0.35, 3.0, true)
	_smooth(b, 0.5)
	return b


func _bell() -> PackedFloat32Array:
	var b := _buf(0.9)
	for start in [0.0, 0.18]:
		_tone(b, start, 0.7, 2350.0, 2350.0, 0.6, 6.0)
		_tone(b, start, 0.7, 3520.0, 3520.0, 0.3, 8.0)
		_tone(b, start, 0.7, 4700.0, 4700.0, 0.12, 10.0)
	return b


## Two steel tumblers touching: bright, short and a little uneven.
func _clink() -> PackedFloat32Array:
	var b := _buf(0.35)
	for hit in [[0.0, 1.0], [0.045, 0.5]]:
		_tone(b, hit[0], 0.3, 2630.0, 2610.0, hit[1], 22.0)
		_tone(b, hit[0], 0.3, 3910.0, 3890.0, hit[1] * 0.6, 28.0)
		_tone(b, hit[0], 0.3, 5470.0, 5470.0, hit[1] * 0.3, 35.0)
		_noise(b, hit[0], 0.01, hit[1] * 0.4, 0.0, 0.1)
	return b


## A rolling shutter: fast metal rattles that slow down, then a thud.
func _shutter() -> PackedFloat32Array:
	var b := _buf(0.9)
	var t := 0.0
	var gap := 0.018
	while t < 0.7:
		var f := rng.randf_range(900.0, 1400.0)
		_noise(b, t, 0.015, 0.5, 120.0, 0.3)
		_tone(b, t, 0.03, f, f * 0.95, 0.15, 90.0)
		t += gap
		gap *= 1.03
	_tone(b, 0.72, 0.18, 120.0, 70.0, 1.0, 22.0)
	_noise(b, 0.72, 0.1, 0.6, 40.0, 0.8)
	return b


## A temple bell far down the street at dawn: low, long and shimmering.
func _temple_bell() -> PackedFloat32Array:
	var b := _buf(3.0)
	for hit in [0.0, 1.2]:
		for partial in [[1.0, 1.0], [2.0, 0.5], [2.76, 0.35], [5.4, 0.15], [8.9, 0.06]]:
			var f: float = 392.0 * partial[0]
			_tone(b, hit, 3.0 - hit, f, f * 0.998, partial[1], 1.4 + partial[0] * 0.3)
	_smooth(b, 0.3)
	return b


## Many people talking at once: soft vowel-ish blips over a low murmur.
func _murmur_loop() -> PackedFloat32Array:
	var length := 4.0
	var b := _buf(length)
	var low := 0.0
	for i in b.size():
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.05
		b[i] = low * 0.6
	for i in 140:
		var at := rng.randf_range(0.0, length - 0.3)
		var f := rng.randf_range(160.0, 320.0)
		_tone(b, at, rng.randf_range(0.12, 0.28), f, f * rng.randf_range(0.85, 1.15), rng.randf_range(0.05, 0.12), 6.0)
	_smooth(b, 0.6)
	return b


## A speech bubble popping up.
func _pop() -> PackedFloat32Array:
	var b := _buf(0.12)
	_tone(b, 0.0, 0.1, 420.0, 900.0, 1.0, 30.0)
	return b


## Batter hitting hot oil.
func _splash() -> PackedFloat32Array:
	var b := _buf(0.6)
	_noise(b, 0.0, 0.6, 1.0, 7.0, 0.2)
	for i in 30:
		var at := rng.randf_range(0.0, 0.4)
		_tone(b, at, 0.02, 3000.0, 1800.0, 0.3, 150.0)
	return b


## Low traffic rumble. Made a second longer and cross-faded so it loops smoothly.
func _street_loop() -> PackedFloat32Array:
	var length := int(6.0 * RATE)
	var overlap := int(1.0 * RATE)
	var raw := PackedFloat32Array()
	raw.resize(length + overlap)
	var brown := 0.0
	var low := 0.0
	for i in raw.size():
		brown = clampf(brown * 0.995 + rng.randf_range(-1.0, 1.0) * 0.05, -1.0, 1.0)
		low += (brown - low) * 0.08
		raw[i] = low
	var b := _buf(6.0)
	for i in length:
		var v := raw[i]
		if i < overlap:
			var mix := float(i) / overlap
			v = raw[i] * mix + raw[length + i] * (1.0 - mix)
		b[i] = v * (0.8 + 0.2 * sin(TAU * float(i) / length))
	return b


## Steady rain on a tin awning: soft hiss plus lots of tiny drops.
func _rain_loop() -> PackedFloat32Array:
	var length := int(4.0 * RATE)
	var b := _buf(4.0)
	var low := 0.0
	for i in length:
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.35
		b[i] = low * 0.35
	for i in 900:
		var at := rng.randf_range(0.0, 3.98)
		var f := rng.randf_range(2500.0, 5000.0)
		_tone(b, at, 0.012, f, f * 0.8, rng.randf_range(0.05, 0.2), 200.0)
	return b


## A light mridangam-style beat for the rushes, at the day music's tempo.
func _rush_loop() -> PackedFloat32Array:
	var beat := 0.3
	var pattern := [1, 0, 2, 0, 1, 2, 2, 0, 1, 0, 2, 0, 1, 2, 0, 2]
	var b := _buf(pattern.size() * beat)
	for i in pattern.size():
		match pattern[i]:
			1:
				_tone(b, i * beat, 0.25, 110.0, 70.0, 1.0, 14.0)
				_noise(b, i * beat, 0.02, 0.3, 0.0, 0.5)
			2:
				_tone(b, i * beat, 0.08, 520.0, 480.0, 0.5, 40.0)
				_noise(b, i * beat, 0.03, 0.4, 60.0, 0.1)
	return b


## A tanpura drone plus a plucked melody, written so the loop wraps cleanly.
## "notes" are SCALE indexes per beat, -1 for a rest.
func _music(notes: Array, beat: float, tonic: float, darkness: float) -> PackedFloat32Array:
	var length := notes.size() * beat
	var b := _buf(length)
	var drone := [tonic * 0.75, tonic, tonic, tonic * 0.5]
	var step := beat * 1.5
	var t := 0.0
	var i := 0
	while t < length - 0.01:
		_pluck(b, t, drone[i % drone.size()], 0.35, 0.9985)
		t += step
		i += 1
	for n in notes.size():
		var degree: int = notes[n]
		if degree >= 0:
			var freq := tonic * pow(2.0, SCALE[degree] / 12.0)
			_pluck(b, n * beat, freq, 0.6, 0.996)
	if darkness > 0.0:
		_smooth(b, darkness)
	return b


# --- Building blocks --------------------------------------------------------

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


## A sine (or square) note sliding from f0 to f1, with a fast attack and an
## exponential decay ("decay" per second; 0 keeps it steady).
func _tone(b: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, amp: float,
		decay: float, square: bool = false) -> void:
	var first := int(start * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	for i in n:
		var k := first + i
		if k >= b.size():
			break
		var t := float(i) / RATE
		phase += TAU * lerpf(f0, f1, float(i) / n) / RATE
		var v := sin(phase)
		if square:
			v = 0.5 if v >= 0.0 else -0.5
		var env := exp(-t * decay) * minf(1.0, t * 400.0) * minf(1.0, float(n - i) / 40.0)
		b[k] += v * amp * env


## Filtered noise. "smooth" from 0 (bright) towards 1 (dark).
func _noise(b: PackedFloat32Array, start: float, dur: float, amp: float, decay: float, smooth: float) -> void:
	var first := int(start * RATE)
	var low := 0.0
	for i in int(dur * RATE):
		var k := first + i
		if k >= b.size():
			break
		low += (rng.randf_range(-1.0, 1.0) - low) * (1.0 - smooth)
		b[k] += low * amp * exp(-float(i) / RATE * decay)


## A plucked string (Karplus-Strong). The tail wraps to the start of the buffer
## so looping music has no seam.
func _pluck(b: PackedFloat32Array, start: float, freq: float, amp: float, decay: float) -> void:
	var size := maxi(2, int(RATE / freq))
	var ring := PackedFloat32Array()
	ring.resize(size)
	for i in size:
		ring[i] = rng.randf_range(-1.0, 1.0)
	var first := int(start * RATE)
	var index := 0
	for i in int(2.5 * RATE):
		var current := ring[index]
		ring[index] = (current + ring[(index + 1) % size]) * 0.5 * decay
		index = (index + 1) % size
		b[(first + i) % b.size()] += current * amp


## A gentle low-pass over the whole sound.
func _smooth(b: PackedFloat32Array, amount: float) -> void:
	var low := 0.0
	for i in b.size():
		low += (b[i] - low) * (1.0 - amount)
		b[i] = low


func _save(sound_name: String, samples: PackedFloat32Array) -> void:
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := 0.9 / peak if peak > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	var path := ProjectSettings.globalize_path(OUT.path_join(sound_name + ".wav"))
	var err := wav.save_to_wav(path)
	print("%s %.2fs %s" % [sound_name, samples.size() / float(RATE), "ok" if err == OK else "error %d" % err])
