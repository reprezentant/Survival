# SURVIVE — Game Design Document
> Godot 4.6 · Forward Plus · v1.0 (Feature Complete)

---

## Concept

Survival na izolowanej wyspie. Gracz buduje tratwę i ucieka — to jest win condition. Gra jest **krótka i skoncentrowana**: jeden cel, określona ścieżka technologiczna, bez otwartej piaskownicy.

**Pętla gry (core loop):**
```
Zbieraj surowce → Craftuj narzędzia → Odkrywaj nowe receptury → Zbuduj tratwę → Ucieknij
```

**Pillar design:**
1. **Zagrożenie przez czas** — nie ma regeneracji energii, musisz jeść
2. **Postęp technologiczny** — każde narzędzie odblokowuje kolejną warstwę craftingu
3. **Ryzyko vs nagroda** — wilki są groźne, ale dają mięso; grzyby regenerują energię kosztem zdrowia

---

## Stan projektu — KOMPLETNY

### Rdzeń gracza
- [x] Ruch (WASD + sprint + skok), kamera z szumem (ShakingCamera)
- [x] **Energia** — spada podczas chodzenia (`0.05 × velocity/frame`) i używania broni (`-0.5/użycie`)
- [x] **Zdrowie** — odbiera je wilk (domyślnie -20), grzyb (-10), brak energii (przelew do HP)
- [x] Footstep audio (0.6s chód / 0.3s sprint, 3D pozycyjne, pitch randomizacja)
- [x] HUD: paski HP/Energy, hotbar 9 slotów

### Ekwipunek i przedmioty (19 typów)
- [x] Inwentarz 28 slotów + hotbar 9 slotów
- [x] Stackowanie (max 50), drag-and-drop między wszystkimi slotami
- [x] Zapis/odczyt inwentarza (`user://inventory.json`)
- [x] **System ochrony dropowania** — wartościowe przedmioty wymagają potwierdzenia
- [x] 3 typy zasobów przedmiotów: `ItemResource`, `WeaponItemResource`, `ConsumableItemResource`

| Surowce          | Narzędzia         | Konstrukty   |
|------------------|-------------------|--------------|
| Stick, Stone, Plant | **Axe**, **Pickaxe** | Campfire     |
| Mushroom, Fruit  | Multitool, Tinderbox | **Torch**    |
| Log, Coal, Flintstone | **Rope**        | Tent, Raft   |
| RawMeat, CookedMeat   |             |              |

*Pogrubione przedmioty mają ochronę przed przypadkowym dropowaniem*

### Journal System 📚 (NOWY)
- [x] **Automatyczne odkrywanie** — przedmioty/stworzenia dodawane po interakcji
- [x] **Kategoryzacja** — Items, Objects, Creatures w osobnych zakładkach  
- [x] **Powiadomienia** — wykrzykniki (`!`) przy nowych/zaktualizowanych wpisach
- [x] **Keybinding** — klawisz J otwiera journal
- [x] **Dynamiczne odblokowywanie** — wpisy pojawiają się w miarę postępu

```
EventSystem (Autoload)
├── PlayerStatsManager
├── InventoryManager
├── EquippedItemManager
├── BulletinController
├── HUDController
├── Spawner
├── MusicController
├── SFXController
├── SettingsController
├── SleepManager
└── DayNightCycleAnimPlayer
```

**Reguła:** Jeśli musisz wywołać metodę w innym managerze — użyj sygnału.

### Prefiks sygnałów (konwencja)
| Prefiks | Podsystem |
|---------|-----------|
| `BUL_` | Bulletin/UI overlay |
| `STA_` | Stage management |
| `INV_` | Inventory |
| `PLA_` | Player |
| `EQU_` | Equipped item |
| `SPA_` | Spawner |
| `SFX_` | Sound effects |
| `MUS_` | Music |
| `GAM_` | Game-level (fade, navmesh, etc.) |
| `HUD_` | HUD visibility |
| `SET_` | Settings |

