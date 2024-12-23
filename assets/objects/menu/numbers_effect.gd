@tool
extends RichTextEffect
class_name RichTextNumbers

var bbcode = "numbers"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.offset = Vector2(0, -char_fx.relative_index)
	return true
