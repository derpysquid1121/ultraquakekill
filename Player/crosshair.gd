@tool
extends Control

@export var crosshair_circle := 1
@export var crosshair_size := 1
@export var crosshair_length := [7, 16, 6, 17]
@export var crosshair_color := Color(0,1,0)
@export var crosshair_shadow := Color(0,0,0)

func _draw() -> void:
	draw_circle(Vector2.ZERO, crosshair_circle + 1, crosshair_shadow)
	draw_circle(Vector2.ZERO, crosshair_circle, crosshair_color)
	
	draw_line(Vector2(crosshair_length[2], 0), Vector2(crosshair_length[3], 0), crosshair_shadow, crosshair_size + 2)
	draw_line(Vector2(crosshair_length[2] * -1, 0), Vector2(crosshair_length[3] * -1, 0), crosshair_shadow, crosshair_size + 2)
	
	draw_line(Vector2(0, crosshair_length[2]), Vector2(0, crosshair_length[3]), crosshair_shadow, crosshair_size + 2)
	draw_line(Vector2(0, crosshair_length[2] * -1), Vector2(0, crosshair_length[3] * -1), crosshair_shadow, crosshair_size + 2)
	
	draw_line(Vector2(crosshair_length[0], 0), Vector2(crosshair_length[1], 0), crosshair_color, crosshair_size)
	draw_line(Vector2(crosshair_length[0] * -1, 0), Vector2(crosshair_length[1] * -1, 0), crosshair_color, crosshair_size)
	
	draw_line(Vector2(0, crosshair_length[0]), Vector2(0, crosshair_length[1]), crosshair_color, crosshair_size)
	draw_line(Vector2(0, crosshair_length[0] * -1), Vector2(0, crosshair_length[1] * -1), crosshair_color, crosshair_size)
