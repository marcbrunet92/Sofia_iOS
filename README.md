# Sofia iOS

iOS version of the Sofia Wind Farm app. It mirrors [Sofia_Android](https://github.com/marcbrunet92/Sofia_Android) screen for screen: same API, same data processing, same UI, same strings (English and French) and the same three home screen widgets.

Requirements: Xcode 26 or later, iOS 17 deployment target. The `Sofia` scheme is shared so Xcode Cloud can build it.

## Layout

| Folder | Content | Android equivalent |
| --- | --- | --- |
| `SofiaCore/` | Swift package shared by the app and the widget: constants, API client and DTOs, aggregation, local cache, repositories, widget data loading | `Constants.kt`, `data/`, `util/`, `widget/modern/SofiaWidgetData.kt`, `SofiaWidgetSnapshots.kt` |
| `Sofia/` | SwiftUI app: view models, screens, components, theme, string catalogs, assets | `MainActivity.kt`, `ui/`, `res/values*/strings.xml` |
| `Widget/` | WidgetKit extension: live production, availability by unit, configurable graph | `widget/modern/*GlanceWidget.kt`, `SofiaGraphConfig.kt` |
| `dev_utils/` | Source concatenation script | `dev_utils/` |

## Behaviour

- **Graph tab** (start tab): live production gauge (latest committed PN vs 1400 MW), dataset chips (weather, committed, actual), time window chips (6h … All) and a line chart with MW on the left axis and wind on the right axis. The chart can be scrolled and pinch-zoomed; a window chip zooms to that duration at the end of the data. Pull to refresh, automatic refresh every 60 s.
- **Alerts tab**: availability by unit computed from the active REMIT notices, notice cards and a detail screen. Pull to refresh, automatic refresh every 120 s.
- **Sofia tab**: description of the farm and location map.
- **Settings tab**: test mode (uses `T_HEYM11` instead of the four Sofia BMUs) and disclaimer.
- Data is cached on disk (JSON files replacing the Android Room database), so the last known values show immediately at launch and offline.

### Widgets

- **Sofia · Production** (small, medium): gauge, current committed MW, actual MW, update time.
- **Sofia · Availability by unit** (small, medium): REMIT availability of each unit.
- **Sofia · Graph** (medium, large): committed production (and actual production from 7 days) over a window chosen with *Edit Widget*.

Widgets fetch their own data from the API every ~30 minutes and fall back to their last successful snapshot when offline.

### Sharing test mode and cache with the widget

Without an App Group the widget cannot read the app's settings, so it always shows live (non-test) data. To share the test mode and the app cache with the widget, add the App Group `group.com.lemarc.Sofia` to both the `Sofia` and `WidgetExtension` targets (and regenerate their provisioning profiles). The code already uses it when it is available.

## Tests

`SofiaCore` has unit tests (date parsing, aggregation, records, availability by unit):

```bash
cd SofiaCore && swift test
```
