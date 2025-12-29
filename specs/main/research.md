# Phase 0: Research & Technical Decisions

**Input**: Feature Specification (`spec.md`), Project Constitution

## 1. Technical Architecture

### Decision: MQL5 Language (Single Source)
- **Choice**: Develop primarily in MQL5 (compatible with MT5), as it offers better object-oriented features, backtesting capabilities, and execution speed compared to MQL4.
- **Rationale**: The "Widwa Pa" technique requires multi-timeframe analysis (M5, H1, D1, H4) simultaneously. MQL5 handles multi-currency/multi-timeframe data access much more efficiently than MQL4.
- **Alternatives**: MQL4 (Too limited for complex panels), Python Bridge (Too much latency for visual panel updates).

### Decision: Event-Driven UI (Object-Based)
- **Choice**: Use standard `CChartObject` classes (Label, Edit, Button, RectLabel) managed via a custom `Panel` class.
- **Rationale**:
  - **Simplicity (Principle V)**: Canvas is powerful but requires manual pixel rendering and event handling logic that is prone to bugs.
  - **Performance**: Standard objects are hardware-accelerated by the terminal.
  - **Maintenance**: Easier to adjust X/Y coordinates of a `CButton` than to rewrite a canvas drawing function.

### Decision: Logic & View Separation
- **Choice**: Strict Model-View-Controller (MVC) adaptation.
  - **Model**: `SignalEngine` (Calculates Zones, PA, EMAs).
  - **View**: `DashboardPanel` (Draws buttons, labels, updates text).
  - **Controller**: `OnTick()` and `OnChartEvent()` handlers acting as the bridge.
- **Rationale**: Follows **Principle V (Simplicity & Robustness)**. Allows testing the Signal logic without needing the GUI to be active (e.g., in optimization mode).

## 2. Domain-Specific Research

### Zone Calculation Logic
- **Requirement**: Offsets from D1 Open (+/- 300, +/- 1000).
- **Implementation**:
  - `iOpen(Symbol(), PERIOD_D1, 0)` to get today's open.
  - **Edge Case**: Server time rollover. The EA must detect `New Day` event to reset zones.

### Price Action Detection
- **Patterns**: Hammer, Shooting Star, Engulfing.
- **Definition**:
  - **Hammer**: Lower shadow > 2x Body, Upper shadow small/none, Bullish/Bearish body allowed (context matters).
  - **Engulfing**: Current body completely covers previous body + opposite color.
- **Verification**: Must wait for candle Close (Shift 1) to confirm PA. "Live" PA detection (Shift 0) is unstable and violates **Principle II (Signal Precision)**.

### Session Timing
- **Data Source**: Broker Server Time (TimeCurrent).
- **Mapping**: User must map Server Time to Local Time or GMT to correctly identify "Asia" (08:00-10:00), "Europe" (13:30-16:00), "US" (19:30-22:00).
- **Solution**: Auto-detect GMT offset or provide simple input `ServerHourOffset`.

## 3. Risk Management Formula
- **Formula**: `Lot = (AccountBalance * RiskPercent / 100) / (SL_Points * TickValue)`
- **Constraints**:
  - `LotStep`: Round to nearest valid step (e.g., 0.01).
  - `MinLot/MaxLot`: Clamp values.
  - `TickValue`: Must be retrieved dynamically (`SymbolInfoDouble(SYMBOL_TRADE_TICK_VALUE)`).

## 4. Unknowns & Clarifications
- **Resolved**: "Signficant Numbers" from the book (ending in 00, 50, etc.) will be treated as additional visual guides, not hard entry filters, unless specified.
- **Resolved**: "First Touch" of EMA means price crosses or touches the line after having been away from it for X bars. We will define "Reset Logic" for EMA touches (e.g., must close above EMA for 5 bars before a new "Touch" counts).
