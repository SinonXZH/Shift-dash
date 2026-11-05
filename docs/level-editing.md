# 在编辑器中布置关卡

## 场景入口

- `scenes/main.tscn`：游戏流程、房间顺序、玩家、HUD、调试设置及音频节点。
- `scenes/rooms/room_01.tscn`～`room_03.tscn`：三个可直接编辑的房间。
- `scenes/actors/player.tscn`：玩家、冲刺状态、拖尾、呼吸环；逻辑在 `scripts/player.gd`。
- `scenes/actors/enemy.tscn`：可重复实例化的敌人；Inspector 中 Kind 选择追踪或射击，Speed Multiplier 控制个体移速，Initial Fire Delay 控制首次开火延迟。
- 选中敌人实例并勾选 `Movement Disabled` 可禁止移动；射击、受击和清房判定继续有效。运行时代码可通过 `enemy.movement_disabled = true` 禁止移动，设为 `false` 恢复。
- `scenes/rooms/exit.tscn`：出口，Size 控制触发区域与显示尺寸。
- `scenes/ui/game_ui.tscn`：HUD、按钮、开始/暂停/结算面板。可在 2D 编辑器中调整布局、字体和主题。

## 修改现有房间

1. 打开房间场景，拖动 `PlayerSpawn` 修改玩家出生点。
2. 将 `enemy.tscn` 拖入 `Enemies` 节点下，移动或复制敌人实例。运行时会直接读取这些实例，不再额外随机生成敌人。
3. 拖动 `Exit` 修改出口。清空所有敌人后出口开启。
4. 选中房间根节点，修改 `Arena Size`、`Rhythm Section` 和 `Difficulty`。节奏与房间顺序独立，复制房间后也可选择任意一种节奏。
5. 按 F6 单独试玩此房间，按 R 重开。F5 从主场景运行完整房间序列。

房间根节点支持平移；矩形边界按轴对齐计算，请保持根节点旋转为 0、缩放为 1。Arena Size 的原点为房间左上角，敌人与出生点应位于矩形内部。可以用障碍物场景布置内部墙体。

## 布置障碍与危险区域

- 将 `scenes/props/obstacle.tscn` 拖入房间根节点或自行建立的 `Props` 节点下。灰蓝色实心块会阻挡玩家、敌人和子弹；冲刺撞墙后停止。通过 Inspector 的 `Size` 修改尺寸，绘制与碰撞一起更新，建议用 Size 而非节点缩放调整大小。
- 将 `scenes/props/hazard.tscn` 拖入同样位置。红色尖刺区域不阻挡移动，但玩家接触或高速穿过都会受伤。`Size` 控制范围，`Damage` 控制每次伤害；默认冲刺也会受伤，勾选 `Dash Can Pass Safely` 可以允许冲刺无伤穿越。
- 危险区域沿用受伤无敌间隔，持续站在里面会在无敌结束后再次受伤，不会每帧扣血；出生保护期间也不会受伤。
- 障碍物和危险区域不计入清房敌人数，不要放到 `Enemies` 节点下。不要将玩家出生点放在实心障碍内部。

## 添加房间

复制任一现有房间场景并重新布置，保留 `PlayerSpawn`、`Enemies`、`Exit` 三个节点名称。打开 `main.tscn`，选中根节点，在 Inspector 的 `Room Scenes` 数组中加入新场景，并调整顺序。房间总数自动取数组长度。

主场景中的 `Rooms/RoomPreview` 仅用于查看第一个房间的布局；请在房间源场景中修改并保存。运行及重开时按 `Room Scenes` 数组重新实例化，不读取预览实例的临时覆盖。

## 调试与回归

F1 保留移动、冲刺、敌人速度、节拍及音频调试。敌人数量由摆放实例数决定；每个房间的 Difficulty 决定敌人速度/射速的成长级别。

可使用 Godot 控制台运行回归：

```text
godot --headless --path . --script res://tests/scene_smoke.gd
```

测试覆盖房间实例、出生点、敌人开火、合拍冲刺、出口切换、重开、设置暂停，以及 F6 单房间试玩入口。
