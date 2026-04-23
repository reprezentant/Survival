# SURVIVE — Island Survival Game

> **Godot 4.6 · Forward Plus · v1.0 (Feature Complete)**

A focused survival game set on an isolated island. Build a raft and escape — that's the win condition. The game is **short and concentrated**: one goal, defined technological progression, no open-world sandbox.

## 🎯 **Game Loop**
```
Collect Resources → Craft Tools → Unlock Recipes → Build Raft → Escape
```

## 🚀 **Quick Start**
1. **Controls**: WASD movement, Shift sprint, Space jump, E interact
2. **Inventory**: I key (or Tab for crafting)
3. **Journal**: J key (track discovered items/creatures)
4. **Goal**: Build a Raft to escape the island

## 📋 **Core Features**

### ⚡ **Player Systems**
- **Movement**: WASD + sprint + jump with camera shake
- **Energy**: Depletes while walking (0.05/meter) and using weapons (-0.5/use)
- **Health**: Damaged by wolves (-20), mushrooms (-10), energy depletion
- **Audio**: Positional 3D footsteps with pitch randomization
- **HUD**: HP/Energy bars + 9-slot hotbar

### 🎒 **Inventory & Items (19 types)**
- **Inventory**: 28 slots + 9 hotbar slots
- **Mechanics**: Stacking (max 50), drag-and-drop, auto-save, stack splitting
- **Drop Protection**: Valuable items require confirmation popup with permanence warnings
- **Context Menu**: Right-click for stack splitting and item management
- **Warning System**: Clear alerts for items that disappear permanently vs recoverable drops
- **Item Types**: Resources, Tools, Consumables, Constructables

| Resources | Tools | Constructables |
|-----------|-------|----------------|
| Stick, Stone, Plant | Axe, Pickaxe | Campfire |
| Mushroom, Fruit | Multitool, Tinderbox | Torch |
| Log, Coal, Flintstone | Rope | Tent, Raft |
| RawMeat, CookedMeat | | |

### 🔨 **Crafting & Technology Tree**
```
Rope (Plant×2)
  └─ Axe (Stick+Stone+Rope)
  └─ Pickaxe (Stick+Stone+Rope)
  └─ Multitool (Stick+Stone+Flintstone+Coal+RawMeat) ──── prerequisite
       └─ Tinderbox (Stick×2+Stone+Flintstone+Coal) ──── prerequisite
            └─ Campfire (Stick×3+Stone×10)
            └─ Torch (Stick+Rope×2)
            └─ Raft (Stick×6+Rope×4+Plant×6+Log×6+CookedMeat×2) ← WIN
  └─ Tent (Stick×5+Rope×4+Plant×6)
```

### 🍳 **Cooking System**
- **Batch Cooking**: Cook multiple items simultaneously
- **Progress Tracking**: Visual progress bar + countdown timer
- **Persistent State**: Progress saved when closing menu
- **Quantity Selection**: Choose how many items to cook with popup dialog
- **Smart State Management**: No automatic item placement, prevents unwanted cooking
- **Recipe**: RawMeat → CookedMeat (5 seconds each)

### 📚 **Journal System**
- **Auto-Discovery**: Items/creatures automatically logged
- **Categories**: Items, Objects, Creatures
- **Notifications**: Exclamation marks for new/updated entries
- **Keybind**: J key to open

### ⚔️ **Combat & Resources**
- **Axe**: Chops trees (weapon requirement) → Logs → 3 Sticks when chopped
- **Pickaxe**: Mines boulders (weapon requirement) → Coal/Flintstone
- **Hit Effects**: Particle effects (wood/stone/blood)
- **Weapon Filtering**: Tools only work on appropriate targets

### 🐺 **Animals & AI**
- **Cow**: Passive, flees when attacked or spotted
- **Wolf**: Full AI with vision cone (80°), chase, attack, drops RawMeat
- **Navigation**: NavigationAgent3D with dynamic navmesh rebaking

### 🏗️ **Construction**
- **Placement Preview**: Green/red overlay with collision detection
- **Campfire**: Instant cooking station
- **Tent**: Sleep point, advances time 8 hours
- **Raft**: Win condition, triggers credits

### 🌍 **World Systems**
- **Day/Night Cycle**: AnimationPlayer-based with sleep fast-forward
- **Scene Management**: MainMenu → Island → Credits with threaded loading
- **Settings**: Volume, resolution scale, SSAA, fullscreen (persistent)
- **Save System**: Inventory auto-saves, world resets on restart

## 🏗️ **Technical Architecture**

### EventSystem Communication
All systems communicate through `EventSystem` singleton (59 signals):
- **No direct references** between managers
- **Signal prefixes**: BUL_, INV_, PLA_, EQU_, SPA_, etc.
- **Decoupled design** for maintainability

### Collision Layers
| Layer | Purpose | Used By |
|-------|---------|---------|
| 1 | environment | LOS raycast |
| 2 | actor | player, animals |
| 3 | interactable | pickups, cookers |
| 4 | hitbox | weapon detection |
| 5-6 | rigid_pickuppable | logs, small items |

## 📁 **Project Structure**
```
actors/          # Player, animals with AI
bulletins/       # UI overlays, menus
game/           # Core systems, managers
interactables/  # Pickups, cookers
items/          # Equippable items
objects/        # Hittable objects, constructables
resources/      # Item configs, attributes
stages/         # Game scenes
ui/            # Custom UI components
```

## 🎮 **Controls**
- **WASD**: Movement
- **Shift**: Sprint
- **Space**: Jump
- **Mouse**: Look around
- **E**: Interact
- **I**: Inventory
- **Tab**: Crafting menu
- **J**: Journal
- **ESC**: Pause menu
- **1-9**: Hotbar selection
- **Left Click**: Use equipped item/attack

## 🛠️ **Development Notes**

### Known Technical Debt
- World state (trees, buildings, animals) doesn't persist on restart
- Some legacy signal references in cooking system
- Item descriptions could be more visible in UI

### Design Principles
- EventSystem for all inter-manager communication
- Weapon filtering enforced through HittableObjectAttributes
- Blueprints handle technology tree prerequisites
- Drop confirmation protects valuable crafted items

---

## 🆕 **Ostatnie zmiany (v1.0)**
- Naprawiono system podnoszenia przedmiotów: dodano brakujący RayCast3D (`InteractionRayCast`) do gracza, ustawiono `target_position = Vector3(0, 0, -8)`, `collide_with_areas = true`, `collision_mask = 4`.
- System interakcji działa na warstwie 3 (interactable), RayCast jest dzieckiem kamery trzecioosobowej.
- Cała architektura pickupów jest event-driven (sygnały Godot, brak bezpośrednich referencji).
- Status projektu: **Feature Complete** (wszystkie planowane funkcje zaimplementowane).

## ⚡ **System podnoszenia przedmiotów**
- Gracz podnosi przedmioty przez RayCast3D (`InteractionRayCast`) wychodzący z kamery trzecioosobowej.
- RayCast wykrywa tylko obiekty na warstwie 3 (`collision_mask = 4`), czyli wszystkie pickuppable/interactable.
- Zasięg interakcji: 8 metrów (dostosowane do dystansu kamery).
- Interakcja wywołuje sygnał do EventSystem, który obsługuje pickup, inventory i usuwanie obiektu ze sceny.
- Prompt pojawia się tylko, gdy RayCast trafia w Area3D z metodą `start_interaction()`.

---

**Created with ❤️ in Godot 4.6 by [Your Name]**
