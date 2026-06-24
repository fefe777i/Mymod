-- СЛОВА ТА ЇХ ХАРАКТЕРИСТИКИ
local WORDS_DATABASE = {
    -- Рівень 1 (легкі слова)
    {
        id = "big",
        word = "Біг",
        description = "Швидкість пересування",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30, -- секунд
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "speed", amount = -0.1},
                {type = "message", text = "Ви стали повільнішим"}
            }
        }
    },
    -- ПРИРОДА
    {
        id = "lis",
        word = "Ліс",
        description = "Дух дерев",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "agility", amount = 1},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 1},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "message", text = "Ви стали мудрішим, але менш спритним"}
            }
        }
    },
    {
        id = "richka",
        word = "Річка",
        description = "Плинність води",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "speed", amount = 0.2},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 1},
                {type = "attribute", attr = "speed", amount = -0.1},
                {type = "message", text = "Ви стали сильнішим, але повільнішим"}
            }
        }
    },
    {
        id = "viter",
        word = "Вітер",
        description = "Свобода польоту",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "jump", amount = 0.2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "will", amount = 1},
                {type = "attribute", attr = "jump", amount = -0.1},
                {type = "message", text = "Ви стали вольовішим, але менш стрибким"}
            }
        }
    },
    {
        id = "kamin",
        word = "Камінь",
        description = "Незламність",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 1},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 1},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але менш вольовим"}
            }
        }
    },
    {
        id = "vogon",
        word = "Вогонь",
        description = "Пристрасть та енергія",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "message", text = "Ви стали мудрішим, але слабкішим"}
            }
        }
    },
    {
        id = "zemlya",
        word = "Земля",
        description = "Родючість та основа",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 1},
                {type = "attribute", attr = "speed", amount = -0.1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "speed", amount = 0.2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали швидшим, але менш вольовим"}
            }
        }
    },
    {
        id = "more",
        word = "Море",
        description = "Глибина та таємниці",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали сильнішим, але менш мудрим"}
            }
        }
    },
    {
        id = "nebo",
        word = "Небо",
        description = "Висота та мрії",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "jump", amount = 0.3},
                {type = "attribute", attr = "will", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "jump", amount = -0.2},
                {type = "message", text = "Ви стали вольовішим, але менш стрибким"}
            }
        }
    },
    {
        id = "sonce",
        word = "Сонце",
        description = "Світло та життя",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали мудрішим, але менш вольовим"}
            }
        }
    },
    {
        id = "misats",
        word = "Місяць",
        description = "Таємничість та інтуїція",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але менш мудрим"}
            }
        }
    },
    {
        id = "zirka",
        word = "Зірка",
        description = "Надія та напрямок",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "message", text = "Ви стали вольовішим, але менш спритним"}
            }
        }
    },
    
    -- КУЛЬТУРА
    {
        id = "mova",
        word = "Мова",
        description = "Сила слова",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали сильнішим, але менш розумним"}
            }
        }
    },
    {
        id = "pismennist",
        word = "Писемність",
        description = "Збереження знань",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але менш розумним"}
            }
        }
    },
    {
        id = "kaligrafia",
        word = "Каліграфія",
        description = "Краса письма",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "message", text = "Ви стали розумнішим, але менш спритним"}
            }
        }
    },
    {
        id = "mitstvo",
        word = "Мистецтво",
        description = "Творчість та натхнення",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 1},
                {type = "attribute", attr = "agility", amount = 1},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 15}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "message", text = "Ви стали сильнішим, але менш творчим"}
            }
        }
    },
    {
        id = "muzyka",
        word = "Музика",
        description = "Гармонія звуків",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали сильнішим, але менш гармонійним"}
            }
        }
    },
    {
        id = "tanets",
        word = "Танець",
        description = "Рух та грація",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "message", text = "Ви стали вольовішим, але менш граційним"}
            }
        }
    },
    {
        id = "teatr",
        word = "Театр",
        description = "Перевтілення",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але менш артистичним"}
            }
        }
    },
    {
        id = "pisennya",
        word = "Пісення",
        description = "Голос предків",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 3},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 20}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 3},
                {type = "attribute", attr = "will", amount = -2},
                {type = "message", text = "Ви стали мудрішим, але втратили голос"}
            }
        }
    },
    {
        id = "obryad",
        word = "Обряд",
        description = "Давні традиції",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 25}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 3},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але втратили традиції"}
            }
        }
    },
    {
        id = "svyato",
        word = "Свято",
        description = "Радість буття",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 1},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 15}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали розумнішим, але сумнішим"}
            }
        }
    },
    
    -- МОВА ТА ПИСЬМО
    {
        id = "litera",
        word = "Літера",
        description = "Основа письма",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 1},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 5}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 1},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали сильнішим, але менш грамотним"}
            }
        }
    },
    {
        id = "slovo",
        word = "Слово",
        description = "Сила висловлювання",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але менш красномовним"}
            }
        }
    },
    {
        id = "rechennya",
        word = "Речення",
        description = "Зв'язність думок",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "will", amount = -1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали вольовішим, але думки плутаються"}
            }
        }
    },
    {
        id = "tekst",
        word = "Текст",
        description = "Зібрання слів",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 45,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "speed", amount = -0.1},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "attribute", attr = "speed", amount = 0.2},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви стали швидшим, але менш начитаним"}
            }
        }
    },
    {
        id = "knyha",
        word = "Книга",
        description = "Мудрість сторінок",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 3},
                {type = "attribute", attr = "strength", amount = -1},
                {type = "edos", amount = 20}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 3},
                {type = "attribute", attr = "mind", amount = -2},
                {type = "message", text = "Ви стали сильнішим, але менш мудрим"}
            }
        }
    },
    {
        id = "suviy",
        word = "Сувій",
        description = "Давні знання",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 3},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 20}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 3},
                {type = "attribute", attr = "mind", amount = -2},
                {type = "message", text = "Ви стали спритнішим, але втратили знання"}
            }
        }
    },
    {
        id = "glyph",
        word = "Гліф",
        description = "Магічний символ",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 2},
                {type = "attribute", attr = "will", amount = 2},
                {type = "attribute", attr = "agility", amount = -1},
                {type = "edos", amount = 25}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 3},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "attribute", attr = "will", amount = -1},
                {type = "message", text = "Ви стали спритнішим, але магія зникає"}
            }
        }
    },
    {
        id = "runa",
        word = "Руна",
        description = "Слов'янська магія",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 3},
                {type = "attribute", attr = "mind", amount = -1},
                {type = "edos", amount = 20}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 3},
                {type = "attribute", attr = "will", amount = -2},
                {type = "message", text = "Ви стали мудрішим, але втратили силу предків"}
            }
        }
    },
        -- РІВЕНЬ 4 (Епічні слова)
    {
        id = "nezlamnist",
        word = "Незламність",
        description = "Духовна міць, що не піддається жодним випробуванням",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 8},
                {type = "attribute", attr = "mind", amount = -3},
                {type = "attribute", attr = "agility", amount = -2},
                {type = "edos", amount = 80}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 5},
                {type = "attribute", attr = "agility", amount = 3},
                {type = "attribute", attr = "will", amount = -4},
                {type = "message", text = "Ви стали гнучкішим, але втратили стержень"}
            }
        }
    },
    {
        id = "vseperedbachennya",
        word = "Всепередбачення",
        description = "Здатність бачити всі можливі варіанти майбутнього",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 10},
                {type = "attribute", attr = "will", amount = -4},
                {type = "attribute", attr = "strength", amount = -3},
                {type = "edos", amount = 90}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 6},
                {type = "attribute", attr = "will", amount = 4},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "message", text = "Ви стали сильнішим, але майбутнє приховане"}
            }
        }
    },
    {
        id = "blagorodstvo",
        word = "Благородство",
        description = "Честь та гідність, що передаються поколіннями",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 7},
                {type = "attribute", attr = "mind", amount = 4},
                {type = "attribute", attr = "agility", amount = -5},
                {type = "edos", amount = 85}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 8},
                {type = "attribute", attr = "mind", amount = -3},
                {type = "attribute", attr = "will", amount = -3},
                {type = "message", text = "Ви стали спритнішим, але втратили честь"}
            }
        }
    },
    {
        id = "pershodzherelo",
        word = "Першоджерело",
        description = "Знання з самого початку часів",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 9},
                {type = "attribute", attr = "will", amount = 3},
                {type = "attribute", attr = "speed", amount = -0.4},
                {type = "edos", amount = 90}
            },
            reject = {
                {type = "attribute", attr = "speed", amount = 0.6},
                {type = "attribute", attr = "agility", amount = 4},
                {type = "attribute", attr = "mind", amount = -4},
                {type = "message", text = "Ви стали швидшим, але втратили першознання"}
            }
        }
    },
    {
        id = "vsesvit",
        word = "Всесвіт",
        description = "Розуміння безмежності буття",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 8},
                {type = "attribute", attr = "will", amount = 5},
                {type = "attribute", attr = "strength", amount = -4},
                {type = "edos", amount = 95}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 7},
                {type = "attribute", attr = "agility", amount = 4},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "message", text = "Ви стали сильнішим, але Всесвіт звужується"}
            }
        }
    },
    {
        id = "bezsmertya",
        word = "Безсмертя",
        description = "Вічне життя, але ціною сприйняття",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 12},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "attribute", attr = "agility", amount = -4},
                {type = "edos", amount = 100}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 8},
                {type = "attribute", attr = "agility", amount = 6},
                {type = "attribute", attr = "will", amount = -6},
                {type = "message", text = "Ви стали мудрішим, але смертним"}
            }
        }
    },
    {
        id = "prozrinnya",
        word = "Прозріння",
        description = "Бачити сутність речей",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 9},
                {type = "attribute", attr = "will", amount = 4},
                {type = "attribute", attr = "strength", amount = -5},
                {type = "edos", amount = 85}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 8},
                {type = "attribute", attr = "agility", amount = 3},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "message", text = "Ви стали сильнішим, але засліпли"}
            }
        }
    },
    {
        id = "nadlyudyna",
        word = "Надлюдина",
        description = "Вихід за межі людського",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 9},
                {type = "attribute", attr = "agility", amount = 5},
                {type = "attribute", attr = "mind", amount = -6},
                {type = "edos", amount = 90}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 8},
                {type = "attribute", attr = "will", amount = 5},
                {type = "attribute", attr = "strength", amount = -6},
                {type = "message", text = "Ви стали мудрішим, але лишились людиною"}
            }
        }
    },
    {
        id = "hronospid",
        word = "Хроноспід",
        description = "Прискорення власного часу",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "speed", amount = 0.8},
                {type = "attribute", attr = "agility", amount = 6},
                {type = "attribute", attr = "mind", amount = -4},
                {type = "edos", amount = 80}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 7},
                {type = "attribute", attr = "will", amount = 4},
                {type = "attribute", attr = "speed", amount = -0.5},
                {type = "message", text = "Ви стали мудрішим, але час сповільнився"}
            }
        }
    },
    {
        id = "arkhitektura",
        word = "Архітектура",
        description = "Мистецтво будувати світи",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 7},
                {type = "attribute", attr = "will", amount = 5},
                {type = "attribute", attr = "agility", amount = -5},
                {type = "edos", amount = 85}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 7},
                {type = "attribute", attr = "strength", amount = 4},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "message", text = "Ви стали спритнішим, але світи руйнуються"}
            }
        }
    },
    {
        id = "filosofiya",
        word = "Філософія",
        description = "Любов до мудрості",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 8},
                {type = "attribute", attr = "will", amount = 4},
                {type = "attribute", attr = "strength", amount = -4},
                {type = "edos", amount = 80}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 6},
                {type = "attribute", attr = "agility", amount = 4},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "message", text = "Ви стали сильнішим, але мудрість втрачена"}
            }
        }
    },
    {
        id = "teurhiya",
        word = "Теургія",
        description = "Божественна магія",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 180,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 6},
                {type = "attribute", attr = "will", amount = 6},
                {type = "attribute", attr = "agility", amount = -5},
                {type = "edos", amount = 90}
            },
            reject = {
                {type = "attribute", attr = "agility", amount = 7},
                {type = "attribute", attr = "speed", amount = 0.4},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "attribute", attr = "will", amount = -3},
                {type = "message", text = "Ви стали швидшим, але боги відвернулись"}
            }
        }
    },
    
    -- РІВЕНЬ 5 (Легендарні слова)
    {
        id = "apokalipsys",
        word = "Апокаліпсис",
        description = "Кінець всього, але й новий початок",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 15},
                {type = "attribute", attr = "mind", amount = 10},
                {type = "attribute", attr = "strength", amount = -8},
                {type = "attribute", attr = "agility", amount = -7},
                {type = "edos", amount = 200}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 12},
                {type = "attribute", attr = "agility", amount = 10},
                {type = "attribute", attr = "mind", amount = -8},
                {type = "attribute", attr = "will", amount = -7},
                {type = "message", text = "Ви вижили, але світ навколо гине"}
            }
        }
    },
    {
        id = "transtsendentnist",
        word = "Трансцендентність",
        description = "Буття поза межами реальності",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 18},
                {type = "attribute", attr = "will", amount = 12},
                {type = "attribute", attr = "strength", amount = -10},
                {type = "attribute", attr = "agility", amount = -8},
                {type = "edos", amount = 250}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 14},
                {type = "attribute", attr = "agility", amount = 12},
                {type = "attribute", attr = "speed", amount = 0.6},
                {type = "attribute", attr = "mind", amount = -10},
                {type = "message", text = "Ви лишились в реальності, але вона тісна"}
            }
        }
    },
    {
        id = "omnipotentsiya",
        word = "Омніпотенція",
        description = "Всемогутність, що обмежує",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 20},
                {type = "attribute", attr = "will", amount = 15},
                {type = "attribute", attr = "mind", amount = -12},
                {type = "attribute", attr = "agility", amount = -10},
                {type = "edos", amount = 300}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 18},
                {type = "attribute", attr = "agility", amount = 14},
                {type = "attribute", attr = "strength", amount = -12},
                {type = "attribute", attr = "will", amount = -8},
                {type = "message", text = "Ви стали мудрішим, але всемогутність втрачена"}
            }
        }
    },
    {
        id = "absolyutna_volya",
        word = "Абсолютна воля",
        description = "Воля, що ламає реальність",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 22},
                {type = "attribute", attr = "mind", amount = 8},
                {type = "attribute", attr = "strength", amount = -12},
                {type = "attribute", attr = "agility", amount = -10},
                {type = "edos", amount = 280}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 16},
                {type = "attribute", attr = "agility", amount = 14},
                {type = "attribute", attr = "speed", amount = 0.8},
                {type = "attribute", attr = "will", amount = -12},
                {type = "message", text = "Ви стали сильнішим, але воля зламана"}
            }
        }
    },
    {
        id = "kosmichna_svidomist",
        word = "Космічна свідомість",
        description = "Єдність з всесвітом",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 20},
                {type = "attribute", attr = "will", amount = 10},
                {type = "attribute", attr = "strength", amount = -10},
                {type = "attribute", attr = "agility", amount = -8},
                {type = "edos", amount = 270}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 14},
                {type = "attribute", attr = "agility", amount = 12},
                {type = "attribute", attr = "speed", amount = 0.7},
                {type = "attribute", attr = "mind", amount = -10},
                {type = "message", text = "Ви стали могутнішим, але космос мовчить"}
            }
        }
    },
    {
        id = "panta_rei",
        word = "Панта рей",
        description = "Все тече, все змінюється",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "agility", amount = 15},
                {type = "attribute", attr = "speed", amount = 1.0},
                {type = "attribute", attr = "mind", amount = -10},
                {type = "attribute", attr = "will", amount = -8},
                {type = "edos", amount = 250}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = 16},
                {type = "attribute", attr = "will", amount = 12},
                {type = "attribute", attr = "agility", amount = -10},
                {type = "attribute", attr = "speed", amount = -0.6},
                {type = "message", text = "Ви стали мудрішим, але застигли"}
            }
        }
    },
    {
        id = "metamorfoza",
        word = "Метаморфоза",
        description = "Повне перетворення",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "agility", amount = 14},
                {type = "attribute", attr = "mind", amount = 10},
                {type = "attribute", attr = "strength", amount = -8},
                {type = "attribute", attr = "will", amount = -8},
                {type = "edos", amount = 260}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 15},
                {type = "attribute", attr = "will", amount = 12},
                {type = "attribute", attr = "agility", amount = -10},
                {type = "attribute", attr = "mind", amount = -8},
                {type = "message", text = "Ви стали сильнішим, але незмінним"}
            }
        }
    },
    {
        id = "katarzys",
        word = "Катарсис",
        description = "Очищення через страждання",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 18},
                {type = "attribute", attr = "mind", amount = 12},
                {type = "attribute", attr = "strength", amount = -10},
                {type = "attribute", attr = "agility", amount = -8},
                {type = "edos", amount = 280}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 14},
                {type = "attribute", attr = "agility", amount = 12},
                {type = "attribute", attr = "speed", amount = 0.6},
                {type = "attribute", attr = "will", amount = -10},
                {type = "attribute", attr = "mind", amount = -5},
                {type = "message", text = "Ви уникли страждань, але й очищення"}
            }
        }
    },
    {
        id = "noosfera",
        word = "Ноосфера",
        description = "Сфера розуму",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 22},
                {type = "attribute", attr = "will", amount = 8},
                {type = "attribute", attr = "strength", amount = -12},
                {type = "attribute", attr = "agility", amount = -8},
                {type = "edos", amount = 290}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = 16},
                {type = "attribute", attr = "agility", amount = 12},
                {type = "attribute", attr = "speed", amount = 0.7},
                {type = "attribute", attr = "mind", amount = -12},
                {type = "message", text = "Ви стали могутнішим, але розум затьмарений"}
            }
        }
    },
    {
        id = "uvaga",
        word = "Увага",
        description = "Пильність та спостережливість",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 1},
                {type = "edos", amount = 3}
            },
            reject = {
                {type = "effect", effect = "blindness", duration = 5},
                {type = "message", text = "Ви втратили пильність"}
            }
        }
    },
    {
        id = "kydok",
        word = "Кидок",
        description = "Сила метання",
        level = 1,
        rarity = "common",
        glow = 5,
        research_time = 30,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 1}
            },
            reject = {
                {type = "damage", amount = 1},
                {type = "message", text = "Ви невдало кинули камінь"}
            }
        }
    },
    
    -- Рівень 2 (середні слова)
    {
        id = "mudrist",
        word = "Мудрість",
        description = "Давнє знання",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 3},
                {type = "edos", amount = 15}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = -1},
                {type = "message", text = "Ви забули важливе"}
            }
        }
    },
    {
        id = "stiikist",
        word = "Стійкість",
        description = "Непохитність духу",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 3},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "effect", effect = "slowness", duration = 10},
                {type = "message", text = "Ви похитнулися"}
            }
        }
    },
    {
        id = "mogutnist",
        word = "Могутність",
        description = "Велика сила",
        level = 2,
        rarity = "uncommon",
        glow = 8,
        research_time = 60,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 3},
                {type = "edos", amount = 10}
            },
            reject = {
                {type = "damage", amount = 3},
                {type = "message", text = "Сила покинула вас"}
            }
        }
    },
    
    -- Рівень 3 (складні слова)
    {
        id = "geniy",
        word = "Геній",
        description = "Вищий розум",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 120,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 5},
                {type = "edos", amount = 30}
            },
            reject = {
                {type = "attribute", attr = "mind", amount = -2},
                {type = "message", text = "Ви втратили геніальність"}
            }
        }
    },
    {
        id = "titan",
        word = "Титан",
        description = "Сила велетня",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 120,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 5},
                {type = "edos", amount = 25}
            },
            reject = {
                {type = "attribute", attr = "strength", amount = -2},
                {type = "message", text = "Ви стали кволішим"}
            }
        }
    },
    {
        id = "legenda",
        word = "Легенда",
        description = "Безсмертна слава",
        level = 3,
        rarity = "rare",
        glow = 11,
        research_time = 120,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 5},
                {type = "edos", amount = 20}
            },
            reject = {
                {type = "attribute", attr = "will", amount = -2},
                {type = "message", text = "Про вас забудуть"}
            }
        }
    },
    
    -- Рівень 4 (епічні слова)
    {
        id = "bezsmertya",
        word = "Безсмертя",
        description = "Вічне життя",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "will", amount = 10},
                {type = "attribute", attr = "mind", amount = 5},
                {type = "edos", amount = 100}
            },
            reject = {
                {type = "effect", effect = "wither", duration = 20},
                {type = "message", text = "Смерть дивиться на вас"}
            }
        }
    },
    {
        id = "vsevladdya",
        word = "Всевладдя",
        description = "Абсолютна сила",
        level = 4,
        rarity = "epic",
        glow = 14,
        research_time = 300,
        rewards = {
            accept = {
                {type = "attribute", attr = "strength", amount = 10},
                {type = "attribute", attr = "will", amount = 5},
                {type = "edos", amount = 80}
            },
            reject = {
                {type = "damage", amount = 10},
                {type = "message", text = "Сила розчавила вас"}
            }
        }
    },
    
    -- Рівень 5 (легендарні слова)
    {
        id = "absolut",
        word = "Абсолют",
        description = "Поза межами реальності",
        level = 5,
        rarity = "legendary",
        glow = 16,
        research_time = 600,
        rewards = {
            accept = {
                {type = "attribute", attr = "mind", amount = 50},
                {type = "attribute", attr = "strength", amount = 90},
                {type = "attribute", attr = "will", amount = 40},
                {type = "edos", amount = 1000}
            },
            reject = {
                {type = "effect", effect = "void", duration = 30},
                {type = "message", text = "Реальність руйнується"}
            }
        }
    }
}

