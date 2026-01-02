# Implementation Plan: Stepped Profit Lock (Ladder Logic)

## Objective
Implement a "Ladder" or "Stepped" Profit Lock system.
Instead of a standard trailing stop that follows price at a distance, this system locks in specific profit levels based on milestones.

## The Logic (Ladder System)

1.  **Stage 1: Initial Lock**
    *   **Trigger:** When `CurrentProfit >= Trigger_Points` (e.g., 200 pts).
    *   **Action:** Move SL to `OpenPrice + Lock_Amount_Points` (e.g., +50 pts).
    *   *Result:* We have locked our first 5 pips.

2.  **Stage 2: Sequential Stepping**
    *   Once the initial lock is active, we check for **further profit gains**.
    *   **Trigger:** Has profit increased by another `Step_Points` (e.g., 100 pts) above the *initial trigger*?
    *   **Formula:** `StepsTaken = Floor((CurrentProfit - Trigger_Points) / Step_Points)`
    *   **Action:** Move SL to `Initial_Lock_SL + (StepsTaken * Step_Points)`.
    *   *Result:* If price moves +10 pips, SL moves +10 pips. We maintain the exact same "buffer" distance from the current price as we established in the first step, but only updating in discrete 10-pip jumps.

## Files to Modify

### 1. `MQL5/Include/EA_Helper/TradeManager.mqh`
**Action:** Update `ManagePositions` to use this new "Ladder" logic.

*   **Inputs:** `lock_trigger_pts`, `lock_amount_pts`, `step_pts`. (Note: `trail_dist` is no longer needed/used in this logic, or can be kept as a separate optional feature, but for this specific request, we focus on the stepping profit lock).

*   **Detailed Logic (BUY Example):**
    ```cpp
    double currentProfitPts = CurrentPrice - OpenPrice;

    // 1. Check if we reached the start line
    if (currentProfitPts >= lock_trigger_pts)
    {
        // 2. Calculate Base Lock SL (The "Foundation")
        double baseLockSL = OpenPrice + (lock_amount_pts * Point);

        // 3. Calculate how many "Steps" we have climbed BEYOND the trigger
        //    (CurrentProfit - Trigger) / Step
        double profitBeyondTrigger = currentProfitPts - lock_trigger_pts;
        int stepsClimbed = (int)MathFloor(profitBeyondTrigger / step_pts);

        // 4. Calculate New Target SL
        //    BaseSL + (Steps * StepDistance)
        double stepGain = stepsClimbed * (step_pts * Point);
        double newTargetSL = baseLockSL + stepGain;

        // 5. Apply if better than current SL
        if (newTargetSL > CurrentSL)
        {
            ApplySL(newTargetSL);
        }
    }
    ```

*   **SELL Example:** Inverted logic.
    *   `currentProfitPts = OpenPrice - CurrentPrice`
    *   `baseLockSL = OpenPrice - (lock_amount_pts * Point)`
    *   `newTargetSL = baseLockSL - stepGain` (Moving DOWN)
    *   Apply if `newTargetSL < CurrentSL` (or `CurrentSL == 0`).

### 2. `MQL5/Experts/EA_Helper/WidwaPa_Assistant.mq5`
**Action:** Update Inputs to match this logic.

*   **New Inputs:**
    *   `Input_ProfitLock_Trigger_Pts` = 200 (Start locking at 20 pips profit)
    *   `Input_ProfitLock_Amount_Pts` = 50 (Lock 5 pips initially)
    *   `Input_ProfitLock_Step_Pts` = 100 (Move SL every 10 pips of further profit)
    *   *Removed:* `Input_Trailing_Stop_Pts` (Standard trailing distance is replaced by this logic).

## Performance Impact
*   **High Performance:** Because we use `MathFloor` and `Step` logic, the SL target `newTargetSL` only changes value when a full step is completed.
*   **Zero Spam:** The condition `if (newTargetSL > CurrentSL)` will naturally return `false` for 99% of ticks while the price is moving *within* a step, ensuring zero unnecessary server calls.

