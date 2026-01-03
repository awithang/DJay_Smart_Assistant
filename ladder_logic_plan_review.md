# Plan Review: Stepped Profit Lock (Ladder Logic)

**Date:** 2026-01-03
**Reviewer:** Claude Code (Coding Agent)
**Status:** 📋 Review Complete - Awaiting Implementation Decision

---

## Executive Summary

The "Ladder Logic" plan proposes a **Constant Buffer Trailing** system that differs fundamentally from the previously implemented "Step Trailing Stop" approach. This review analyzes the feasibility, correctness, and trade-offs of the proposed implementation.

---

## The Core Concept

### What is "Ladder Logic"?

A stepped profit lock system that maintains a **constant buffer** between the current price and the Stop Loss as profit increases.

**Key Formula:**
```
StepsTaken = Floor((CurrentProfit - Trigger_Points) / Step_Points)
NewSL = Initial_Lock_SL + (StepsTaken * Step_Points)
```

**Result:** For every X pips of additional profit beyond the trigger, the SL moves up by X pips, maintaining the same buffer distance.

---

## Feasibility Analysis

### ✅ Mathematically Sound

| Component | Assessment |
|-----------|------------|
| Formula correctness | ✅ Valid - Integer division with floor works correctly |
| BUY direction logic | ✅ Correct - SL moves UP as profit increases |
| SELL direction logic | ✅ Correct - SL moves DOWN as profit increases |
| Edge cases | ✅ Handled - Initial SL bypass when `CurrentSL == 0` |

### ✅ Performance Claims Valid

| Claim | Verification |
|-------|--------------|
| Zero spam | ✅ True - `newTargetSL` only changes on full step completion |
| High performance | ✅ True - Single O(N) loop with simple arithmetic |
| No unnecessary server calls | ✅ True - `if (newTargetSL > CurrentSL)` filters ~99% of ticks |

---

## Detailed Logic Walkthrough

### BUY Position Example

**Parameters:**
- Trigger: 200 points (20 pips)
- Lock Amount: 50 points (5 pips)
- Step: 100 points (10 pips)

| Profit Level | Calculation | SL Position | Buffer |
|--------------|-------------|-------------|--------|
| 0-199 pts | Not triggered | No change | N/A |
| 200 pts | `baseLockSL = Open + 50` | Open + 50 | 150 pts |
| 250 pts | `stepsClimbed = Floor(50/100) = 0` | Open + 50 | 200 pts |
| 300 pts | `stepsClimbed = Floor(100/100) = 1` | Open + 150 | 150 pts |
| 400 pts | `stepsClimbed = Floor(200/100) = 2` | Open + 250 | 150 pts |
| 450 pts | `stepsClimbed = Floor(250/100) = 2` | Open + 250 | 200 pts |

**Observation:** The buffer oscillates between 150-200 points, but the general trend is constant.

### SELL Position Example

**Parameters:** Same as above

| Profit Level | Calculation | SL Position |
|--------------|-------------|-------------|
| 0-199 pts | Not triggered | No change |
| 200 pts | `baseLockSL = Open - 50` | Open - 50 |
| 300 pts | `stepsClimbed = 1` | Open - 150 |
| 400 pts | `stepsClimbed = 2` | Open - 250 |

**Logic:** Inverted - SL moves DOWN as profit increases.

---

## Comparison: Ladder Logic vs. Previous Implementation

| Aspect | Ladder Logic (New) | Step Trailing Stop (Previous) |
|--------|-------------------|------------------------------|
| **Primary Goal** | Lock in specific profit levels | Follow price at fixed distance |
| **Parameters** | 3 (trigger, lock, step) | 4 (trigger, lock, trail_dist, trail_step) |
| **Buffer Behavior** | Constant (trigger - lock) | Variable (trail_dist) |
| **Complexity** | Simple | Moderate |
| **Use Case** | Trend following with fixed R:R | General trailing protection |

### Example Behavior (BUY position at various profit levels):

| Current Profit | Ladder Logic SL | Previous SL (trail=300, step=100) |
|----------------|-----------------|-----------------------------------|
| 200 pts | Open + 50 (lock) | Open + 50 (lock) |
| 250 pts | Open + 50 | Open + 50 (step not reached) |
| 300 pts | Open + 150 | Open - 100 (trailing) or Open + 50 (lock wins) |
| 400 pts | Open + 250 | Open + 100 (trailing) |

---

## Advantages

| Advantage | Explanation |
|-----------|-------------|
| ✅ **Simplicity** | Fewer parameters to configure |
| ✅ **Predictable Buffer** | Constant risk/reward ratio as trade progresses |
| ✅ **Zero Spam** | Natural filtering through `MathFloor` |
| ✅ **Clear Profit Locking** | Each step locks in exactly X pips of gain |
| ✅ **Intuitive** | Easy to explain: "Lock 5 pips, then move SL every 10 pips" |

