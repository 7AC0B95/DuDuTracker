local addonName, addon = ...

-- Table of Vanilla WoW Dungeons
-- Key: Zone Name (GetRealZoneText)
-- Value: Table with ZoneID (optional/best guess), Level (for sorting), and Boss List
addon.DungeonData = {
    ["Ragefire Chasm"] = {
        zoneID = 2437,
        level = 13,
        bosses = {
            "Oggleflint",
            "Taragaman the Hungerer",
            "Bazzalan",
            "Jergosh the Invoker"
        }
    },
    ["Wailing Caverns"] = {
        zoneID = 1417,
        level = 17,
        bosses = {
            "Lady Anacondra",
            "Lord Cobrahn",
            "Lord Pythas",
            "Lord Serpentis",
            "Verdan the Everliving",
            "Mutanus the Devourer",
            "Skum",
            "Kresh"
        }
    },
    ["The Deadmines"] = {
        zoneID = 1581,
        level = 17,
        bosses = {
            "Rhahk'Zor",
            "Sneed",
            "Gilnid",
            "Mr. Smite",
            "Cookie",
            "Captain Greenskin",
            "Edwin VanCleef"
        }
    },
    ["Shadowfang Keep"] = {
        zoneID = 1584,
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
        }
    },
    ["Blackfathom Deeps"] = {
        zoneID = 1582,
        level = 24,
        bosses = {
            "Ghamoo-ra",
            "Lady Sarevess",
            "Gelihast",
            "Lorgus Jett",
            "Baron Aquanis",
            "Twilight Lord Kelris",
            "Aku'mai"
        }
    },
    ["The Stockade"] = {
        zoneID = 1583,
        level = 24,
        bosses = {
            "Targorr the Dread",
            "Kam Deepfury",
            "Hamhock",
            "Bazil Thredd",
            "Dextren Ward",
            "Bruegal Ironknuckle"
        }
    },
    ["Gnomeregan"] = {
        zoneID = 1477,
        level = 29,
        bosses = {
            "Grubbis",
            "Viscous Fallout",
            "Electrocutioner 6000",
            "Crowd Pummeler 9-60",
            "Mekgineer Thermaplugg"
        }
    },
    ["Razorfen Kraul"] = {
        zoneID = 2437, -- Check ID
        level = 29,
        bosses = {
            "Roogug",
            "Aggem Thorncurse",
            "Death Speaker Jargba",
            "Overlord Ramtusk",
            "Agathelos the Raging",
            "Blind Hunter",
            "Charlga Razorflank"
        }
    },
    ["Razorfen Downs"] = {
        zoneID = 1581, -- Check ID
        level = 37,
        bosses = {
            "Tuten'kash",
            "Mordresh Fire Eye",
            "Glutton",
            "Ragglesnout",
            "Amnennar the Coldbringer"
        }
    },
    ["Scarlet Monastery"] = {
        zoneID = 1581, -- SM has 4 wings, usually detected as subzones or same map
        level = 30,
        bosses = {
            -- Graveyard
            "Interrogator Vishas",
            "Bloodmage Thalnos",
            -- Library
            "Houndmaster Loksey",
            "Arcanist Doan",
            -- Armory
            "Herod",
            -- Cathedral
            "High Inquisitor Fairbanks",
            "Scarlet Commander Mograine",
            "High Priestess Whitemane"
        }
    },
    ["Uldaman"] = {
        zoneID = 1581,
        level = 41,
        bosses = {
            "Revelosh",
            "Ironaya",
            "Obsidian Sentinel",
            "Galgann Firehammer",
            "Grimlok",
            "Archaedas"
        }
    },
    ["Zul'Farrak"] = {
        zoneID = 1581,
        level = 44,
        bosses = {
            "Antu'sul",
            "Theka the Martyr",
            "Witch Doctor Zum'rah",
            "Nekrum Gutchewer",
            "Shadowpriest Sezz'ziz",
            "Chief Ukorz Sandscalp",
            "Gahz'rilla"
        }
    },
    ["Maraudon"] = {
        zoneID = 1581,
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
        }
    },
    ["Sunken Temple"] = {
        zoneID = 1581,
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
    ["Blackrock Depths"] = {
        zoneID = 1581,
        level = 52,
        bosses = {
            "High Interrogator Gerstahn",
            "Lord Roccor",
            "Houndmaster Grebmar",
            "Bael'Gar",
            "Lord Incendius",
            "Warder Stilgiss",
            "Fineous Darkvire",
            "Pyromancer Loregrain",
            "General Angerforge",
            "Golem Lord Argelmach",
            "Hurley Blackbreath",
            "Phalanx",
            "Ribbly Screwspigot",
            "Plugger Spazzring",
            "Ambassador Flamelash",
            "The Seven", -- Special encounter
            "Magmus",
            "Emperor Dagran Thaurissan",
            "Princess Moira Bronzebeard"
        }
    },
    ["Lower Blackrock Spire"] = {
        zoneID = 1581,
        level = 55,
        bosses = {
            "Highlord Omokk",
            "Shadow Hunter Vosh'gajin",
            "War Master Voone",
            "Mother Smolderweb",
            "Urok Doomhowl",
            "Quartermaster Zigris",
            "Halycon",
            "Gizrul the Slavener",
            "Overlord Wyrmthalak"
        }
    },
    ["Upper Blackrock Spire"] = {
        zoneID = 1581,
        level = 58,
        bosses = {
            "Pyroguard Emberseer",
            "Solakar Flamewreath",
            "Goraluk Anvilcrack",
            "Jed Runewatcher",
            "Gyth",
            "Warchief Rend Blackhand",
            "The Beast",
            "General Drakkisath"
        }
    },
    ["Scholomance"] = {
        zoneID = 1581,
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
    ["Stratholme"] = {
        zoneID = 1581,
        level = 58,
        bosses = {
            -- Undead
            "Baroness Anastari",
            "Nerub'enkan",
            "Maleki the Pallid",
            "Magistrate Barthilas",
            "Ramstein the Gorger",
            "Baron Rivendare",
            -- Living
            "Timmy the Cruel",
            "Cannon Master Willey",
            "Archivist Galford",
            "Balnazzar"
        }
    },
    ["Dire Maul"] = {
        zoneID = 1581,
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
        }
    }
}