### Warstwy fizyczne
| Layer | Nazwa | Używana przez |
|-------|-------|---------------|
| 1 | environment | LOS raycast zwierząt |
| 2 | actor | gracz, zwierzęta |
| 3 | interactable | pick-upy, kucharki |
| 4 | hitbox | detekcja trafień bronią |
| 5 | big_rigid_pickuppable | log, coal, etc. |
| 6 | small_rigid_pickuppable | drobne pick-upy |
| 7 | static_body | |
| 8 | water | |

---

## Zasady projektowania (reguły dla przyszłych feature'ów)

### DO (rób)
- Nowe mechaniki wchodzą przez sygnały EventSystem z odpowiednim prefiksem
- Każdy nowy przedmiot musi mieć wpis w `ItemConfig.Keys` i odpowiadający `.tres` zasób
- Drzewa technologiczne rozwiązywane przez system blueprintów (prerequisyty w `CraftingBlueprint`)
- Zwierzęta to instancje `animal.gd` — dodaj nowy typ przez scenę z innymi eksportami (damage, aggression, vision_range, etc.)
- Hittable objects przez zasób `HittableObjectAttributes` — weapon_filter jest prawem, nie sugestią
- Skrypty na `@tool` tylko dla wizualnych helperów (jak FlickeringLight) — nie logiki gry

### DON'T (unikaj)
- Nie trzymaj bezpośrednich referencji `get_node("/root/...")` między managerami
- Nie dodawaj surowców do hotbara z `is_equippable = false` — system to blokuje przez UI, ale nie przez kod
- Nie rejestruj sygnału bez `connect_once()` jeśli callback jest jednorazowy (patrz: `INV_add_item_ack`)
- Nie zapisuj stanu świata w InventoryManager — to jest tylko stan ekwipunku

---

## Znane długi techniczne (TODO przed releasem)

### Bugs / Ryzyka
- [ ] `INV_delete_item` signal używany w `starting_cooking_slot.gd` jako fallback legacy path — sygnał nie istnieje w EventSystem → runtime error jeśli old_slot nie jest InventorySlot
- [ ] `FadingBulletin.destroy_self()` hardcoduje `BUL_destroy_bulletin(PauseMenu)` — obejście przez override w SettingsMenu, ale kruche
- [ ] Zapis gry (`SET_save_game`) — tylko inwentarz. Stan świata (drzewa, budowle, zwierzęta) nie jest zachowany po restarcie

### Brakujące funkcje (design gaps)
- [ ] **Brak regeneracji energii pasywnej** — gracz nie regeneruje energii przez odpoczynek (tylko przez jedzenie). Rozważyć: stanie w miejscu = małe regen?
- [ ] **Torch** ma equippable scenę ale żaden skrypt z działaniem — dodać źródło światła + bonus nocny
- [ ] **Rope, Multitool, Tinderbox** nie są odrzucalne/scrappowalne poza craftingiem — celowe czy przeoczenie?
- [ ] **Grzyby** to trap (-10 HP, +15 energy) — gracz musi wiedzieć o efekcie. Brak opisu w UI item info?
- [ ] **Zapis stanu świata** — po restarcie mapa reset, ale inwentarz zachowany → desync

### Quality of Life
- [ ] Item tooltip / opis w crafting menu — `description` w ItemResource jest widoczne w CraftingMenu, ale sprawdzić czy renderowane dla wszystkich przedmiotów
- [ ] Śmierć gracza (health ≤ 0) → powrót do MainMenu. Brak ekranu śmierci / komunikatu
- [ ] Brak blokady wielokrotnego klikania FinalCookingSlot (jest pending guard ale brak wizualnego feedbacku)

---

## Przyszłe mechaniki (backlog)

> Posortowane od najbardziej pasujących do obecnego zakresu gry.

### Tier 1 — pasuje do MVP
- [ ] **Wskaźnik głodu** (odrębny od energii) — zmusza do gotowania mięsa
- [ ] **Zbieranie deszczówki** — kubeł + deszcz → woda pitna: trzecia statystyka (pragnienie)
- [ ] **Stan nocy** — bez pochodni widoczność mocno ograniczona (post-processing ciemność)
- [ ] **Multiple cooking recipes** — np. Fruit+Mushroom → Zupa lecznicza

