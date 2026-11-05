# 冲刺模式

[English](dash-modes.en.md)

按 **F1**，在 **Dash behavior** 中选择模式，然后点击 **Apply & Save**。

| 模式 | 不合拍 | 普通合拍 | 完美合拍 |
| --- | --- | --- | --- |
| Free dash (original archive) | 普通冲刺 | 爆发冲刺 | 爆发冲刺 |
| Rhythm gated (archive) | 不冲刺 | 普通冲刺 | 爆发冲刺 |
| Rhythm gated + slowdown（默认） | 不冲刺 | 普通冲刺，命中减速 | 爆发冲刺，命中保持速度 |

默认完美窗口为 ±100 ms，合拍窗口为 ±200 ms。普通与爆发冲刺的默认冷却分别为 0.35 秒和 0.20 秒。爆发以 1.8 倍速度冲完相同距离。

节奏限定模式每拍只允许一次成功冲刺，脱拍不消耗冷却。默认模式下，普通冲刺每次命中保留当前速度的 45%，最低为初速的 15%。减速只影响本次冲刺，剩余时长不变。可在 F1 的 **Speed retained per enemy hit** 调整倍率。
