# Implementation Plan: EA Helper - Widwa Pa Trade Assistant

**Branch**: `001-ea-signal-panel` | **Date**: 2025-12-29 | **Spec**: [specs/main/spec.md](spec.md)
**Input**: Feature specification based on "Widwa Pa Trade Vol.2.1"

## Summary

Develop a MetaTrader 5 Expert Advisor (EA) that assists traders by automating the "Widwa Pa" strategy calculations. The EA will calculate daily Buy/Sell zones relative to the D1 open price, detect Price Action signals (Hammer, Engulfing) in real-time, and provide a dashboard panel for one-click execution with auto-calculated lot sizing based on risk percentage.

## Technical Context

**Language/Version**: MQL5 (compatible with MT5)
**Primary Dependencies**: Standard Library (`Trade\Trade.mqh`, `ChartObjects\ChartObjectsTxtControls.mqh`)
**Storage**: N/A (Runtime calculation only, minimal state persistence if needed via GlobalVariables)
**Testing**: MetaTrader 5 Strategy Tester (Visual Mode)
**Target Platform**: Windows (MT5 Desktop Terminal)
**Project Type**: Single Expert Advisor (EA)
**Performance Goals**: <1ms execution time per tick, UI updates <16ms (60fps target for smooth panel)
**Constraints**: Must handle connection drops, requotes, and invalid stops gracefully.
**Scale/Scope**: Single user, Single chart focus (XAUUSD primarily).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Automation Over Manual Calculation**: Plan automates Zone and Lot math.
- [x] **II. Signal Precision**: Plan specifies waiting for Candle Close (Shift 1) for PA.
- [x] **III. Integrated Risk Management**: Plan includes `TradeManager` with strict Risk % logic.
- [x] **IV. Visual-First UX**: Panel design is central to the architecture.
- [x] **V. Simplicity**: Using standard Objects instead of Canvas for easier maintenance.

## Project Structure

### Documentation (this feature)

```text
specs/main/
├── plan.md              # This file
├── research.md          # Technical decisions (MQL5, Objects, Timeframes)
├── data-model.md        # Class structure (SignalEngine, TradeManager)
├── quickstart.md        # User guide
└── contracts/           # (N/A for local EA)
```

### Source Code (repository root)

```text
MQL5/
├── Experts/
│   └── WidwaPa_Assistant.mq5       # Main entry point (OnTick, OnTimer)
├── Include/
│   └── EA_Helper/
│       ├── SignalEngine.mqh        # Logic: Zones, PA, Trends
│       ├── TradeManager.mqh        # Logic: Risk, Orders
│       └── DashboardPanel.mqh      # View: UI Objects management
└── Images/                         # (Optional) Icons
```

**Structure Decision**: Standard MQL5 Expert Advisor structure with modular `.mqh` include files for separation of concerns.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Custom Panel Class | UX Requirement | Standard `Comment()` is insufficient for interactive buttons/risk management. |