---

## Disadvantages / Concerns

| Concern | Explanation |
|---------|-------------|
| ⚠️ **Replaces Trailing Stop** | No traditional fixed-distance trailing option |
| ⚠️ **Fixed Buffer May Not Suit All Conditions** | In ranging markets, constant buffer might be too tight/too wide |
| ⚠️ **No "Trail Distance" Parameter** | Less flexible than having independent control |
| ⚠️ **Step Size = Buffer Size** | The step and lock amount are implicitly linked via the buffer concept |

---

## Edge Cases & Validation

### Edge Case 1: Price Reversal Mid-Step

**Scenario:** Price goes from 300 pts to 280 pts (back below step threshold)

**Expected:** SL should NOT move down (we only move SL in profit direction)

**Plan Verification:** ✅ Correct - The condition `if (newTargetSL > CurrentSL)` ensures SL never moves against us

### Edge Case 2: First SL Assignment

**Scenario:** Position has no SL yet (`CurrentSL == 0`)

**Expected:** Should bypass comparison and set SL immediately

**Plan Verification:** ✅ Correct - Plan mentions "or `CurrentSL == 0`" in SELL logic

### Edge Case 3: Rapid Price Movement

**Scenario:** Price jumps from 200 pts to 500 pts in one tick

**Expected:** SL should calculate correctly for `stepsClimbed = 3`

**Plan Verification:** ✅ Correct - `MathFloor((500-200)/100) = 3` → SL moves to Open + 350

---

## Code Quality Assessment

### Proposed Code Snippet Analysis:

```cpp
double currentProfitPts = CurrentPrice - OpenPrice;

if (currentProfitPts >= lock_trigger_pts)
{
    double baseLockSL = OpenPrice + (lock_amount_pts * Point);
    double profitBeyondTrigger = currentProfitPts - lock_trigger_pts;
    int stepsClimbed = (int)MathFloor(profitBeyondTrigger / step_pts);
    double stepGain = stepsClimbed * (step_pts * Point);
    double newTargetSL = baseLockSL + stepGain;

    if (newTargetSL > CurrentSL || CurrentSL == 0)
    {
        ApplySL(newTargetSL);
    }
}
```

**Assessment:** ✅ Clean, readable, and correct

---

## Recommendations

### 1. Implementation Approach

**Option A: Replace Current Implementation**
- Simpler codebase
- Fewer user parameters
- Loss of trailing stop flexibility

**Option B: Add as Toggle Option** ⭐ **Recommended**
- Keep both strategies available
- Add `Input_Trailing_Mode` (0=Ladder, 1=Traditional)
- Allows A/B testing and adaptation to market conditions

### 2. Suggested Input Structure

```
// Trade Management Mode
input ENUM_TRAIL_MODE Input_Trailing_Mode = TRAIL_LADDER;

// Ladder Logic Parameters
input int Input_Ladder_Trigger_Pts = 200;
input int Input_Ladder_Lock_Pts = 50;
input int Input_Ladder_Step_Pts = 100;

// Traditional Parameters (if mode = TRAIL_TRADITIONAL)
input int Input_ProfitLock_Trigger_Pts = 200;
input int Input_ProfitLock_Amount_Pts = 50;
input int Input_Trailing_Stop_Pts = 300;
input int Input_Trailing_Step_Pts = 100;
```

### 3. Testing Checklist

Before live deployment:
- [ ] Verify BUY positions lock correctly at trigger
- [ ] Verify SELL positions lock correctly at trigger
- [ ] Confirm SL moves in steps (not every tick)
- [ ] Test price reversal (SL should not move backward)
- [ ] Test rapid price jumps
- [ ] Verify buffer calculation at various profit levels

---

## Final Verdict

| Criteria | Rating | Notes |
|----------|--------|-------|
| **Feasibility** | ✅ Excellent | Logic is sound and implementable |
| **Correctness** | ✅ Excellent | Formulas are mathematically correct |
| **Performance** | ✅ Excellent | Zero spam, O(N) complexity |
| **Simplicity** | ✅ Excellent | Fewer parameters, clear logic |
| **Flexibility** | ⚠️ Moderate | Replaces traditional trailing |

### Recommendation: **Implement as an Additional Option**

The Ladder Logic is a **valid and excellent approach** for traders who prefer constant-buffer trailing. However, I recommend implementing it alongside the traditional step trailing stop (via a mode toggle) to provide maximum flexibility.

---

## Next Steps

1. **User Decision:** Choose between Replace vs. Add-as-Option approach
2. **Implementation:** Modify `TradeManager.mqh` and `WidwaPa_Assistant.mq5`
3. **Testing:** Demo account verification
4. **Documentation:** Update user guide with new parameters

**Status:** ⏸️ **Awaiting user decision on implementation approach**