-- ============================================
-- words.lua - Система слів з вибором при підвищенні рівня
-- ============================================

-- ТАБЛИЦЯ СЛІВ (яку ти хочеш залишити)
-- Встав сюди свою таблицю WORDS_DATABASE

-- Глобальна таблиця атрибутів гравців
local player_attributes = {}

-- Ініціалізація атрибутів гравця
local function init_player_attributes(player_name)
    if not player_attributes[player_name] then
        player_attributes[player_name] = {
            mind = 0,
            strength = 0,
            will = 0,
            speed = 1.0,
            health_bonus = 0,
            damage_bonus = 0
        }
    end
    return player_attributes[player_name]
end

-- Додавання атрибуту
local function add_attribute(player_name, attr, amount)
    local attrs = init_player_attributes(player_name)
    attrs[attr] = (attrs[attr] or 0) + amount
    
    local player = minetest.get_player_by_name(player_name)
    if player then
        if attr == "speed" then
            player:set_physics_override({speed = attrs.speed})
        elseif attr == "strength" then
            attrs.damage_bonus = attrs.strength * 0.1
        elseif attr == "will" then
            attrs.health_bonus = attrs.will * 0.5
        end
    end
    
    local data = get_player_data(player_name)
    data.attributes = attrs
    save_fortress_data()
