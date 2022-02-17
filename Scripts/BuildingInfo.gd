extends Control

func _on_PanelContainer_item_rect_changed():
	$Top.position.x = $PanelContainer.rect_size.x / 2.0
	$Bottom.position.x = $PanelContainer.rect_size.x / 2.0
	$Top.position.y = -4
	$Bottom.position.y = $PanelContainer.rect_size.y + 4
	rect_size = $PanelContainer.rect_size
