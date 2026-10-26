extends Node
## Servidor HTTP mínimo que entrega a versão web do jogo a partir de quem hospeda.
## Celulares e navegadores na mesma rede abrem http://IP-do-host:PORT e jogam sem
## instalar nada; a página então conecta por WebSocket na porta do jogo.
##
## Os arquivos da exportação web vêm de `web/site.zip`, que o tools/export.sh gera
## e embute nas builds de PC e Android. Sem ele (ex.: rodando pelo editor antes de
## exportar), o servidor não sobe e o lobby avisa.
##
## Só responde GET aos arquivos do zip. O envio é feito aos poucos, a cada quadro,
## para o .wasm (~40 MB) não travar o jogo de quem hospeda.

const PORT := 8080
const SITE_ZIP := "res://web/site.zip"
## Bytes enviados por conexão a cada quadro.
const CHUNK := 256 * 1024
const MIME_TYPES := {
	"html": "text/html; charset=utf-8",
	"js": "application/javascript",
	"wasm": "application/wasm",
	"pck": "application/octet-stream",
	"png": "image/png",
	"json": "application/json",
}

var _server: TCPServer
var _zip: ZIPReader
var _files := PackedStringArray()
## Conexões abertas: {"peer": StreamPeerTCP, "request": String, "out": PackedByteArray, "sent": int}
var _clients: Array[Dictionary] = []


## O host tem a versão web para servir? (o navegador nunca hospeda)
func is_available() -> bool:
	return not OS.has_feature("web") and FileAccess.file_exists(SITE_ZIP)


func is_running() -> bool:
	return _server != null and _server.is_listening()


func start() -> bool:
	if is_running():
		return true
	if not is_available():
		return false
	_zip = ZIPReader.new()
	if _zip.open(SITE_ZIP) != OK:
		_zip = null
		return false
	_files = _zip.get_files()
	_server = TCPServer.new()
	if _server.listen(PORT) != OK:
		push_warning("Não foi possível abrir a porta %d para a versão web." % PORT)
		stop()
		return false
	print("Versão web disponível na porta %d (%d arquivos)." % [PORT, _files.size()])
	return true


func stop() -> void:
	for client in _clients:
		client.peer.disconnect_from_host()
	_clients.clear()
	if _server:
		_server.stop()
	_server = null
	if _zip:
		_zip.close()
	_zip = null


func _process(_delta: float) -> void:
	if not is_running():
		return
	while _server.is_connection_available():
		_clients.append({"peer": _server.take_connection(), "request": "", "out": PackedByteArray(), "sent": 0})
	for client in _clients.duplicate():
		_serve(client)


func _serve(client: Dictionary) -> void:
	var peer: StreamPeerTCP = client.peer
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_clients.erase(client)
		return
	if client.out.is_empty():
		var available := peer.get_available_bytes()
		if available > 0:
			client.request += peer.get_utf8_string(available)
		if not "\r\n\r\n" in client.request:
			if client.request.length() > 16384:
				_close(client)
			return
		client.out = _response(client.request.get_slice("\r\n", 0))
		return
	var result: Array = peer.put_partial_data(client.out.slice(client.sent, client.sent + CHUNK))
	if result[0] != OK:
		_close(client)
		return
	client.sent += result[1]
	if client.sent >= client.out.size():
		_close(client)


func _close(client: Dictionary) -> void:
	client.peer.disconnect_from_host()
	_clients.erase(client)


## Monta a resposta para a primeira linha do pedido (ex.: "GET /index.wasm HTTP/1.1").
func _response(request_line: String) -> PackedByteArray:
	var parts := request_line.split(" ")
	if parts.size() < 2 or parts[0] != "GET":
		return _status(405, "Method Not Allowed")
	var path := parts[1].get_slice("?", 0).trim_prefix("/")
	if path.is_empty():
		path = "index.html"
	if not path in _files:
		return _status(404, "Not Found")
	var body := _zip.read_file(path)
	var header := "HTTP/1.1 200 OK\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n" \
		% [MIME_TYPES.get(path.get_extension(), "application/octet-stream"), body.size()]
	return header.to_utf8_buffer() + body


func _status(code: int, text: String) -> PackedByteArray:
	return ("HTTP/1.1 %d %s\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" % [code, text]).to_utf8_buffer()