end

-- Отримання випадкового слова
local function get_random_word(player_name, max_level, exclude_ids)
    local data = get_player_data(player_name)
    data.words = data.words or {}
    exclude_ids = exclude_ids or {}
    
    local available_words = {}
    for _, word in ipairs(WORDS_DATABASE) do
        if word.level <= max_level and not data.words[word.id] then
            local excluded = false
            for _, id in ipairs(exclude_ids) do
                if id == word.id then
                    excluded = true
                    break
                end
            end
            if not excluded then
                table.insert(available_words, word)
            end
        end
    end
    
    if #available_words == 0 then return nil end
    
    local idx = math.random(1, #available_words)
    return available_words[idx]
end

-- Початок дослідження слова
local function start_research_word(player_name, word_id)
    local data = get_player_data(player_name)
    data.words = data.words or {}
    data.researching = data.researching or {}
    
    local word = nil
    for _, w in ipairs(WORDS_DATABASE) do
        if w.id == word_id then
            word = w
            break
        end
    end
    
    if not word then return false end
    
    data.researching[word_id] = {
        word = word,
        start_time = os.time(),
        end_time = os.time() + word.research_time
    }
    
    save_fortress_data()
    
    minetest.chat_send_player(player_name, "📖 Ви почали досліджувати слово '" .. word.word .. "'... Це займе " .. word.research_time .. " секунд.")
    return true
end

-- ============================================
-- ПЕРЕВІРКА ЗАВЕРШЕННЯ ДОСЛІДЖЕНЬ
-- ============================================

local function check_research_completion(player_name)
    local data = get_player_data(player_name)
    if not data.words then return end
    
    local current_time = os.time()
    local changed = false
    
    for id, word_data in pairs(data.words) do
        -- Якщо слово в стадії дослідження і час вийшов
        if word_data.status == "researching" and word_data.start_time then
            local word = word_data.word
            if current_time >= word_data.start_time + word.research_time then
                word_data.status = "pending"
                word_data.researched = true
                word_data.researched_time = current_time
                changed = true
                
                minetest.chat_send_player(player_name, "✨ Дослідження слова '" .. word.word .. "' завершено! Відкрийте меню слів (кнопка 'Книга').")
            end
        end
    end
    
    if changed then
        save_fortress_data()
    end
end

-- Перевірка кожні 2 секунди
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    
    if timer > 2 then
        for _, player in ipairs(minetest.get_connected_players()) do
            local player_name = player:get_player_name()
            check_research_completion(player_name)
        end
        timer = 0
    end
end)

