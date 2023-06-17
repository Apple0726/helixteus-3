extends Control

func _on_PanelContainer_item_rect_changed():
	$Top.position.x = $PanelContainer.size.x / 2.0
	$Bottom.position.x = $PanelContainer.size.x / 2.0
	$Top.position.y = -4
	$Bottom.position.y = $PanelContainer.size.y + 4
	size = $PanelContainer.size
