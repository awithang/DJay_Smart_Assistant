1 I need you to act as an implementation agent for a MetaTrader 5 Expert Advisor project. We have completed the specification, planning, and task
      breakdown phases.
    2
    3 Please read the following context files to understand the project:
    4 1. `specs/main/plan.md` (Technical Plan)
    5 2. `specs/main/data-model.md` (Class Structure)
    6 3. `specs/main/tasks.md` (Task List)
    7 4. `specs/main/checklists/ea_impl.md` (Requirement Checklist)
    8
    9 **Objective:**
   10 Start implementing **Phase 1 (Setup)** and **Phase 2 (Foundational)** tasks from `specs/main/tasks.md`.
   11
   12 **Tasks to cover (Phase 1 & 2):**
   13 - T001: Create project folder structure (`Experts/EA_Helper`, `Include/EA_Helper`)
   14 - T002: Create main EA file `WidwaPa_Assistant.mq5`
   10 Start implementing **Phase 1 (Setup)** and **Phase 2 (Foundational)** tasks from `specs/main/tasks.md`.
   11
   12 **Tasks to cover (Phase 1 & 2):**
   13 - T001: Create project folder structure (`Experts/EA_Helper`, `Include/EA_Helper`)
   14 - T002: Create main EA file `WidwaPa_Assistant.mq5`
   11
   12 **Tasks to cover (Phase 1 & 2):**
   13 - T001: Create project folder structure (`Experts/EA_Helper`, `Include/EA_Helper`)
   14 - T002: Create main EA file `WidwaPa_Assistant.mq5`
   13 - T001: Create project folder structure (`Experts/EA_Helper`, `Include/EA_Helper`)
   14 - T002: Create main EA file `WidwaPa_Assistant.mq5`
   14 - T002: Create main EA file `WidwaPa_Assistant.mq5`
   15 - T003: Create `Definitions.mqh`
   16 - T004: Create empty class files (`SignalEngine.mqh`, `TradeManager.mqh`, `DashboardPanel.mqh`)
   17 - T005: Implement `CSignalEngine` base class
   17 - T005: Implement `CSignalEngine` base class
   18 - T006: Implement `CTradeManager` base class
   19 - T007: Implement `CDashboardPanel` base class
   20 - T008: Integrate classes into the main EA
   20 - T008: Integrate classes into the main EA
   21
   22 **Strict Requirements:**
   23 - **File Paths**: Use the exact absolute paths defined in `tasks.md`.
   24 - **Class Structure**: Follow the C++ class definitions in `data-model.md` exactly.
   25 - **Skeleton Code**: **Do not** implement the complex logic for User Stories (Zones, Signals, Risk) yet. Keep methods empty or return default values.
      are verifying the architecture and compilation first.
   26 - **Compilation**: Ensure the code is valid MQL5 syntax and will compile without errors.
   27
   28 Please generate the code for these files one by one.
