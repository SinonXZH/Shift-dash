extends RefCounted
## Archived free mode and the new rhythm-gated mode share the same movement code.
enum Mode { FREE_ARCHIVED, RHYTHM_GATED, CONTACT_SLOWDOWN }

static func evaluate(mode: int, error: float, perfect_window: float, good_window: float, fresh_beat: bool) -> Dictionary:
	var onbeat := error <= good_window and fresh_beat
	var perfect := error <= perfect_window and onbeat
	if mode in [Mode.RHYTHM_GATED, Mode.CONTACT_SLOWDOWN]:
		return {"allowed": onbeat, "empowered": perfect, "confirmed": onbeat,
			"perfect": perfect, "label": "PERFECT" if perfect else ("ON BEAT" if onbeat else ("BEAT USED" if not fresh_beat and error <= good_window else "OFF BEAT"))}
	return {"allowed": true, "empowered": onbeat, "confirmed": onbeat,
		"perfect": perfect, "label": "PERFECT" if perfect else ("ON BEAT" if onbeat else "FREE DASH")}