-- ============================================
-- МЕНЮ ВИБОРУ СЛІВ ПРИ ПІДВИЩЕННІ РІВНЯ
-- ============================================

function show_level_up_words(player_name)
    local data = get_player_data(player_name)
    local player_data = human_fortress.edos_data[player_name]
    
    -- Тільки до 50 рівня
    if player_data.level > 50 then
        return
    end
    
    -- Визначаємо максимальний рівень слів на основі рівня гравця
    local max_word_level = math.min(5, math.ceil(player_data.level / 10))
    
    -- Вибираємо 3 випадкові слова
    local options = {}
    local attempts = 0
    local max_attempts = 50 -- Запобігає нескінченному циклу
    
    while #options < 3 and attempts < max_attempts do
        attempts = attempts + 1
        
        -- Отримуємо випадкове слово
        local word = get_random_word(player_name, max_word_level, {})
        
        if word then
            -- Перевіряємо чи слово вже є в options
            local already_in_options = false
            for _, existing in ipairs(options) do
                if existing.id == word.id then
                    already_in_options = true
                    break
                end
            end
            
            -- Перевіряємо чи слово вже вивчене
            local already_learned = data.words and data.words[word.id] and data.words[word.id].status == "accepted"
            
            -- Якщо слово не в options і не вивчене - додаємо
            if not already_in_options and not already_learned then
                table.insert(options, word)
            end
        end
    end
    
    -- Якщо все ще менше 3 - значить немає доступних слів
    if #options == 0 then
        minetest.chat_send_player(player_name, "📖 Немає нових слів для вивчення...")
        return
    end
    
    -- Зберігаємо опції в даних гравця
    data.pending_word_choice = options
    data.pending_word_choice_time = os.time() -- Запам'ятовуємо час створення
    save_fortress_data()
    
    -- Створюємо formspec
    local formspec = "size[8,6]" ..
        "bgcolor[#0A0A1A;true]" ..
        "box[0,0;8,0.8;#2D2D44]" ..
        "label[0.5,0.2;✨ Яке слово ти вибереш сьогодні?]" ..
        "box[0.5,1;7,3.5;#1E1E2E]"
    
    local y = 1.3
    for i, word in ipairs(options) do
        local rarity_color = "#C0C0C0"
        if word.rarity == "uncommon" then rarity_color = "#00FF00"
        elseif word.rarity == "rare" then rarity_color = "#0000FF"
        elseif word.rarity == "epic" then rarity_color = "#800080"
        elseif word.rarity == "legendary" then rarity_color = "#FF8000" end
        
        formspec = formspec ..
            "box[1," .. y .. ";6,0.8;" .. rarity_color .. "33]" ..
            "label[1.2," .. (y+0.2) .. ";" .. word.word .. " - " .. word.description .. "]" ..
            "button[6," .. y .. ";1,0.8;choose_" .. i .. ";Обрати]"
        y = y + 1
    end
    
    formspec = formspec .. "button[3,5;2,0.8;close;❌ Відмовитись]"
    
    minetest.show_formspec(player_name, "human_fortress:level_up_words", formspec)
