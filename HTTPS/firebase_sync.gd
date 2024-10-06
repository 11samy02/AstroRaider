extends Node

var firebase_url := "https://astro-raider-default-rtdb.europe-west1.firebasedatabase.app/Highscore.json"

@onready var http_request = $HTTPRequest
var current_request := ""

var All_Highscores : Array = []

signal request_finished

func _ready() -> void:
	http_request.request_completed.connect(on_http_request_request_completed)

func send_highscore(player_name: String, wave: int):
	current_request = "POST"
	
	var data = {
		"player_name": player_name,
		"wave": wave
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	var err = http_request.request(firebase_url, headers, HTTPClient.METHOD_POST, json_data)
	
	if err == OK:
		print("Anfrage erfolgreich gesendet")
	else:
		print("Fehler beim Senden der Anfrage:", err)

func get_highscores():
	current_request = "GET"
	All_Highscores = []
	
	var err = http_request.request(firebase_url)
	if err == OK:
		print("GET-Anfrage erfolgreich gesendet")
	else:
		print("Fehler beim Senden der GET-Anfrage:", err)


func on_http_request_request_completed(result, response_code, headers, body):
	print("Anfrage abgeschlossen mit Ergebnis:", result)
	print("HTTP-Antwortcode:", response_code)
	if response_code == 200:
		if current_request == "POST":
			print("Highscore erfolgreich gespeichert!")
			request_finished.emit()
		elif current_request == "GET":
			print("Highscores erfolgreich abgerufen!")
			var json_response = body.get_string_from_utf8()
			var highscores = JSON.parse_string(json_response)
			if highscores == null:
				print("Fehler beim Parsen der Highscore-Daten")
			else:
				for key in highscores.keys():
					All_Highscores.append(highscores[key])
				
				All_Highscores.sort_custom(compare_highscores)
				request_finished.emit()
	else:
		print("Fehler bei der Anfrage:", response_code)
		print("Antwort:", body.get_string_from_utf8())

func compare_highscores(a, b):
	if typeof(a["wave"]) == TYPE_INT and typeof(b["wave"]) == TYPE_INT:
		if a["wave"] > b["wave"]:
			return true
	elif typeof(a["wave"]) == TYPE_INT and typeof(b["wave"]) != TYPE_INT:
		return true
	return false
