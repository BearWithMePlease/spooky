extends AudioListener2D

var sound_effects: Array

func on_main_finished_ready():
	self.sound_effects = get_tree().get_nodes_in_group("sound_effects")

	# Start all sound effects
	for audio_player:AudioStreamPlayer2D in sound_effects:
		audio_player.play()