end

-- ============================================
-- ЗВИЧАЙНЕ МЕНЮ СЛІВ (КОЛО)
-- ============================================

function show_words_menu(player_name)
    local data = get_player_data(player_name)
    data.words = data.words or {}
    data.attributes = data.attributes or init_player_attributes(player_name)
    
    check_research_completion(player_name)
    
    local attrs = data.attributes
    
    local formspec = "size[14,9]" ..
        "bgcolor[#0A0A1A;true]" ..
        
        "box[0,0;14,0.8;#2D2D44]" ..
        "label[0.5,0.2;📖 СИСТЕМА СЛІВ]" ..
        "label[8,0.2;🧠 Розум: " .. (attrs.mind or 0) .. "]" ..
        "label[10,0.2;💪 Сила: " .. (attrs.strength or 0) .. "]" ..
        "label[12,0.2;🛡️ Воля: " .. (attrs.will or 0) .. "]" ..
        "button[12.5,0.2;1.2,0.5;back;🔙 Назад]" ..
        
        "container[5.5,3]" ..
        "box[0,0;3,3;#2A2A4A]" ..
        "image[0.5,0.5;2,2;human_fortress_player_icon.png]" ..
        "label[0.8,2.5;Ви]" ..
        "container_end[]"
    
    local researched_words = {}
    for id, word_data in pairs(data.words) do
        if word_data.researched and word_data.status == "pending" then
            table.insert(researched_words, {
                id = id,
                word = word_data.word,
                time = word_data.researched_time
            })
        end
    end
    
    table.sort(researched_words, function(a, b)
        return a.time > b.time
    end)
    
    local radius = 3.5
    local center_x = 7
    local center_y = 4.5
    
    for i, word_data in ipairs(researched_words) do
        if i <= 12 then
            local angle = (i - 1) * (2 * math.pi / math.min(#researched_words, 12))
            local x = center_x + math.cos(angle) * radius
            local y = center_y + math.sin(angle) * radius
            
            local word = word_data.word
            local glow_color = "255,215,0"
            
            if word.rarity == "common" then glow_color = "192,192,192"
            elseif word.rarity == "uncommon" then glow_color = "0,255,0"
            elseif word.rarity == "rare" then glow_color = "0,0,255"
            elseif word.rarity == "epic" then glow_color = "128,0,128"
            elseif word.rarity == "legendary" then glow_color = "255,128,0" end
            
            formspec = formspec ..
                "button[" .. (x-1) .. "," .. (y-0.8) .. ";2,1.6;word_" .. word_data.id .. ";" .. word.word .. "]" ..
                "box[" .. (x-1) .. "," .. (y+0.8) .. ";2,0.1;rgba(" .. glow_color .. ",0.8)]" ..
                "label[" .. (x-0.9) .. "," .. (y-0.9) .. ";⚡" .. word.level .. "]"
        end
    end
    
    formspec = formspec ..
        "button[6.5,7.5;1,0.8;words_scroll_left;◀]" ..
        "button[7.5,7.5;1,0.8;words_scroll_right;▶]"
    
    minetest.show_formspec(player_name, "human_fortress:words", formspec)
end

-- ============================================
-- МЕНЮ ВИБОРУ ДЛЯ СЛОВА
-- ============================================

local function show_word_choice_menu(player_name, word_id)
    local data = get_player_data(player_name)
    if not data.words[word_id] then return end
    
    local word = data.words[word_id].word
    
    local formspec = "size[8,6]" ..
        "bgcolor[#0A0A1A;true]" ..
        
        "box[0,0;8,0.8;#2D2D44]" ..
        "label[0.5,0.2;📖 СЛОВО: " .. word.word .. "]" ..
        
        "box[0.5,1;7,3;#1E1E2E]" ..
        "label[1,1.2;'" .. word.word .. "']" ..
        "label[1,1.6;" .. word.description .. "]" ..
        "label[1,2.0;📊 Рівень: " .. word.level .. " | Рідкість: " .. word.rarity .. "]" ..
        
        "label[1,2.6;🎁 ЯКЩО ПРИЙНЯТИ:]"
    
    local y = 3.0
    for _, reward in ipairs(word.rewards.accept) do
        if reward.type == "edos" then
            formspec = formspec .. "label[1," .. y .. ";   • +" .. reward.amount .. " Ейдосів]"
        elseif reward.type == "attribute" then
            local attr_name = "???"
            if reward.attr == "mind" then attr_name = "Розум"
            elseif reward.attr == "strength" then attr_name = "Сила"
            elseif reward.attr == "will" then attr_name = "Воля" end
            formspec = formspec .. "label[1," .. y .. ";   • +" .. reward.amount .. " " .. attr_name .. "]"
        end
        y = y + 0.3
    end
    
    formspec = formspec .. "label[1,4.0;💔 ЯКЩО ВІДМОВИТИСЯ:]"
    y = 4.4
    for _, reward in ipairs(word.rewards.reject) do
        if reward.type == "damage" then
            formspec = formspec .. "label[1," .. y .. ";   • -" .. reward.amount .. " здоров'я]"
        elseif reward.type == "attribute" then
            local attr_name = "???"
            if reward.attr == "mind" then attr_name = "Розум"
            elseif reward.attr == "strength" then attr_name = "Сила"
            elseif reward.attr == "will" then attr_name = "Воля" end
            formspec = formspec .. "label[1," .. y .. ";   • " .. reward.amount .. " " .. attr_name .. "]"
        elseif reward.type == "effect" then
            formspec = formspec .. "label[1," .. y .. ";   • Ефект: " .. reward.effect .. " (" .. reward.duration .. "с)]"
        elseif reward.type == "message" then
            formspec = formspec .. "label[1," .. y .. ";   • " .. reward.text .. "]"
        end
        y = y + 0.3
    end
    
    formspec = formspec ..
        "button[1.5,5.2;2,0.8;accept_word;✅ ПРИЙНЯТИ]" ..
        "button[4.5,5.2;2,0.8;reject_word;❌ ВІДМОВИТИСЯ]"
    
    local context = data
    context.pending_word_id = word_id
    save_fortress_data()
    
    minetest.show_formspec(player_name, "human_fortress:word_choice", formspec)
end

-- ============================================
-- ДОПОМІЖНІ ФУНКЦІЇ
-- ============================================

-- Обробка прийняття слова
local function accept_word(player_name, word_id)
    local data = get_player_data(player_name)
    if not data.words[word_id] then return false end
    
    local word = data.words[word_id].word
    
    for _, reward in ipairs(word.rewards.accept) do
        if reward.type == "edos" then
            -- add_resources(player_name, "score", reward.amount)
            minetest.chat_send_player(player_name, "💰 +" .. reward.amount .. " Ейдосів!")
        elseif reward.type == "attribute" then
            add_attribute(player_name, reward.attr, reward.amount)
            minetest.chat_send_player(player_name, "✨ +" .. reward.amount .. " " .. reward.attr .. "!")
        end
    end
    
    data.words[word_id].status = "accepted"
    save_fortress_data()
    
    return true
end

-- Обробка відмови від слова
local function reject_word(player_name, word_id)
    local data = get_player_data(player_name)
    if not data.words[word_id] then return false end
    
    local word = data.words[word_id].word
    local player = minetest.get_player_by_name(player_name)
    
    for _, reward in ipairs(word.rewards.reject) do
        if reward.type == "damage" then
            if player then
                local hp = player:get_hp()
                player:set_hp(math.max(1, hp - reward.amount))
                minetest.chat_send_player(player_name, "💔 Ви отримали " .. reward.amount .. " шкоди!")
            end
        elseif reward.type == "attribute" then
            add_attribute(player_name, reward.attr, reward.amount)
            minetest.chat_send_player(player_name, "💔 " .. reward.amount .. " " .. reward.attr .. "!")
        elseif reward.type == "effect" then
            minetest.chat_send_player(player_name, "💔 Ефект: " .. reward.effect)
        elseif reward.type == "message" then
            minetest.chat_send_player(player_name, "💔 " .. reward.text)
        end
    end
    
    data.words[word_id].status = "rejected"
    save_fortress_data()
    
    return true
end

-- Система випадкового отримання слів
local function try_grant_random_word(player)
    if not player or not player:is_player() then return end
    
    local player_name = player:get_player_name()
    local data = get_player_data(player_name)
    
    local max_level = 1
    if data.upgrades then
        if data.upgrades.cathedral then max_level = 5
        elseif data.upgrades.magic_tower then max_level = 4
        elseif data.upgrades.blacksmith then max_level = 3
        elseif data.upgrades.barracks then max_level = 2 end
    end
    
    if math.random() < 0.05 then
        local word = get_random_word(player_name, max_level)
        if word then
            start_research_word(player_name, word.id)
        end
    end
end

-- Тригери для отримання слів
minetest.register_on_player_hpchange(function(player, hp_change)
    if hp_change < 0 then
        minetest.after(0.1, function()
            try_grant_random_word(player)
        end)
    end
    return hp_change
end, true)

minetest.register_on_dignode(function(pos, oldnode, digger)
    if digger and digger:is_player() then
        try_grant_random_word(digger)
    end
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode)
    if placer and placer:is_player() then
        try_grant_random_word(placer)
    end
end)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
    if player and player:is_player() then
        try_grant_random_word(player)
    end
end)

