extends Node

signal changed(cur_exp: float, max_exp: float, cur_lvl: int)

# NOTES
const notes := {
	"stone": "С пустыми руками вряд-ли получится выжить! Для начало нужно повалить дерево, для этого подойдет любой близлежайший камень [подобрать камень - press F]",
	
	"log": "У меня получилось срубить дерево! Но дальше орудовать камнем желания нет, нужно сделать примитивные инструменты из того что есть.\
	Я могу сделать каменные инструменты: для топора нужен камень[x2] и дерево[x3], а для кирки камень[x3] и дерево[x2].\
	Чтобы что-то сделать нужно сложить [press Q] материалы на землю и начать крафт [press C].",
	
	"night": "Уже темнеет... Важно подготовиться к ночи. Я не буду ночевать в темноте и на голодный желудок!\
	Чтобы развести костер, нужно сложить бревна[x3] в кучу. А подкрепиться можно с ягод которые растут неподалёку.\
	[Положите древесину, откройте зону крафта, создайте костер и добавьте дров [RIGHT CLICK] для горения]",
	
}

var unlocked_notes := []

# EXPERIENCE
const lvlup_cost := 6.0
var lvl: int = 0
var cur_exp: float = 0.0

func add_exp(added_exp: float) -> void:
	cur_exp += added_exp
	
	var cur_lvlup_cost: float = lvlup_cost + lvlup_cost * lvl/2
	if cur_exp > cur_lvlup_cost:
		cur_exp -= cur_lvlup_cost
		lvl += 1
		G.text_message.add("NEW LEVEL REACHED!")
	
	changed.emit(cur_exp, cur_lvlup_cost, lvl)

func add_note(note_name: String) -> void:
	unlocked_notes.append(notes[note_name])
	G.text_message.add("NEW NOTE UNLOCKED! VIEW IT IN BOOK [press B]")
