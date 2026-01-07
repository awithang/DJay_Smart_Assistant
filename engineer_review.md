# Master Repair Specification: Pips vs. Points & Safety Fixes

**Date:** January 7, 2026
**Subject:** Fix for BUG-2025-001 (Excessive Lot Sizes)
**Status:** ROOT CAUSE IDENTIFIED

## 1. Root Cause: Parameter Mismatch
The "Zero Trades" issue was previously addressed by relaxing filters, but it introduced a catastrophic risk due to **Pips vs. Points** confusion in the input parameters.

- **The Mismatch:** `Input_QS_SL_Points` is set to `20`. The user intended **20 Pips** (200 points), but the code uses it as **20 Points** (2 pips).
- **The Result:** A 2-pip stop loss forces the lot size calculation to be **10x larger** than intended.
- **Why others work:** Standard strategies use `Input_SL_Points = 500` (50 pips), which results in normal sizing.

## 2. Required Fixes (Consolidated)

### 2.1 Parameter Standardization (DJay_Smart_Assistant.mq5)
**Action:** Align Quick Scalp inputs with the EA's "Points" standard.
- Update `Input_QS_TP_Points` default to `350` (35 pips).
- Update `Input_QS_SL_Points` default to `200` (20 pips).
- Update input comments to clearly state "(points)".

### 2.2 Risk Normalization Logic (DJay_Smart_Assistant.mq5)
**Action:** Decouple lot sizing from the tight Stop Loss distance.
- **Location:** `ExecuteQuickScalpTrade`.
- **Logic:** Scale the risk percentage relative to the standard 500-point Stop Loss.
  ```mql5
  double riskScale = (double)sl_points / 500.0; 
  req.risk_percent = dashboardPanel.GetRiskPercent() * riskScale;
  ```
- **Result:** Quick Scalp trades will now have the **same lot size** as standard Arrow/Rev/Break trades, ensuring account safety.

### 2.3 Secondary Safety Nets (TradeManager.mqh)
- **Margin Check:** Add `OrderCalcMargin` validation against `AccountInfoDouble(ACCOUNT_MARGIN_FREE)`.
- **PointValue Check:** Ensure `pointValue` is not < 0.01.

### 2.4 Signal Logic (SignalEngine.mqh)
- **ADX Timeframe:** Change `iADX` initialization from `PERIOD_CURRENT` to `PERIOD_M5`.
- **Advisor Text:** Add "Market Choppy (ADX Low)" status check.

## 3. Conclusion
Standardizing the parameters to "Points" fixes the math, and "Risk Normalization" fixes the aggressive leverage. Together, these ensure the Quick Scalp feature is safe and consistent with the rest of the EA.
