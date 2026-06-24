# item_builder — Конструктор власних предметів для Luanti/Minetest

## Що робить мод

Дозволяє будь-якому гравцю з привілеєм `item_builder` створювати власні предмети прямо в грі через зручний GUI — без перезапуску сервера.

## Команди

| Команда | Опис |
|---|---|
| `/itembuilder` або `/ib` | Відкрити конструктор |

## Привілей

```
/grant <ім'я> item_builder
```

За замовчуванням адміністратор і одиночна гра вже мають привілей.

## Що можна робити в GUI

1. **Новий предмет** — відкриває редактор:
   - **Системна назва** — унікальна назва англійською (без пробілів), наприклад `magic_sword`
   - **Відображувана назва** — що бачить гравець у інвентарі
   - **Опис** — текст підказки
   - **Тип предмету** — `craftitem`, `tool` або `node`
   - **Lua-код** — необов'язковий код що визначає поведінку (on_use, on_place тощо)
   - **Текстура** — піксель-арт редактор 16×16 з палітрою та hex-кольорами

2. **Список предметів** — перегляд, редагування та видалення збережених предметів

## Де зберігаються дані

```
<папка_світу>/custom_items/
  ├── _index.txt          ← список імен
  ├── magic_sword.lua     ← визначення предмету
  ├── magic_sword.png     ← текстура (16×16 RGBA PNG)
  └── ...
```

## Приклад Lua-коду для предмету

```lua
-- Код виконується в sandbox, змінює таблицю def перед реєстрацією
def.on_use = function(itemstack, user, pointed_thing)
    minetest.chat_send_player(user:get_player_name(), "✨ Магія!")
    return itemstack
end

def.on_place = function(itemstack, placer, pointed_thing)
    local pos = pointed_thing.above
    minetest.set_node(pos, {name = "default:torch"})
    return itemstack
end
```

## Версія Luanti

Мінімальна: **5.6** (через `formspec_version[4]` та `minetest.dynamic_add_media`)

## Встановлення

1. Скопіюйте папку `item_builder` у `mods/` вашого Luanti
2. Активуйте мод у менеджері модів або у `world.mt`:
   ```
   load_mod_item_builder = true
   ```
3. Запустіть світ та виконайте `/itembuilder`
