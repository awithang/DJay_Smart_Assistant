# Engineer Review: Quick Scalp Logic Optimization (v2.0)

**Date:** January 7, 2026
**Subject:** Review of Quick Scalp implementation vs @implement_plan_quick_scalp.md

## 1. Executive Summary
The implementation successfully transitions the Quick Scalp logic from a restrictive "AND" filter to a more effective "OR" filter (RSI/Stochastic). The "Smart Auto-Switch" UI feedback is well-integrated. However, there are two critical technical discrepancies in `SignalEngine.mqh` that will cause inconsistent behavior in multi-timeframe environments.

## 2. Successes (Correctly Implemented)
- **OR Logic Filter:** `DJay_Smart_Assistant.mq5` correctly uses `(RSI < BuyLevel || Stoch < BuyLevel)` logic to increase trade frequency.
- **ADX Filter in OnTick:** The hard-stop for trades when `ADX < 20` is correctly placed before execution logic.
- **Smart UI Feedback:** `DashboardPanel` correctly handles the four states (OFF, READY, LOW ADX, WAIT) with appropriate color coding.

## 3. Discrepancies & Required Fixes

### 3.1 ADX Handle Timeframe Mismatch (Critical)
- **Location:** `SignalEngine.mqh` -> `Init()`
- **Issue:** The code uses `PERIOD_CURRENT` for the ADX handle.
- **Impact:** If the EA is running on an H1 chart, it will use H1 ADX (Trend strength) instead of M5 ADX (Momentum/Volatility). This will lead to "Zero Trades" on H1 charts even if M5 is trending.
- **Fix:** Change `iADX(_Symbol, PERIOD_CURRENT, 14)` to `iADX(_Symbol, PERIOD_M5, 14)`.

### 3.2 Advisor Message Logic (Usability)
- **Location:** `SignalEngine.mqh` -> `GetAdvisorMessage()`
- **Issue:** The advisor message does not reflect the ADX filter state. It reports "Quick Scalp active" while the internal logic might be blocking trades due to low ADX.
- **Impact:** User confusion. The UI shows "Active" but no trades occur, making the fix appear "broken."
- **Fix:** Add a check `if (GetADXValue(PERIOD_M5) < 20)` and return `"Market is Choppy (ADX Low). Quick Scalp Paused."`

## 4. Conclusion
The "Zero Trades" bug is partially fixed by the RSI/Stoch OR logic, but will persist on higher timeframes due to the ADX handle mismatch. Once the two fixes above are applied, the implementation will be 100% compliant with the v2.0 optimization plan.

**Recommendation:** Proceed with fixing the ADX handle timeframe and updating the Advisor text logic.