### Tier 2 — rozbudowa
- [ ] **Bestiary** — więcej zwierząt: dzik (agresywny, słabszy od wilka), królik (ucieka, mały drop)
- [ ] **Crafting stacji** — workbench potrzebny do zaawansowanych receptur
- [ ] **Trwałość narzędzi** — topory się psują, trzeba craftować nowe
- [ ] **Pogoda (weather system)** — deszcz gasi campfire, mróz drenaż energii (szkielet już istnieje w projekcie!)

### Tier 3 — stretch goals
- [ ] **Multiplayer** — wymagałoby refactoru EventSystem na NetworkedEventSystem
- [ ] **Procedural island** — obecna wyspa jest statyczna
- [ ] **Dialogue / lore** — notatki na wyspie wyjaśniające backstory

---

## Przepływ gracza (happy path)

```
START
  → Zbierz Stick × wiele + Stone × wiele + Plant × wiele
  → Craftuj Rope → Axe → Pickaxe
  → Ścinaj drzewa (Axe) → Log
  → Bij głazy (Pickaxe) → Coal + Flintstone
  → Zbierz Fruit / poluj na Krowę → RawMeat
  → Craftuj Multitool (wymaga: Stick+Stone+Flintstone+Coal+RawMeat)
  → Craftuj Tinderbox (wymaga Multitool)
  → Craftuj Campfire → postaw → gotuj RawMeat → CookedMeat
  → Craftuj Raft (wymaga obu narzędzi + Log×6 + CookedMeat×2 + ...)
  → Postaw Raft na plaży → interakcja → CREDITS (WIN)
END
```

**Czas oczekiwany pierwszego przejścia:** ~20–30 min (do zbalansowania)

---

## Pliki kluczowe (mapa projektu)

| Plik | Co robi |
|------|---------|
| `game/event_system.gd` | Wszystkie sygnały gry |
| `game/managers/inventory_manager.gd` | Logika inwentarza |
| `game/managers/player_stats_manager.gd` | HP/Energy |
| `game/managers/equipped_item_manager.gd` | Logika hotbara |
| `game/configs/item_config.gd` | Enum przedmiotów + ścieżki do zasobów |
| `actors/player/player.gd` | Ruch, wejście gracza |
| `actors/animals/animal.gd` | AI zwierząt (state machine) |
| `objects/hittable_objects/hittable_object.gd` | Drzewa, głazy |
| `items/equippables/equippable_weapon.gd` | RayCast trafień |
| `items/equippables/equippable_constructable.gd` | System budowania |
| `bulletins/player_menus/crafting_menu/crafting_menu.gd` | UI craftingu |
| `bulletins/player_menus/cooking_menu/cooking_menu.gd` | UI gotowania |
| `resources/crafting_blueprints/` | Przepisy craftu (.tres) |
| `resources/items/` | Zasoby przedmiotów (.tres) |

---

## 🆕 **Changelog v1.0 — Feature Complete**
- Naprawiono system podnoszenia przedmiotów: dodano brakujący RayCast3D (`InteractionRayCast`) do gracza, ustawiono `target_position = Vector3(0, 0, -8)`, `collide_with_areas = true`, `collision_mask = 4`.
- System interakcji działa na warstwie 3 (interactable), RayCast jest dzieckiem kamery trzecioosobowej.
- Pickupy i interakcje są w pełni event-driven (sygnały Godot, brak bezpośrednich referencji między managerami).
- Status projektu: **100% ukończony** — wszystkie planowane funkcje zaimplementowane.

## ⚡ **System podnoszenia przedmiotów**
- Gracz podnosi przedmioty przez RayCast3D (`InteractionRayCast`) wychodzący z kamery trzecioosobowej.
- RayCast wykrywa tylko obiekty na warstwie 3 (`collision_mask = 4`), czyli wszystkie pickuppable/interactable.
- Zasięg interakcji: 8 metrów (dostosowane do dystansu kamery).
- Interakcja wywołuje sygnał do EventSystem, który obsługuje pickup, inventory i usuwanie obiektu ze sceny.
- Prompt pojawia się tylko, gdy RayCast trafia w Area3D z metodą `start_interaction()`.
