---
description: "Task list for EA Helper - Widwa Pa Trade Assistant"
---

# Tasks: EA Helper - Widwa Pa Trade Assistant

**Input**: Design documents from `specs/main/`
**Prerequisites**: plan.md (required), spec.md (required), data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: [US1] (Zones), [US2] (Signals), [US3] (Risk Panel)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create MQL5 project folder structure (`Experts/EA_Helper`, `Include/EA_Helper`)
- [ ] T002 Create main EA file `MQL5/Experts/EA_Helper/WidwaPa_Assistant.mq5` with OnTick/OnInit handlers
- [ ] T003 Create shared definitions header `MQL5/Include/EA_Helper/Definitions.mqh` (enums, constants)
- [ ] T004 [P] Create empty class files (`SignalEngine.mqh`, `TradeManager.mqh`, `DashboardPanel.mqh`)

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core logic required by all stories

- [ ] T005 Implement `CSignalEngine` base class with `RefreshData()` method in `MQL5/Include/EA_Helper/SignalEngine.mqh`
- [ ] T006 Implement `CTradeManager` base class in `MQL5/Include/EA_Helper/TradeManager.mqh`
- [ ] T007 Implement `CDashboardPanel` base class in `MQL5/Include/EA_Helper/DashboardPanel.mqh`
- [ ] T008 Integrate classes into main EA `WidwaPa_Assistant.mq5` (Include and Instantiate)

**Checkpoint**: EA compiles without errors and loads on chart (even if empty).

---

## Phase 3: User Story 1 - Daily Trading Zone Visualization (Priority: P1)

**Goal**: Automate daily zone calculation (+/- 300, 1000 points) and display on chart.

**Independent Test**: Attach EA, verify horizontal lines/zones appear at correct D1 Open offsets.

### Implementation for User Story 1

- [ ] T009 [US1] Implement `GetZoneLevel` logic in `SignalEngine.mqh` (D1 Open + Offset)
- [ ] T010 [US1] Add `DrawZones` method to `DashboardPanel.mqh` to render visual lines
- [ ] T011 [US1] Link `SignalEngine` zone data to `DashboardPanel` rendering in `OnTick`
- [ ] T012 [US1] Add `Input_Zone_Offset` parameters to main EA file

**Checkpoint**: Zones appear correctly on chart relative to daily open.

---

## Phase 4: User Story 2 - Real-time Signal Detection & Display (Priority: P2)

**Goal**: Detect PA (Hammer, Engulfing) and EMA touches, display alerts.

**Independent Test**: Use Strategy Tester visually to see "SIGNAL" label appear when PA pattern occurs.

### Implementation for User Story 2

- [ ] T013 [P] [US2] Implement `IsHammer`, `IsShootingStar` logic in `SignalEngine.mqh`
- [ ] T014 [P] [US2] Implement `IsEngulfing` logic in `SignalEngine.mqh`
- [ ] T015 [P] [US2] Implement `CheckEMATouch` logic in `SignalEngine.mqh` (EMA 100/200/720)
- [ ] T016 [US2] Add `UpdateSignalDisplay` to `DashboardPanel.mqh` to show text alerts
- [ ] T017 [US2] Wire `SignalEngine` detection to `DashboardPanel` update in main EA

**Checkpoint**: Panel displays accurate text signals when patterns occur in Strategy Tester.

---

## Phase 5: User Story 3 - Risk Management & Order Execution Panel (Priority: P3)

**Goal**: One-click trading with auto-calculated lot size based on risk.

**Independent Test**: Click Buy button, verify Order opened with correct Lot Size for the Risk %.

### Implementation for User Story 3

- [ ] T018 [P] [US3] Implement `CalculateLotSize` in `TradeManager.mqh` (Risk math)
- [ ] T019 [P] [US3] Implement `ExecuteOrder` in `TradeManager.mqh` using `CTrade`
- [ ] T020 [US3] Add interactive UI (Buttons, Edit Box) to `DashboardPanel.mqh`
- [ ] T021 [US3] Implement `OnChartEvent` handler in main EA to capture button clicks
- [ ] T022 [US3] Connect Button Click -> `TradeManager::ExecuteOrder` logic

**Checkpoint**: Full functional panel allowing trade execution.

---

## Final Phase: Polish & Cross-Cutting Concerns

- [ ] T023 [P] Add error handling for invalid inputs (e.g., Risk > 10%)
- [ ] T024 [P] Optimize `OnTick` (don't redraw panel if nothing changed)
- [ ] T025 [P] Add "Session" clock display to Panel (Asia/Europe/US)
- [ ] T026 Add tooltips/comments for user guidance

---

## Implementation Strategy

### Incremental Delivery

1.  **Skeleton (Phase 1-2)**: Get a blank EA that compiles and runs.
2.  **Zones (Phase 3)**: Get the visual lines working (Visual confirmation).
3.  **Signals (Phase 4)**: Add the "Brain" to detect patterns.
4.  **Trading (Phase 5)**: Add the "Hands" to execute trades.
