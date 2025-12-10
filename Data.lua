local addonName, addon = ...

-- Table of Vanilla WoW Dungeons
-- Key: Instance ID (number)
-- Value: Table with Name, Level, Boss List (Guaranteed), and Rares List (Rare Spawns)
addon.DungeonData = {
    [389] = {
        name = "Ragefire Chasm",
        level = 13,
        bosses = {
            "Taragaman the Hungerer",
            "Bazzalan",
            "Jergosh the Invoker"
        },
        rares = {
            "Oggleflint" -- True Rare
        }
    },
    [43] = {
        name = "Wailing Caverns",
        level = 17,
        bosses = {
            "Lady Anacondra",
            "Lord Cobrahn",
            "Kresh", -- Fixed spawn (roaming)
            "Lord Pythas",
            "Skum", -- Fixed spawn (optional)
            "Lord Serpentis",
            "Verdan the Everliving",
            "Mutanus the Devourer"
        },
        rares = {
            "Deviate Faerie Dragon" -- True Rare
        }
    },
    [36] = {
        name = "The Deadmines",
        level = 17,
        bosses = {
            "Rhahk'Zor",
            "Sneed",
            "Gilnid",
            "Mr. Smite",
            "Cookie",
            "Captain Greenskin",
            "Edwin VanCleef"
        },
        rares = {
            "Miner Johnson" -- True Rare
        }
    },
    [33] = {
        name = "Shadowfang Keep",
        level = 22,
        bosses = {
            "Rethilgore",
            "Razorclaw the Butcher",
            "Baron Silverlaine",
            "Commander Springvale",
            "Odo the Blindwatcher",
            "Fenrus the Devourer",
            "Wolf Master Nandos",
            "Archmage Arugal"
        },
        rares = {
            "Deathsworn Captain" -- True Rare (Spawns on battlements)
        }
    },
    [48] = {
        name = "Blackfathom Deeps",
        level = 24,
        bosses = {
            "Ghamoo-ra",
            "Lady Sarevess",
            "Gelihast",
            "Lorgus Jett",
            "Old Serra'kis", -- Added (Guaranteed spawn)
            "Twilight Lord Kelris",
            "Aku'mai"
        },
        rares = {
            "Baron Aquanis" -- From quest summoning (Rare Elite classification)
        }
    },
    [34] = {
        name = "The Stockade",
        level = 24,
        bosses = {
            "Targorr the Dread",
            "Kam Deepfury",
            "Hamhock",
            "Bazil Thredd",
            "Dextren Ward"
        },
        rares = {
            "Bruegal Ironknuckle" -- True Rare
        }
    },
    [90] = {
        name = "Gnomeregan",
        level = 29,
        bosses = {
            "Grubbis",
            "Viscous Fallout",
            "Electrocutioner 6000",
            "Crowd Pummeler 9-60",
            "Mekgineer Thermaplugg"
        },
        rares = {
            "Dark Iron Ambassador" -- True Rare
        }
    },
    [47] = {
        name = "Razorfen Kraul",
        level = 29,
        bosses = {
            "Roogug",
            "Aggem Thorncurse",
            "Death Speaker Jargba",
            "Overlord Ramtusk",
            "Agathelos the Raging",
            "Charlga Razorflank"
        },
        rares = {
            "Blind Hunter", -- True Rare
            "Earthcaller Halmgar" -- True Rare
        }
    },
    [189] = {
        name = "Scarlet Monastery",
        level = 30,
        bosses = {
            "Interrogator Vishas",
            "Bloodmage Thalnos", -- Graveyard End
            "Houndmaster Loksey",
            "Arcanist Doan", -- Library End
            "Herod", -- Armory End
            "High Inquisitor Fairbanks",
            "Scarlet Commander Mograine",
            "High Priestess Whitemane" -- Cathedral End
        },
        rares = {
            "Ironspine", -- Graveyard Rare
            "Azshir the Sleepless", -- Graveyard Rare
            "Fallen Champion" -- Graveyard Rare
        }
    },
    [129] = {
        name = "Razorfen Downs",
        level = 37,
        bosses = {
            "Tuten'kash",
            "Mordresh Fire Eye",
            "Glutton",
            "Ragglesnout",
            "Plaguemaw the Rotting", -- Added (Guaranteed)
            "Amnennar the Coldbringer"
        }
    },
    [70] = {
        name = "Uldaman",
        level = 41,
        bosses = {
            "Revelosh",
            "Ironaya",
            "Obsidian Sentinel",
            "Ancient Stone Keeper", -- Added (Guaranteed)
            "Galgann Firehammer",
            "Grimlok",
            "Baelog", -- Added (Guaranteed)
            "Archaedas"
        },
        rares = {
            "Digmaster Shovelphlange" -- True Rare
        }
    },
    [209] = {
        name = "Zul'Farrak",
        level = 44,
        bosses = {
            "Antu'sul",
            "Theka the Martyr",
            "Witch Doctor Zum'rah",
            "Nekrum Gutchewer",
            "Shadowpriest Sezz'ziz",
            "Chief Ukorz Sandscalp",
            "Gahz'rilla"
        },
        rares = {
            "Zerillis", -- True Rare
            "Dustwraith" -- True Rare
        }
    },
    [349] = {
        name = "Maraudon",
        level = 46,
        bosses = {
            "Noxxion",
            "Razorlash",
            "Lord Vyletongue",
            "Celebras the Cursed",
            "Landslide",
            "Tinkerer Gizlock",
            "Rotgrip",
            "Princess Theradras"
        },
        rares = {
            "Meshlok the Harvester" -- True Rare
        }
    },
    [109] = {
        name = "The Sunken Temple",
        level = 50,
        bosses = {
            "Atal'alarion",
            "Jammal'an the Prophet",
            "Ogom the Wretched",
            "Morphaz",
            "Hazzas",
            "Dreamscythe",
            "Weaver",
            "Avatar of Hakkar",
            "Shade of Eranikus"
        }
    },
    [230] = {
        name = "Blackrock Depths",
        level = 52,
        bosses = {
            "High Interrogator Gerstahn",
            "Lord Roccor",
            "Houndmaster Grebmar",
            "Bael'Gar",
            "Lord Incendius",
            "Warder Stilgiss",
            "Fineous Darkvire",
            "General Angerforge",
            "Golem Lord Argelmach",
            "Hurley Blackbreath",
            "Phalanx",
            "Ribbly Screwspigot",
            "Plugger Spazzring",
            "Ambassador Flamelash",
            "The Seven",
            "Magmus",
            "Emperor Dagran Thaurissan",
            "Princess Moira Bronzebeard"
        },
        rares = {
            "Panzor the Invincible", -- True Rare
            "Pyromancer Loregrain" -- Moved to Rare (Rare Elite classification)
        }
    },
    [429] = {
        name = "Dire Maul",
        level = 55,
        bosses = {
            -- East
            "Pusillin",
            "Zevrim Thornhoof",
            "Hydrospawn",
            "Lethtendris",
            "Alzzin the Wildshaper",
            -- West
            "Tendris Warpwood",
            "Illyanna Ravenoak",
            "Magister Kalendris",
            "Immol'thar",
            "Prince Tortheldrin",
            -- North
            "Guard Mol'dar",
            "Stomper Kreeg",
            "Guard Fengus",
            "Guard Slip'kik",
            "Captain Kromcrush",
            "King Gordok"
        },
        rares = {
            "Mushgog", -- DM East Rare
            "Skarr the Unbroken", -- DM West Rare (Added)
            "Tsu'zee" -- DM North Rare
        }
    },
    [229] = {
        name = "Blackrock Spire",
        level = 55,
        bosses = {
            -- LBRS
            "Highlord Omokk",
            "Shadow Hunter Vosh'gajin",
            "War Master Voone",
            "Mother Smolderweb",
            "Urok Doomhowl",
            "Quartermaster Zigris",
            "Halycon",
            "Gizrul the Slavener",
            "Overlord Wyrmthalak",
            -- UBRS
            "Pyroguard Emberseer",
            "Solakar Flamewreath",
            "Goraluk Anvilcrack",
            "Gyth",
            "Warchief Rend Blackhand",
            "The Beast",
            "General Drakkisath"
        },
        rares = {
            "Jed Runewatcher", -- True Rare (UBRS)
            "Bannok Grimaxe", -- True Rare (LBRS)
            "Crystal Fang", -- True Rare (LBRS)
            "Spirestone Butcher" -- True Rare (LBRS)
        }
    },
    [289] = {
        name = "Scholomance",
        level = 58,
        bosses = {
            "Kirtonos the Herald",
            "Jandice Barov",
            "Rattlegore",
            "Marduk Blackpool",
            "Vectus",
            "Ras Frostwhisper",
            "Instructor Malicia",
            "Doctor Theolen Krastinov",
            "Lorekeeper Polkelt",
            "The Ravenian",
            "Lord Alexei Barov",
            "Lady Illucia Barov",
            "Darkmaster Gandling"
        }
    },
    [329] = {
        name = "Stratholme",
        level = 58,
        bosses = {
            "Baroness Anastari",
            "Nerub'enkan",
            "Maleki the Pallid",
            "Magistrate Barthilas",
            "Ramstein the Gorger",
            "Baron Rivendare",
            "Timmy the Cruel",
            "Cannon Master Willey",
            "Archivist Galford",
            "Balnazzar"
        },
        rares = {
            "Hearthsinger Forresten", -- True Rare
            "Skul", -- True Rare
            "Stonespine", -- True Rare
            "Ezra Grimm" -- True Rare (Added)
        }
    }
}