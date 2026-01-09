# Implementation Plan: Sniper + Hybrid Mode Coordination

## Overview

Enable **Sniper Mode** and **Hybrid Mode** to work together as a coordinated system where:
- **Sniper Mode**: Makes decisions every 15 minutes (on new M15 bars)
- **Hybrid Mode**: Fills the gap during the 15-minute window with M5 entries
- **Priority**: Sniper takes precedence; Hybrid only trades when Sniper hasn't executed in the current M15 cycle

## Current State Analysis

**File**: `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5`

**Line 396**: Mutual exclusion logic that prevents both modes from working together:
```cpp
if(g_hybrid_mode_enabled && !g_sniper_mode_enabled)
```

**Problem**: Hybrid is completely disabled when Sniper is ON, missing M5 opportunities during the 15-minute gap.

## Design Approach: Priority-Based Coordination

### Key Concept
- **M15 Cycle**: The 15-minute period between M15 bar openings
- **Sniper Priority**: Sniper executes first when new M15 bar appears
- **Hybrid Gap-Filling**: During the cycle, Hybrid can trade if Sniper hasn't
- **Cycle Reset**: When new M15 bar appears, tracking resets

### Coordination Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    M15 CYCLE BEGINS                             │
│              (New M15 bar detected)                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  RESET: g_sniper_executed_this_cycle = false                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SNIPER MODE CHECK (M15 signal)                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Sniper Signal Found?                                    │    │
│  │   YES → Execute Trade → Set flag: true                  │    │
│  │   NO  → Continue to Hybrid                              │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  HYBRID MODE CHECK (M5 signals during cycle)                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Can Hybrid Execute?                                     │    │
│  │   g_sniper_mode_enabled == false → YES                  │    │
│  │   g_sniper_executed_this_cycle == false → YES           │    │
│  │   Otherwise → NO (already executed)                     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### State Variables to Add

```cpp
// Around line 131 (after g_sniper_mode_enabled)
datetime g_last_m15_bar_time = 0;       // Track current M15 cycle start
bool g_sniper_executed_this_cycle = false; // Track if Sniper traded in current cycle
```

## Implementation Steps

### Step 1: Add State Variables (Line ~131)

**Location**: After `bool g_sniper_mode_enabled = false;`

```cpp
//--- Sniper+Hybrid Coordination State
datetime g_last_m15_bar_time = 0;           // Track current M15 cycle for coordination
bool g_sniper_executed_this_cycle = false;  // Track if Sniper executed in current M15 cycle
```

### Step 2: Add M15 Cycle Detection (Line ~360)

**Location**: Before Sniper Mode section (before line 361)

```cpp
// --- M15 Cycle Detection for Sniper+Hybrid Coordination ---
datetime currentM15BarTime = iTime(_Symbol, PERIOD_M15, 0);
bool newM15Bar = (currentM15BarTime != g_last_m15_bar_time);

// Reset coordination state on new M15 bar
if(newM15Bar)
{
   g_last_m15_bar_time = currentM15BarTime;
   g_sniper_executed_this_cycle = false;

   if(g_sniper_mode_enabled && g_hybrid_mode_enabled)
      Print("[COORD] New M15 cycle - Sniper priority reset");
}
```

### Step 3: Track Sniper Execution (Lines ~380, 390)

**Location**: After `ExecuteSniperTrade()` calls

**Change 1** (Line ~380, after `ExecuteSniperTrade(ORDER_TYPE_BUY)`):
```cpp
if(g_tradingMode == MODE_AUTO)
{
   ExecuteSniperTrade(ORDER_TYPE_BUY);
   g_sniper_executed_this_cycle = true; // Mark Sniper executed
}
```

**Change 2** (Line ~390, after `ExecuteSniperTrade(ORDER_TYPE_SELL)`):
```cpp
if(g_tradingMode == MODE_AUTO)
{
   ExecuteSniperTrade(ORDER_TYPE_SELL);
   g_sniper_executed_this_cycle = true; // Mark Sniper executed
}
```

### Step 4: Update Hybrid Mode Condition (Line 396)

**Replace**:
```cpp
if(g_hybrid_mode_enabled && !g_sniper_mode_enabled)
```

**With**:
```cpp
// Hybrid Mode: Enable gap-filling when Sniper hasn't executed in current M15 cycle
bool hybridAllowed = !g_sniper_mode_enabled ||  // Sniper OFF → Hybrid independent
                     (g_sniper_mode_enabled && !g_sniper_executed_this_cycle);  // Sniper ON but hasn't traded

if(g_hybrid_mode_enabled && hybridAllowed)
```

### Step 5: Add Minimal Coordination Logging (Line ~404)

**Location**: Inside `if(newM5Bar)` block, after `GetHybridSignal()` call

