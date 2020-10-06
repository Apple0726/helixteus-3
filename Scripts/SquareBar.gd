extends Control

func set_progress(progress):
	$Bar1.value = progress * 8
	$Bar2.value = (progress - 12.5) * 4
	$Bar3.value = (progress - 37.5) * 4
	$Bar4.value = (progress - 62.5) * 4
	$Bar5.value = (progress - 87.5) * 8
