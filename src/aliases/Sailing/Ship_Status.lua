-- Ship Status Display
-- Shows comprehensive ship state information

if poopDeck.ship then
    local state = poopDeck.ship:getState()
    
    -- Display header
    if poopDeck.display then
        poopDeck.display:showMessage("Ship Status Report", "good", true)
    else
        echo("=== Ship Status Report ===\n")
    end
    
    -- Navigation Status
    cecho("<cyan>Navigation:\n")
    echo(string.format("  Heading: %s | Speed: %s (actual: %d kts)\n", 
        state.currentHeading or "unknown",
        state.currentSpeed or "unknown",
        state.actualSpeed or 0))
    echo(string.format("  Docked: %s | Anchored: %s\n",
        state.isDocked and "Yes" or "No",
        state.anchored and "Yes" or "No"))
    
    -- Wind & Sea
    cecho("\n<cyan>Conditions:\n")
    echo(string.format("  Wind: %s @ %d kts | Sea: %s\n",
        state.windDirection or "unknown",
        state.windSpeed or 0,
        state.seaCondition or "unknown"))
    
    -- Ship Equipment
    cecho("\n<cyan>Equipment:\n")
    echo(string.format("  Plank: %s | Comm Screen: %s | Warning: %s\n",
        state.plankLowered and "Lowered" or "Raised",
        state.commScreenRaised and "Raised" or "Lowered",
        state.warningEnabled and "On" or "Off"))
    
    -- Ship Status
    cecho("\n<cyan>Status:\n")
    echo(string.format("  Balance: %s | Maintenance: %s | On Fire: %s\n",
        state.hasBalance and "Ready" or "Recovering",
        state.needsMaintenance and "Needed" or "Good",
        state.isOnFire and "YES!" or "No"))
    
    -- Ship Health (if available from prompt)
    if state.health then
        cecho("\n<cyan>Health:\n")
        echo(string.format("  Hull: %d%% | Sails: %d%%\n",
            state.health.hull or 100,
            state.health.sails or 100))
    end
    
    -- Command Queue Status
    if poopDeck.ship.commandQueue and #poopDeck.ship.commandQueue > 0 then
        cecho("\n<yellow>Command Queue:\n")
        for i, cmd in ipairs(poopDeck.ship.commandQueue) do
            echo(string.format("  %d. %s %s\n", i, cmd.command, cmd.arg or ""))
        end
    end
else
    echo("poopDeck: Ship not initialized\n")
end