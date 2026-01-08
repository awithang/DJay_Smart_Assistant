# UI Mockup: DJAY Smart Assistant Dashboard v5.0
**Design Goal:** Pack "Context, Momentum, and Risk" into the existing panel space without clutter, creating a "Cockpit" feel for the trader.

## Layout Overview
The dashboard remains a 50/50 split (Left Panel / Right Panel).
*   **Left Panel:** Market Intelligence (The "Decision Grid").
*   **Right Panel:** Execution & Controls (Buttons).

---

## 1. LEFT PANEL: The "Decision Grid" (Redesigned)
*Replaces the old "Strategy Signal" section.*

### Header Area (Top 60px)
*   **Title:** `DJAY Smart Assistant` (Centered, Gold)
*   **Session:** `LONDON (Open)` | `Time: 14:32`
*   **Status:** `RUN TIME` (Green) | `Vol: HIGH` (Red Alert)

### The "Matrix" (Main Data Area - 3 Columns)
This uses a grid system to align data cleanly.

| **TREND (Bias)** | **MOMENTUM (Timing)** | **RISK / SPACE** |
| :--- | :--- | :--- |
| **H4:** ⬆️ (Strong) | **M5 RSI:** 35 (Oversold) | **ATR(14):** 250 pts |
| **H1:** ⬆️ (Strong) | **Stoch:** 15 (Buy Zone) | **Spread:** 12 pts |
| **M15:** ⬇️ (Pullback) | **Slope:** ↘️ (Flat) | **Dist EMA:** -150 pts |
| **Bias:** **BULLISH** | **Action:** **WAIT** | **Space:** **+850 pts** |

*   **Visual Cues:**
    *   Arrows are colored (Green ⬆️, Red ⬇️, Grey ➡️).
    *   "Bias" row sums it up: If H4+H1=Green, Bias is BULLISH.
    *   "Action" row gives the tip: "WAIT" (because M15 is down) or "READY" (if M15 turns).
    *   "Space" shows distance to next Resistance. Green if >300pts, Red if <150pts.

### The "Zone" Footer (Bottom of Left Panel)
*   **Current Zone:** `Zone: MIDDLE (No Support)`
*   **Nearest Level:** `Support @ 1.05200 (250 pts away)`
*   *Note: This keeps the user grounded in the "Map".*

---

## 2. RIGHT PANEL: Execution (Optimized)
*Keeps the current efficient layout but connects it to the Left Panel data.*

### Execution Header
*   **Price:** `1.05450` (Big, Bold, Color changes on tick)

### Manual Buttons (Top)
*   `[ BUY ]` `[ SELL ]` (Large, easy to hit)

### Smart Filters (Middle - Toggles)
Instead of just "Auto On/Off", we add "Filter Switches" so you can choose what to obey.
*   `[x] Trend Filter` (If ON, blocks Buys when H1 is Down)
*   `[x] Zone Filter` (If ON, blocks trading in Middle Zone)
*   `[ ] Aggressive` (If ON, ignores filters - for experts)

### Auto Strategy (Bottom)
*   **Auto:** `[ ON / OFF ]`
*   **Strategies:** `[ Arrow ]` `[ Rev ]` `[ Break ]` `[ Scalp ]`
*   *New Indicator:* Next to `[ Scalp ]`, a small colored dot.
    *   🟢 = Conditions Good
    *   🔴 = Conditions Bad (e.g., Slope is Crash)

---

## 3. Visual "Safety" Indicators
*   **Background Flash:** If Volatility spikes dangerous high (e.g., News event), the panel border pulses RED.
*   **Ghost Buttons:** If "Trend Filter" is ON and Trend is DOWN, the "BUY" button dims (looks disabled) to visually warn you "Don't press this!".

---

## 4. Example User Scenario (The "Falling Knife")
1.  **Market:** Crashing hard.
2.  **Left Panel:**
    *   Trend H1: ⬇️ (Strong)
    *   Slope: ⬇️⬇️ (Steep!)
    *   Action: **NO BUY**
3.  **Right Panel:**
    *   The `[ Scalp ]` dot is 🔴 Red.
    *   The Manual `[ BUY ]` button is dimmed/greyed out.
4.  **Result:** User sees "Action: NO BUY" and the dimmed button. They **do not click**. They save money.
