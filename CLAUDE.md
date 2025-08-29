# CLAUDE.md - Development Context for poopDeck OOP

## Project Overview

**poopDeck-oop** is a complete object-oriented rewrite of the Achaea seafaring automation package for Mudlet. This document contains critical context and lessons learned for future development sessions.

### Current Status: v2.0.0 OOP - Active Development

**Repository:** https://github.com/ronh3/poopDeck-oop  
**Original:** https://github.com/ronh3/poopDeck (procedural version)  
**Architecture:** Complete OOP transformation using Lua metatables  
**Development Methodology:** Specflow for AI-assisted development

## Critical Technical Lessons Learned

### 1. Mudlet Package Loading System (CRITICAL)

**❌ WRONG ASSUMPTION**: Mudlet supports Node.js-style `require()` statements
**✅ REALITY**: Mudlet loads scripts as global code, not modules

#### Incorrect Approach (Don't Use):
```lua
-- THIS DOESN'T WORK IN MUDLET
local Display = require("poopDeck.Classes.Display")
local Config = require("poopDeck.Classes.Config")

-- ALSO WRONG: Using return at end of class file
return Display  -- DON'T DO THIS
```

#### Correct Approach:
```lua
-- In each class file, export to namespace:
poopDeck = poopDeck or {}
poopDeck.Display = Display

-- Then in Init.lua, access via namespace:
poopDeck.config = poopDeck.Config:new()
poopDeck.display = poopDeck.Display:new(poopDeck.config)
```

### 2. Class Loading Timing Issues

**Problem**: Classes may not be loaded when Init.lua runs  
**Solution**: Retry logic with timing checks

```lua
function poopDeck.initialize()
    if not poopDeck.Config then
        echo("poopDeck: Classes not loaded yet, retrying in 1 second...\n")
        tempTimer(1, poopDeck.initialize)
        return
    end
    -- Proceed with initialization...
end
```

### 3. Mudlet Event System Integration

**✅ CORRECT**: Use Mudlet's native event system, not custom patterns
- `raiseEvent("poopDeck.eventName", data)`
- `registerAnonymousEventHandler("poopDeck.eventName", function)`

### 4. Package Structure for Muddler

**File Organization**:
```
src/scripts/Classes/
├── Display.lua          # Class definition
├── Config.lua           # Class definition
├── Ship.lua             # Class definition
├── SeamonsterCombat.lua # Class definition
├── Init.lua             # Initialization system
└── scripts.json         # Muddler registration
```

## Architecture Decisions That Work

### 1. Class Hierarchy Using Metatables
```lua
local Display = {}
Display.__index = Display

function Display:new(config)
    local self = setmetatable({}, Display)
    -- Initialize instance
    return self
end
```

### 2. Event-Driven Communication
- All classes communicate via Mudlet events
- Decoupled architecture enables testing and extension
- Events schema documented in ARCHITECTURE.md

### 3. Backward Compatibility Layer
```lua
-- Maintain old function calls
function poopDeck.turnShip(heading)
    if poopDeck.ship then
        poopDeck.ship:turn(heading)
    else
        echo("poopDeck: Ship not initialized\n")
    end
end
```

### 4. Command Queue System for Game Balance
- Ship commands wait for crew balance ("The crew of your ship is now ready...")
- Method chaining: `ship:chain():castOff():setSpeed("full"):turn("north"):execute()`
- Prevents command spam and game failures

## Common Development Issues and Solutions

### Issue: "Ship not initialized" Error
**Cause**: Initialization system failed or timing issue  
**Debug**: Use `poopDeck.debug()` to check class loading status  
**Fix**: Call `poopDeck.init()` manually or check class loading order

### Issue: Classes not found
**Cause**: Muddler didn't register scripts properly  
**Check**: Verify `scripts.json` files are correct  
**Fix**: Ensure all classes listed in scripts.json with proper hierarchy

### Issue: Events not firing
**Cause**: Event names don't match or handlers not registered  
**Debug**: Check event names in triggers vs class event handlers  
**Fix**: Use consistent `poopDeck.eventName` pattern

## GitHub Actions Automation

