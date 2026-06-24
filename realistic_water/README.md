# 🌊 Realistic Water Mod for Luanti (Minetest)

Повністю реалістична вода з хвилями, відбиттям, пінею та ефектами каустики.

## ✨ Особливості

| Ефект | Опис |
|---|---|
| **Хвилі Герстнера** | 4 шари хвиль з фізично правильною дисперсією |
| **Глибинний колір** | Мілководдя — блакитне, глибини — темно-сині |
| **Фресне** | На краях вода дзеркальна, крізь центр — прозора |
| **Дзеркальний блиск** | Сонце відбивається на поверхні |
| **Підводне розсіяння** | Тонкі краї води світяться (SSS) |
| **Піна на берегах** | Автоматична піна де вода зустрічається з землею |
| **Каустика** | Хвилі світла під водою |
| **Бризки** | Частинки при падінні у воду |
| **Кола на воді** | Анімовані кола від гравця |

## 📦 Встановлення

1. Розпакуй папку `realistic_water` в:
   ```
   ~/.minetest/mods/realistic_water/
   ```
   Або на Windows:
   ```
   %APPDATA%\minetest\mods\realistic_water\
   ```

2. Запусти Luanti, відкрий потрібний світ → **Налаштування** → **Моди** → увімкни **realistic_water**

3. Переконайся що в налаштуваннях гри увімкнено:
   - `enable_shaders = true`
   - `enable_waving_water = true`
   - `waving_water_height = 0.2`
   - `waving_water_length = 10`
   - `waving_water_speed = 10`

4. Запускай! Вся стара вода автоматично замінюється новою.

## ⚙️ Параметри (minetest.conf)

```ini
# Висота хвиль (за замовчуванням 0.2)
waving_water_height = 0.2

# Довжина хвиль
waving_water_length = 10

# Швидкість анімації
waving_water_speed = 10

# ОБОВ'ЯЗКОВО для шейдерів!
enable_shaders = true
enable_waving_water = true
```

## 🗂️ Структура файлів

```
realistic_water/
├── mod.conf                          # Метадані моду
├── init.lua                          # Головний Lua код
├── textures/
│   ├── rw_water_surface_anim.png     # Анімована поверхня (16 кадрів)
│   ├── rw_water_normal.png           # Карта нормалей
│   ├── rw_foam_particle.png          # Частинка піни
│   ├── rw_caustic_particle.png       # Частинка каустики
│   └── rw_ripple_particle.png        # Частинка кола
└── shaders/
    └── nodes/
        ├── water_source/
        │   ├── opengl_vertex.glsl    # Вертекс-шейдер (хвилі)
        │   └── opengl_fragment.glsl  # Фрагмент-шейдер (колір, піна)
        └── water_flowing/
            ├── opengl_vertex.glsl
            └── opengl_fragment.glsl
```

## 🔧 Сумісність

- **Luanti** ≥ 5.7 (рекомендовано 5.8+)
- **Minetest Game** або будь-яка гра з `default`
- Сумісно з `bucket`, `rivers`, `mcl_core`
- OpenGL 3.0+ для повних шейдерів

## 🐛 Відомі обмеження

- Шейдери працюють лише з OpenGL (не OpenGL ES / Android)
- На дуже слабких GPU можна вимкнути шейдери — ефекти частинок і колір залишаться
- Перше завантаження чанків зі старою водою займає кілька секунд для конвертації

## 💬 Команди

```
/rwater   — показати інформацію про мод
```

---
Made with 🌊 for Luanti community