```cpp
if(newM5Bar)
{
   // Get Hybrid Signal (M15 context + M5 trigger)
   ENUM_SIGNAL_TYPE hybridSignal = signalEngine.GetHybridSignal(
      Input_Hybrid_Debug_Mode,
      Input_Hybrid_EMA_MaxDist,
      Input_Hybrid_Trend_MinScore
   );

   // Minimal logging: Only log if Hybrid signal is blocked due to Sniper execution
   if(g_sniper_mode_enabled && hybridSignal != SIGNAL_NONE && g_sniper_executed_this_cycle)
   {
      Print(StringFormat("[COORD] Hybrid signal BLOCKED - Sniper already executed this M15 cycle"));
   }

   // Execute trade on valid Hybrid signal
   if(hybridSignal == SIGNAL_PA_BUY)
   // ... rest of code
```

### Step 6: Update Dashboard Info (Optional Enhancement)

**Location**: In `OnTimer()`, around line 613-614

**Add** coordination status display:
```cpp
// Hybrid Mode status
qsText = g_hybrid_mode_enabled ? "HYBRID: Active" : "HYBRID: Inactive";
if(g_hybrid_mode_enabled && g_sniper_mode_enabled)
{
   qsText += StringFormat(" | Sniper %s this cycle",
                          (g_sniper_executed_this_cycle ? "EXECUTED" : "WAITING"));
}
```

## Code Changes Summary

| Line | Change Type | Description |
|------|-------------|-------------|
| ~131 | ADD | Two new state variables for coordination |
| ~360 | ADD | M15 cycle detection logic |
| ~380 | MOD | Set flag after Sniper BUY execution |
| ~390 | MOD | Set flag after Sniper SELL execution |
| 396 | MOD | Replace `!g_sniper_mode_enabled` with coordination check |
| ~404 | ADD | Optional coordination logging |

## Edge Cases Handled

1. **Market Gaps**: `iTime()` automatically handles weekend gaps and market closures
2. **Manual Trades**: Coordination only affects automated Sniper/Hybrid signals
3. **Mode Toggle**: Disabling/enabling modes mid-cycle handled gracefully
4. **First Bar**: `g_last_m15_bar_time = 0` ensures proper initialization

## Testing & Verification

### 1. Compile Check
```bash
# Compile the EA
metaeditorcompile "DJay_Smart_Assistant.mq5"
```

### 2. Visual Backtest Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| Both modes enabled, Sniper has signal at M15 open | Sniper executes, Hybrid blocked for 15 min |
| Both modes enabled, no Sniper signal at M15 open | Hybrid can execute on M5 signals during cycle |
| Only Sniper enabled | Normal Sniper behavior, Hybrid inactive |
| Only Hybrid enabled | Normal Hybrid behavior, independent |

### 3. Log Output Verification

Only critical events logged:
```
[COORD] New M15 cycle - Sniper priority reset
[COORD] Hybrid signal BLOCKED - Sniper already executed this M15 cycle
```

### 4. Arrow Verification
- Sniper arrows: Code 233 (buy) / 234 (sell) on M15
- Hybrid arrows: Code 241 (buy) / 242 (sell) on M5
- Should not see both within same M15 cycle

### 5. Trade Comment Verification
- Sniper trades: Comment contains "SNIPER"
- Hybrid trades: Comment contains "HYBRID"
- Never both in same M15 cycle

## Files Modified

1. `MQL5/Experts/DJay_Assistant/DJay_Smart_Assistant.mq5`
   - Add state variables (~line 131)
   - Add M15 cycle detection (~line 360)
   - Modify Sniper execution tracking (~lines 380, 390)
   - Modify Hybrid condition (line 396)

## Files Not Modified (No Changes Needed)

- `MQL5/Include/DJay_Assistant/SignalEngine.mqh` - Signal logic unchanged
- `MQL5/Include/DJay_Assistant/TradeManager.mqh` - Trade execution unchanged
- `MQL5/Include/DJay_Assistant/DashboardPanel.mqh` - Optional display update only

## Success Criteria

- [ ] EA compiles without errors
- [ ] Both modes can be enabled simultaneously via inputs
- [ ] Sniper executes first when M15 bar opens (if signal exists)
- [ ] Hybrid fills gaps when Sniper has no signal
- [ ] No duplicate trades in same M15 cycle
- [ ] Log messages clearly show coordination decisions
- [ ] Dashboard shows correct mode status
- [ ] Arrow codes remain distinct (233/234 vs 241/242)

## Rollback Plan

If issues occur, revert changes to line 396:
```cpp
// Revert to original mutual exclusion
if(g_hybrid_mode_enabled && !g_sniper_mode_enabled)
```

And remove the added state variables at line ~131.

---

**Created**: 2025-01-09
**Status**: Ready for implementation
**Estimated Time**: 1-1.5 hours with full testing