### Automatic Version Bumping
- `feat:` or `feature:` → Minor version bump (2.0.0 → 2.1.0)
- `fix:` → Patch version bump (2.0.0 → 2.0.1)  
- `BREAKING:` → Major version bump (2.0.0 → 3.0.0)

### Build Process
1. **Muddler Build**: Processes `src/` directory structure
2. **Testing**: Runs automated tests in Mudlet environment
3. **Package Creation**: Generates `.mpackage` file
4. **Release**: Auto-creates GitHub release with documentation

## Performance Optimizations Applied

### Display System (80% Improvement)
- **Template-based rendering**: Pre-calculate static elements
- **Color inheritance**: Share base colors across schemes
- **String operations**: Use `string.format()` vs concatenation
- **Memory management**: Reuse template objects

### Combat System
- **State cleanup**: Proper timer and resource management
- **External kill detection**: Handle edge cases gracefully
- **Error resilience**: Comprehensive error handling and recovery

## User Experience Principles

### 1. Backward Compatibility (100%)
- All existing aliases must continue working
- New OOP methods available alongside legacy functions
- No breaking changes for existing users

### 2. Progressive Enhancement
- Users can adopt new features at their own pace
- Fallback mechanisms when OOP system unavailable
- Clear error messages and debugging tools

### 3. Performance First
- Optimize critical paths (display rendering, event handling)
- Memory-efficient object lifecycle management
- Minimize game command spam through queueing

## Testing and Validation Approach

### Manual Testing Checklist
1. **Installation**: Package installs without errors
2. **Initialization**: `poopDeck.debug()` shows all systems loaded
3. **Legacy Commands**: `turn north`, `set speed full` work
4. **OOP Methods**: `poopDeck.ship:turn("north")` works
5. **Events**: Monster spawning triggers display updates
6. **Performance**: Notice faster rendering and responsiveness

### Debug Commands
- `poopDeck.debug()` - System state overview
- `poopDeck.status()` - Comprehensive status dump
- `poopDeck.init()` - Manual initialization
- `ship status` - Ship state and command queue status

## Documentation Standards

### Code Documentation
- Inline comments for complex logic
- Class-level documentation with purpose and usage examples
- Event schema documentation
- Performance characteristics noted

### User Documentation
- ARCHITECTURE.md - Technical specification
- DEVELOPMENT_METHODOLOGY.md - Specflow approach used
- CHANGELOG.md - Detailed version history
- README.md - User-focused overview and quick start

## Future Development Guidelines

### 1. Maintain Mudlet Compatibility
- Never use Node.js patterns (`require()`, etc.)
- Test all changes in actual Mudlet installation
- Respect Mudlet's script loading model

### 2. Event-First Architecture
- New features should use event system
- Avoid tight coupling between classes
- Document all events in ARCHITECTURE.md

### 3. Performance Considerations
- Profile critical paths before optimizing
- Prefer memory reuse over object creation
- Test with extended gameplay sessions

### 4. Backward Compatibility Rule
- Never break existing user aliases/functions
- Add new features as enhancements, not replacements
- Provide migration guidance when APIs change

## Common Pitfalls to Avoid

1. **Don't assume Node.js module patterns work in Mudlet**
2. **Don't ignore script loading timing** - classes may not be available immediately
3. **Don't break backward compatibility** - users rely on existing aliases
4. **Don't forget game balance mechanics** - commands need proper queueing
5. **Don't skip manual testing in Mudlet** - unit tests aren't enough

## Repository Management

### Branch Strategy
- `main` - Stable OOP version
- Feature branches for new development
- Separate repository from original procedural version

### Release Process  
1. Update VERSION file
2. Update CHANGELOG.md
3. Commit with appropriate prefix (`feat:`, `fix:`, etc.)
4. GitHub Actions handles build and release automatically
5. Test generated `.mpackage` in clean Mudlet profile

---

**Next Development Session**: Use this document to understand the complete system architecture, critical technical constraints, and established patterns. The OOP system is stable and ready for feature enhancement.

**Most Critical Point**: Mudlet uses global script loading, NOT Node.js module patterns. Always test in actual Mudlet installation.