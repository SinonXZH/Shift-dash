# 关卡编辑

[English](level-editing.en.md)

1. 复制 `scenes/rooms/` 下的房间场景，保留根节点下的 `PlayerSpawn`、`Enemies` 和 `Exit`。
2. 移动 `PlayerSpawn` 和 `Exit`。在 `Enemies` 下直接摆放 `scenes/actors/enemy.tscn` 实例。用 `Kind` 选择追踪或射击，勾选 `Movement Disabled` 可让敌人原地行动。
3. 在房间根节点设置 `Arena Size`、`Rhythm Section` 和 `Difficulty`。保持房间根节点旋转为 0、缩放为 1。
4. 保存后按 **F6** 试玩当前房间，按 **R** 重开。将房间加入 `scenes/main.tscn` 根节点的 `Room Scenes` 数组，按 **F5** 依序试玩。关卡布局应在房间源场景中编辑。

## 障碍与危险区域

将道具放在房间根节点或 `Props` 下。

| 场景 | 编辑方法 |
| --- | --- |
| `scenes/props/obstacle.tscn` | 启用 **Editable Children**，在 `CollisionShape2D → Shape` 中调整尺寸或换成圆形、胶囊。 |
| `scenes/props/polygon_obstacle.tscn` | 启用 **Editable Children**，选中 `CollisionPolygon2D`，在 2D 视图编辑顶点。 |
| `scenes/props/hazard.tscn` | 用 `Size` 设置范围，`Damage` 设置伤害。勾选 `Dash Can Pass Safely` 可无伤冲过。 |

实心障碍会挡住玩家、敌人和子弹，外观随碰撞形状更新。危险区域可以穿过，默认冲刺时也会受伤。清空敌人后出口开启。

按 **F1** 调整移动、冲刺、节拍和音量。冲刺规则见[冲刺模式](dash-modes.md)。
