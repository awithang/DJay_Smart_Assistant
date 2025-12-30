# Feature Specification: EA Helper - Widwa Pa Trade Assistant

**Feature Branch**: `001-ea-signal-panel`  
**Created**: 2025-12-29  
**Status**: Draft  
**Input**: User description: "Develop an EA that displays trade signals on a panel based on the 'Widwa Pa Trade Vol.2.1' technique, with a UI inspired by xCS_Panel."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Daily Trading Zone Visualization (Priority: P1)

As a trader, I want the EA to automatically calculate and display the daily trading zones (Buy Zone/Sell Zone) based on the D1 open price and significant numbers, so that I can identify high-probability entry areas without manual calculation.

**Why this priority**: This is the foundation of the "Widwa Pa Trade" technique. Identifying the +/- 300 and +/- 1000 point zones from the daily open is the first step in the trading plan.

**Independent Test**: Can be tested by verifying that the EA correctly identifies the D1 open price and draws the horizontal zones at the correct distances (e.g., 300, 1000 points) on the chart.

**Acceptance Scenarios**:

1. **Given** the market has just opened for a new day, **When** the EA is loaded, **Then** it must fetch the D1 open price and draw the Buy/Sell zones (+/- 300, +/- 1000 points).
2. **Given** the price enters the +300 to +1000 zone, **When** looking at the panel, **Then** the "Sell Zone" status should be highlighted.

---

### User Story 2 - Real-time Signal Detection & Display (Priority: P2)

As a trader, I want to see a clear "Signal" on the panel when conditions from the book are met (Price Action at zones, EMA touches, or Trend alignment), so that I don't miss trading opportunities.

**Why this priority**: This automates the "wait for signal" part of the technique, reducing cognitive load and emotional trading.

**Independent Test**: Can be tested by simulating a Price Action pattern (e.g., Hammer) at a pre-defined resistance zone and checking if the panel displays a "BUY SIGNAL".

**Acceptance Scenarios**:

1. **Given** the price is at a H1 Resistance Zone, **When** a Bearish Engulfing PA occurs on H1, **Then** the panel must display "H1 SELL SIGNAL".
2. **Given** the price touches EMA 200 for the first time in a trending market, **When** M5 PA occurs, **Then** the panel must display "EMA TOUCH SIGNAL".

---

### User Story 3 - Risk Management & Order Execution Panel (Priority: P3)

As a trader, I want a panel that calculates the correct Lot Size based on my defined Risk % and SL distance (200-300 points), and allows me to execute the trade with one click.

**Why this priority**: Ensures consistent risk management (Chapter 6 of the book) and allows for fast execution once a signal is confirmed.

**Independent Test**: Can be tested by entering a Risk % (e.g., 3%) and a SL distance, then verifying the calculated Lot Size against a manual calculation.

**Acceptance Scenarios**:

1. **Given** a 1000$ balance and 3% risk, **When** the SL is set to 300 points, **Then** the calculated Lot Size must be 0.10 (for Gold 100oz contract) or equivalent.
2. **Given** a signal is confirmed, **When** the "CONFIRM ORDER" button is pressed, **Then** the EA must open the trade with the calculated Lot, SL, and TP.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST calculate Daily Zones based on D1 Open Price and Significant Numbers (+/- 300, +/- 1000 points).
- **FR-002**: System MUST detect and display current Market Session (Asia, Europe, US) based on server time.
- **FR-003**: System MUST identify Price Action patterns (Hammer, Shooting Star, Engulfing) on M5 and H1.
- **FR-004**: System MUST monitor EMA 100, 200, and 720 for "First Touch" signals.
- **FR-005**: System MUST calculate Lot Size dynamically: `Lot = (Balance * Risk%) / (SL_Points * TickValue)`.
- **FR-006**: System MUST display a Signal Dashboard showing Trend alignment (D1, H4, H1).
- **FR-007**: System MUST provide a UI Panel with buttons for Buy/Sell, Risk % setting, and Order Confirmation.

### Key Entities

- **TradingZone**: Represents a price range calculated from D1 Open (e.g., Sell Zone 1, Buy Zone 2).
- **Signal**: A confirmed setup based on Zone + PA + Time + Trend.
- **PositionConfig**: User settings for Risk %, SL Buffer, and TP Ratio.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zone calculation matches manual D1 Open + Offset calculation with 100% accuracy.
- **SC-002**: Signal detection latency is less than 1 second from the close of the candle.
- **SC-003**: Lot Size calculation ensures that a hit SL never loses more than the user-defined Risk % (within slippage limits).
- **SC-004**: UI Panel remains responsive and updates price/profit data at every tick.
