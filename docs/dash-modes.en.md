# Dash Modes

[简体中文](dash-modes.md)

Press **F1**, select a **Dash behavior**, and click **Apply & Save**.

| Mode | Off beat | On beat | Perfect |
| --- | --- | --- | --- |
| Free dash (original archive) | Standard dash | Burst dash | Burst dash |
| Rhythm gated (archive) | No dash | Standard dash | Burst dash |
| Rhythm gated + slowdown (default) | No dash | Standard dash slows on hit | Burst dash keeps its speed on hit |

The default windows are ±100 ms for perfect timing and ±200 ms for on-beat timing. The default cooldowns are 0.35 s for a standard dash and 0.20 s for a burst. A burst covers the same distance at 1.8× speed.

Rhythm-gated modes allow one successful dash per beat. Off-beat inputs do not start a cooldown. In the default mode, each enemy hit during a standard dash retains 45% of the current speed, with a floor of 15% of the starting speed. The slowdown lasts for the current dash and its duration stays the same. Adjust **Speed retained per enemy hit** in F1 settings.
