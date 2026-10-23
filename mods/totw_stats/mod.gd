extends Node
## Track of the Week stats: per week, counts attempts (timed laps that ended
## with more than 2 s on the clock: restarted, completed or left), completed
## laps (invalid ones too) and time on track (pauses and pre-race screen excluded).
## Shown as two extra rows (attempts · laps, time) in the timing box (UiPlayerLapInfo)
## while driving the track of the week; attempts include completed laps.
##
## File: user://totw_stats.json
##   { "<week start date>_<track id>": { track_id, track_name, attempts, laps, seconds } }

const STATS_PATH := "user://totw_stats.json"
const MIN_ATTEMPT_TIME := 2.0

var _stats := {}
var _week := {}  # entry for this week and track in _stats while driving the track of the week
var _track: Track
var _last_lap_time := 0.0  # read before a restart resets the lap
var _laps_label_value: Label  # attempts · laps value in the timing box
var _time_label_value: Label  # time value in the timing box


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	TimeAttackManager.restarted.connect(_on_restarted)


func _on_node_added(node: Node) -> void:
	if node is UiPlayerLapInfo:
		node.ready.connect(_add_rows.bind(node), CONNECT_ONE_SHOT)
	if node is Track:
		node.initialized.connect(_on_track_initialized.bind(node))
		node.tree_exiting.connect(_on_track_exiting.bind(node))


func _on_track_initialized(track: Track) -> void:
	# Restarted
	if track == _track:
		_end_attempt(_last_lap_time)

	# Clear values in case another track was loaded after TOTW
	_clear_variables()

	# Exit if not TOTW (or a past week's TOTW, if the game stayed open past Monday)
	if (not track.is_time_trial
			or track.player == null
			or not track.params.profile.is_track_of_the_week
			or not TrackOfTheWeekManager.is_available):
		return

	# Load the stats file if it exists
	var data = (JSON.parse_string(FileAccess.get_file_as_string(STATS_PATH))
			if FileAccess.file_exists(STATS_PATH)
			else null)
	if data is Dictionary:
		_stats = data

	var profile: TrackProfile = track.params.profile
	var id := "%s_%s" % [TrackOfTheWeekManager.get_week_start_date(), profile.id]
	# Add an entry for this week and track if there is none
	if not _stats.has(id):
		_stats[id] = {
			track_id = profile.id,
			track_name = profile.track_name,
			attempts = 0,
			laps = 0,
			seconds = 0.0
		}
	_week = _stats[id]
	_track = track
	track.player.lap_completed.connect(_on_lap_completed)
	# Save to file if a player pauses (a full restart re-initializes the same track)
	if not track.pause_updated.is_connected(_on_pause_updated):
		track.pause_updated.connect(_on_pause_updated)


func _on_pause_updated(_paused: bool) -> void:
	_save()


func _process(delta: float) -> void:
	# has_session_started is false on the pre-race screen
	if (not _week.is_empty()
			and _track.has_session_started
			and not _track.is_paused
			and is_instance_valid(_track.player)):
		# Save the laptime in case we reset and have to evaluate if we drove longer than 2 seconds
		_last_lap_time = _track.player.current_lap.time
		_week.seconds += delta

	if _week.is_empty() or not is_instance_valid(_time_label_value):
		return
	_time_label_value.text = _format_duration(_week.seconds)


# Copies the "Current" row (label, delta, time) twice so the rows match the game's style
# (its time label uses a font whose digits all have the same width, so the values don't jump).
# The game builds the timing box after the track is initialized (and again after every pause),
# so _week already tells whether this is the track of the week.
func _add_rows(info: UiPlayerLapInfo) -> void:
	if _week.is_empty():
		return
	_laps_label_value = _add_row(info, "Attempts · Laps")
	_time_label_value = _add_row(info, "Time")
	# Lap label is updated here initially and after an attempt completes
	_update_lap_label()


func _add_row(info: UiPlayerLapInfo, title: String) -> Label:
	# Get the UI row from the label
	var current_row: Control = info.current_lap_label.get_parent()
	var row: Control = current_row.duplicate()
	current_row.get_parent().add_child(row)
	row.get_child(0).text = title # Label
	row.get_child(1).text = "" # Delta
	return row.get_child(2) # Value (saved to be changed later)


func _on_restarted() -> void:
	_end_attempt(_last_lap_time)


func _on_lap_completed(lap: Lap) -> void:
	_week.laps += 1
	_end_attempt(lap.time)


func _on_track_exiting(track: Track) -> void:
	if track == _track:
		_end_attempt(_last_lap_time)
		_clear_variables()


func _clear_variables() -> void:
	_track = null
	_week = {}
	_stats = {}
	_last_lap_time = 0.0


func _end_attempt(lap_time: float) -> void:
	if _week.is_empty():
		return
	# Did we drive long enough to count the attempt?
	if lap_time > MIN_ATTEMPT_TIME:
		_week.attempts += 1
	_save()
	_update_lap_label()
	# Reset the laptime counter
	_last_lap_time = 0.0


func _update_lap_label() -> void:
	# Update the laps and attempts label
	if is_instance_valid(_laps_label_value):
		_laps_label_value.text = "%d · %d" % [_week.attempts, _week.laps]


func _save() -> void:
	var file := FileAccess.open(STATS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_stats, "\t"))


# m:ss, with hours from one hour on (h:mm:ss)
func _format_duration(seconds: float) -> String:
	var whole := int(seconds)
	# Special format > 1 hour
	if whole < 3600:
		return "%d:%02d" % [whole / 60, whole % 60]
	return "%d:%02d:%02d" % [whole / 3600, whole / 60 % 60, whole % 60]
