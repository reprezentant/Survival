# Testing Documentation

## Inventory Tests

### How to run
Open the project in Godot and run the script `res://tests/test_inventory.gd` using the Script Editor or create a small test scene that attaches this script to a Node and run the scene.

The script prints outputs to the debugger/console and tests:
- Basic inventory operations (add/remove items)
- Stack management (max 50 items per stack)
- Item validation
- Save/load functionality

### Test Coverage
- ✅ ItemConfig validation  
- ✅ Inventory slot management
- ✅ Stack operations
- ✅ Persistence layer

### Running Tests
1. Open Godot Editor
2. Navigate to `res://tests/test_inventory.gd`
3. Click "Play Scene" or attach to a Node
4. Check console output for results

## System Tests

### Manual Testing Checklist
- [ ] **Inventory**: Drag-and-drop, stacking, save/load
- [ ] **Crafting**: Prerequisites, resource validation
- [ ] **Combat**: Weapon filtering, hit detection
- [ ] **Cooking**: Batch processing, progress persistence
- [ ] **Journal**: Auto-discovery, categorization
- [ ] **Drop Protection**: Confirmation popups for valuable items
- [ ] **Log Chopping**: Axe + Log → 3 Sticks

### Performance Testing
- Game maintains 60 FPS with normal gameplay
- Memory usage stable during extended sessions
- Save/load operations complete under 1 second

---
*Last updated: v1.0 (Feature Complete)*
