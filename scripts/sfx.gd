class_name Sfx
extends RefCounted
## Efeitos sonoros sintetizados em código (sem arquivos de áudio).

const MIX_RATE := 22050

static var _cache := {}


static func whistle() -> AudioStreamWAV:
	return _cached("whistle", func() -> AudioStreamWAV: return _synth(0.7, 1300.0, 1300.0, 0.45, 400.0, 7.0))


static func catch_sound() -> AudioStreamWAV:
	return _cached("catch", func() -> AudioStreamWAV: return _synth(0.45, 900.0, 220.0, 0.5))


static func miss() -> AudioStreamWAV:
	return _cached("miss", func() -> AudioStreamWAV: return _synth(0.35, 160.0, 120.0, 0.45, 0.0, 0.0, true))


static func poof() -> AudioStreamWAV:
	return _cached("poof", func() -> AudioStreamWAV: return _synth(0.18, 500.0, 1400.0, 0.3))


static func tick() -> AudioStreamWAV:
	return _cached("tick", func() -> AudioStreamWAV: return _synth(0.06, 1000.0, 1000.0, 0.3))


static func _cached(key: String, factory: Callable) -> AudioStreamWAV:
	if not _cache.has(key):
		_cache[key] = factory.call()
	return _cache[key]


## Gera um tom com varredura de frequência (`from_hz` -> `to_hz`), vibrato opcional
## e envelope suave. `square` deixa o som mais "áspero" (usado no erro).
static func _synth(duration: float, from_hz: float, to_hz: float, volume: float,
		vibrato_depth := 0.0, vibrato_rate := 0.0, square := false) -> AudioStreamWAV:
	var samples := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in samples:
		var t := float(i) / MIX_RATE
		var progress := t / duration
		var freq := lerpf(from_hz, to_hz, progress) + sin(t * TAU * vibrato_rate) * vibrato_depth
		phase += TAU * freq / MIX_RATE
		var value := sin(phase)
		if square:
			value = signf(value) * 0.6
		var envelope := minf(1.0, t * 80.0) * minf(1.0, (duration - t) * 12.0)
		data.encode_s16(i * 2, int(clampf(value * envelope * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