-- ============================================
-- ОСНОВНИЙ ОБРОБНИК ФОРМ (ОДИН!)
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    
    -- Обробник вибору слів при підвищенні рівня
    if formname == "human_fortress:level_up_words" then
        local data = get_player_data(name)
        
        if not data or not data.pending_word_choice then
            return true
        end
        
        -- Перевіряємо чи вибрали слово
        for i = 1, 3 do
            if fields["choose_" .. i] then
                local chosen = data.pending_word_choice[i]
                if chosen then
                    -- Перевіряємо чи слово ще не вивчене
                    if not data.words then data.words = {} end
                    
                    -- Додаємо слово в дослідження
                    data.words[chosen.id] = {
                        word = chosen,
                        researched = false,
                        status = "researching",
                        start_time = os.time()
                    }
                    
                    minetest.chat_send_player(name, "§G[СЛОВО]§F Ти обрав: §E" .. chosen.word .. "§F - " .. chosen.description)
                    minetest.chat_send_player(name, "📖 Дослідження розпочато! Воно триватиме " .. chosen.research_time .. " секунд.")
                    minetest.sound_play("default_tool_breaks", {to_player = name, gain = 1.0})
                    
                    -- Очищаємо вибір
                    data.pending_word_choice = nil
                    save_fortress_data()
                    
                    -- Оновлюємо GUI
                    if human_fortress.update_gui then
                        human_fortress.update_gui(player)
                    end
                    
                    return true
                end
            end
        end
        
        -- Якщо закрили без вибору або відмовились
        if fields.close or fields.quit then
            data.pending_word_choice = nil
            save_fortress_data()
            
            minetest.chat_send_player(name, "§7[СЛОВО]§F Ти відмовився від вибору...")
            
            if human_fortress.update_gui then
                human_fortress.update_gui(player)
            end
            return true
        end
        
        return true
    end
    
    -- ЗВИЧАЙНЕ МЕНЮ СЛІВ
    if formname == "human_fortress:words" then
        local player_name = player:get_player_name()
        
        if fields.back then
            if show_vilka_menu then
                show_vilka_menu(player_name)
            end
            return true
        end
        
        if fields.words_scroll_left or fields.words_scroll_right then
            show_words_menu(player_name)
            return true
        end
        
        for field, _ in pairs(fields) do
            if string.sub(field, 1, 5) == "word_" then
                local word_id = string.sub(field, 6)
                show_word_choice_menu(player_name, word_id)
                return true
            end
        end
        
        return true
    end
    
    -- МЕНЮ ВИБОРУ ДЛЯ СЛОВА
    if formname == "human_fortress:word_choice" then
        local player_name = player:get_player_name()
        local data = get_player_data(player_name)
        local word_id = data.pending_word_id
        
        if fields.accept_word then
            accept_word(player_name, word_id)
            show_words_menu(player_name)
            return true
        elseif fields.reject_word then
            reject_word(player_name, word_id)
            show_words_menu(player_name)
            return true
        end
        
        return true
    end
    
    return false
end)

-- ФУНКЦІЯ, ЯКУ ТРЕБА ВИКЛИКАТИ ПРИ ПІДВИЩЕННІ РІВНЯ
function human_fortress.on_level_up(player_name)
    local player_data = human_fortress.edos_data[player_name]
    if not player_data then return end
    
    -- Тільки до 50 рівня
    if player_data.level <= 50 then
        show_level_up_words(player_name)
    end
end

-- Ініціалізація для гравця
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    init_player_attributes(player_name)
    
    minetest.after(5, function()
        if player and player:is_player() then
            try_grant_random_word(player)
        end
    end)
end)

print("[Human Fortress] Words system loaded with level-up word selection")