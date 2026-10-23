class_name ItemData
extends Resource
## Описание стакаемого предмета в стиле Risk of Rain.
## Каждый поднятый экземпляр увеличивает свойство персонажа по формуле стека.

enum ItemTier {
	WHITE,  ## Обычный (Common)
	GREEN,  ## Необычный (Uncommon)
	RED,    ## Легендарный (Legendary)
	BOSS    ## Предмет Босса (Boss item)
}

@export var id: StringName = &"item_default"
@export var item_name: String = "Неизвестный Артефакт"
@export_multiline var description: String = "Описание эффекта"
@export var tier: ItemTier = ItemTier.WHITE
@export var icon: Texture2D

@export_group("Пассивные бонусы (за каждый стак)")
@export var attack_speed_per_stack: float = 0.0 ## e.g. +0.15 (+15%)
@export var move_speed_per_stack: float = 0.0   ## e.g. +0.12 (+12%)
@export var health_per_stack: float = 0.0       ## e.g. +25 HP
@export var crit_chance_per_stack: float = 0.0  ## e.g. +0.10 (+10% шанс крита)
@export var extra_jumps_per_stack: int = 0      ## e.g. +1 прыжок в воздухе
@export var block_chance_per_stack: float = 0.0 ## e.g. 15% блок урона (Tougher Times)

@export_group("On-Hit Proc эффекты (при попадании)")
@export var chain_lightning_chance: float = 0.0 ## Шанс цепной молнии Укулеле (0.25)
@export var chain_targets: int = 0              ## Количество целей молнии
@export var bleed_chance_per_stack: float = 0.0 ## Шанс кровотечения (Tri-Tip)

@export_group("On-Kill Proc эффекты (при убийстве)")
@export var explosion_radius: float = 0.0       ## Радиус взрыва Бензина (Gasoline)
@export var explosion_damage_ratio: float = 0.0 ## Урон взрыва от базового урона игрока
