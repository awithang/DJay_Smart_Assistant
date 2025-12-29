# Quickstart: Building & Running the EA

## Prerequisites

1.  **MetaTrader 5 Terminal**: Installed and logged in.
2.  **MetaEditor**: For compiling `.mq5` files.
3.  **Project Structure**:
    - `MQL5/Experts/EA_Helper/` - Root folder.
    - `MQL5/Include/EA_Helper/` - Shared headers/classes.
    - `MQL5/Images/EA_Helper/` - (Optional) Icons for the panel.

## Installation

1.  **Copy Source**:
    - Place `WidwaPa_Assistant.mq5` into `MQL5/Experts/EA_Helper/`.
    - Place classes (`SignalEngine.mqh`, `TradeManager.mqh`, `DashboardPanel.mqh`) into `MQL5/Include/EA_Helper/`.

2.  **Compile**:
    - Open `WidwaPa_Assistant.mq5` in MetaEditor.
    - Press **F7** (Compile). Ensure 0 Errors.

## Running the EA

1.  **Open Chart**: XAUUSD (Gold), Timeframe M5 or H1 (as per strategy).
2.  **Attach EA**: Drag "WidwaPa_Assistant" from Navigator to the chart.
3.  **Allow Algo Trading**: Ensure the "Algo Trading" button in MT5 toolbar is Green.
4.  **Configure Inputs**:
    - **Risk %**: Set to your desired risk (e.g., 2.0).
    - **GMT Offset**: Adjust if your broker time doesn't match standard sessions.

## Usage Guide

1.  **Zone Monitor**: Look at the "Daily Zones" section.
    - If Price > **Sell Zone (+300)**, look for Sell Signals.
    - If Price < **Buy Zone (-300)**, look for Buy Signals.
2.  **Signal Alert**:
    - Wait for "PA SIGNAL" or "EMA TOUCH" to flash on the panel.
3.  **Execution**:
    - When a signal appears, check the calculated "Lot Size" on the panel.
    - Click **BUY** or **SELL** button to execute instantly with preset SL/TP.

## Troubleshooting

-   **Panel looks weird**: Change chart resolution or font size scale (Windows Display Settings).
-   **No Trade**: Check "Journal" tab for error messages (e.g., "Not enough money", "Trading disabled").
-   **Wrong Zones**: Verify `D1 Open` price on the chart matches the broker's daily candle.
