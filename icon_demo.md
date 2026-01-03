# Icon Demo: Wingdings vs Unicode

## Visual Comparison

### Wingdings Icons (Classic/Professional)

| Code | Icon | Button Preview | Usage |
|------|------|----------------|-------|
| `P` | ⚙ | `[P]` → ⚙️ | Settings/Properties |
| `!` | `!` | `[!]` → 📋 | Clipboard/Reports |
| `N` | `N` | `[N]` → 📊 | Bar Chart |
| `O` | `O` | `[O` → 📈 | Line Chart |
| `4` | ✋ | `[4]` → ✋ | Manual Trade |
| `8` | ✉ | `[8]` → ✉️ | Messages/Alerts |
| `q` | ▶ | `[q]` → ▶️ | Start/Run |
| `r` | ⏸ | `[r]` → ⏸️ | Stop/Pause |

### Unicode Icons (Modern/Emoji-style)

| Code | Icon | Button Preview | Usage |
|------|------|----------------|-------|
| `⚙` | ⚙️ | `[⚙]` → ⚙️ | Settings |
| `📋` | 📋 | `[📋]` → 📋 | Clipboard/Reports |
| `📊` | 📊 | `[📊]` → 📊 | Statistics |
| `📈` | 📈 | `[📈]` → 📈 | Charts |
| `💾` | 💾 | `[💾]` → 💾 | Save |
| `🔄` | 🔄 | `[🔄]` → 🔄 | Refresh |

---

## Side-by-Side Button Comparison

### 20x20 Buttons

| Style | Settings Icon | Reports Icon |
|-------|---------------|--------------|
| **Wingdings** | `[P]` | `⚙️` | `[!]` | `!` | |
| **Unicode** | `[⚙]` | `⚙️` | `[📋]` | `📋` | |

### 24x24 Buttons

| Style | Settings Icon | Reports Icon |
|-------|---------------|--------------|
| **Wingdings** | `[P]` | `⚙️` (larger) | `[!]` | `!` | (larger) |
| **Unicode** | `[⚙]` | `⚙️` (larger) | `[📋]` | `📋` | (larger) |

---

## Recommended Setup for Your EA

### Option A: Wingdings (Professional)

```cpp
// Settings button (gear icon)
CreateButton("BtnSettings", x, y, 20, 20, "P", clrGray, clrWhite, 12);
ObjectSetString(chart_id, "EA_BtnSettings", OBJPROP_FONT, "Wingdings");

// Reports button (clipboard icon)
CreateButton("BtnReports", x + 25, y, 20, 20, "!", clrGray, clrWhite, 12);
ObjectSetString(chart_id, "EA_BtnReports", OBJPROP_FONT, "Wingdings");
```

**Visual Result:**
```
┌─────────────────────────────────────┐
│  [EXECUTION]          Price  ⚙ 📋   │  ← Clean, professional
│                                     │
│      [  BUY  ]  [  SELL  ]          │
└─────────────────────────────────────┘
```

### Option B: Unicode (Modern)

```cpp
// Settings button (gear icon)
CreateButton("BtnSettings", x, y, 20, 20, "⚙", clrGray, clrWhite, 12);

// Reports button (clipboard icon)
CreateButton("BtnReports", x + 25, y, 20, 20, "📋", clrGray, clrWhite, 12);
```

**Visual Result:**
```
┌─────────────────────────────────────┐
│  [EXECUTION]          Price  ⚙️ 📋   │  ← Modern, colorful
│                                     │
│      [  BUY  ]  [  SELL  ]          │
└─────────────────────────────────────┘
```

---

## My Personal Recommendation

**Go with Wingdings** for a trading terminal because:

| Pro | Reason |
|-----|--------|
| ✅ | Looks like traditional financial software |
| ✅ | Sharp at any size (no emoji blurriness) |
| ✅ | Black & white (no color distraction) |
| ✅ | Always consistent across Windows versions |
| ✅ | Feels more "professional" than emojis |

**Icon mapping for your use case:**
- `P` (⚙️) → Open Properties window
- `!` (! → 📋) → Open Trade Statistics report

---

## Quick Test in Your EA

To see the difference immediately, you can test both:

```cpp
// Test both side by side temporarily
CreateLabel("Test1", x, y, "Wingdings [P]: ", clrGray, 9);
CreateLabel("Test2", x + 100, y, "⚙", clrWhite, 16);  // Change font to Wingdings for this
ObjectSetString(chart_id, "Test2", OBJPROP_FONT, "Wingdings");

CreateLabel("Test3", x, y + 20, "Unicode [⚙]: ⚙", clrGray, 9);
```

This will show you both approaches instantly on your chart so you can decide!
