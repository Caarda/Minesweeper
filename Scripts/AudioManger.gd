extends AudioStreamPlayer

# --------------------------- #
var CurrentTrack: String
var IsFading: bool
# --------------------------- #
@onready var OSTA = $OST_A
@onready var OSTB = $OST_B
@onready var SFX = $SFX
# --------------------------- #

func _ready() -> void:
	PlaySong("ambient0")
	OSTA.pitch_scale = 1
	OSTB.pitch_scale = 1

func _process(delta: float) -> void:
	#if (Input.is_action_just_pressed("ChangeMusicType")):
	#	SwitchTrack()
	#	print("switch! ", CurrentTrack)
		
	if IsFading:
		OSTB.volume_db = max(-100, linear_to_db(db_to_linear(OSTB.volume_db) - 0.001))
		OSTA.volume_db = linear_to_db(db_to_linear(OSTA.volume_db) + 0.001)
		
		if OSTA.volume_db > 0:
			OSTB.stop()
			OSTA.volume_db = 0
			IsFading = false
			
	if CurrentTrack != null and OSTA.is_playing() == false:
		OSTA.play()

func SwitchTrack():
	IsFading = true
	if CurrentTrack == "ambient2":
		FadeTracks("ambient2", "battle2")
	elif CurrentTrack == "battle2":
		FadeTracks("battle2", "ambient2")
	
func FadeTracks(Current: String, New: String):
	CurrentTrack = New
	OSTB.stream = load("res://Assets/Audio/Music/%s.ogg" % Current)
	OSTB.volume_db = linear_to_db(1)
	OSTB.play()
	OSTB.seek(OSTA.get_playback_position())
	
	OSTA.stream = load("res://Assets/Audio/Music/%s.ogg" % New)
	OSTA.volume_db = linear_to_db(0)
	OSTA.play()
	OSTA.seek(OSTB.get_playback_position())

func PlaySong(Name: String):
	CurrentTrack = Name
	OSTA.stream = load("res://Assets/Audio/Music/%s.mp3" % Name)
	OSTA.play()
	
func PlaySFX(Name: String):
	SFX.stream = load("res://Assets/Audio/Sounds/%s.mp3" % Name)
	SFX.play()
