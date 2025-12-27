extends Node

func format_number(value: int) -> String:
	if value < 1000:
		return str(value)
	
	var suffixes = ["K", "M", "B", "T", "Qa", "Qi"]  # You can expand as needed
	var index = 0
	var number = float(value)
	
	while number >= 1000 and index < suffixes.size():
		number /= 1000.0
		index += 1
	
	# Keep one decimal if needed
	var formatted := str(round(number * 10) / 10.0)
	
	return formatted + suffixes[index - 1]
