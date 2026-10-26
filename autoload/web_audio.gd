extends Node
## Sons na versão web servida por http:// (rede local). Fora de "contexto seguro"
## o navegador não tem o AudioWorklet do Godot, então o motor roda sem áudio
## (veja web/shell.html) e os efeitos sonoros tocam direto pelo Web Audio.
## Os sons são os mesmos de Sfx: as amostras PCM vão uma vez para o JavaScript.
## Som "3D" aproximado: volume pela distância e lado (esquerda/direita) pela câmera.

## Mesma escala de distância dos AudioStreamPlayer3D do jogo (unit_size).
const UNIT_SIZE := 8.0

var enabled := false

var _sent := {}

const SETUP_JS := """
window.ppAudio = {
	ctx: new (window.AudioContext || window.webkitAudioContext)(),
	buffers: {},
	add(id, base64, rate) {
		const bytes = Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
		const pcm = new Int16Array(bytes.buffer);
		const buffer = this.ctx.createBuffer(1, pcm.length, rate);
		const data = buffer.getChannelData(0);
		for (let i = 0; i < pcm.length; i++) data[i] = pcm[i] / 32768;
		this.buffers[id] = buffer;
	},
	play(id, volume, pan) {
		const buffer = this.buffers[id];
		if (!buffer) return;
		if (this.ctx.state !== 'running') this.ctx.resume();
		const source = this.ctx.createBufferSource();
		source.buffer = buffer;
		const gain = this.ctx.createGain();
		gain.gain.value = volume;
		let node = source.connect(gain);
		if (this.ctx.createStereoPanner) {
			const panner = this.ctx.createStereoPanner();
			panner.pan.value = pan;
			node = node.connect(panner);
		}
		node.connect(this.ctx.destination);
		source.start();
	},
};
// O navegador só libera o som depois de um toque ou tecla.
const unlock = () => window.ppAudio.ctx.resume();
window.addEventListener('pointerdown', unlock);
window.addEventListener('keydown', unlock);
window.addEventListener('touchend', unlock);
"""


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	enabled = not JavaScriptBridge.eval("window.isSecureContext", true)
	if enabled:
		JavaScriptBridge.eval(SETUP_JS, true)


## Toca `stream` (um som de Sfx). Com `at`, o volume e o lado dependem da câmera.
func play(stream: AudioStreamWAV, at: Variant = null) -> void:
	var id := stream.get_instance_id()
	if not _sent.has(id):
		_sent[id] = true
		JavaScriptBridge.eval("window.ppAudio.add(%d, '%s', %d)" % [
			id, Marshalls.raw_to_base64(stream.data), stream.mix_rate], true)
	var volume := 1.0
	var pan := 0.0
	var camera := get_viewport().get_camera_3d()
	if at is Vector3 and camera:
		var offset: Vector3 = at - camera.global_position
		volume = 1.0 / (1.0 + offset.length() / UNIT_SIZE)
		if offset.length() > 0.5:
			pan = clampf(camera.global_basis.x.dot(offset.normalized()), -1.0, 1.0) * 0.8
	JavaScriptBridge.eval("window.ppAudio.play(%d, %f, %f)" % [id, volume, pan], true)
