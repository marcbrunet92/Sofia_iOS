Sofia App Capabilities & UI/UX Technical Documentation

This document provides a detailed breakdown of the Sofia Android app's capabilities, UI structure, and data architecture to facilitate its implementation in Swift.
⸻
1. UI Architecture & Navigation

The app uses a Bottom Navigation Bar as the primary navigation pattern, complemented by a Horizontal Pager in the main production view.

A. Production Tab (The Primary Dashboard)
This tab features a "Composite Screen" that allows switching between two distinct data views using a Floating Pager Slider.

* Panel 1: Production (Planned Output)
    * Gauge Card: A circular or semi-circular gauge displaying current_mw vs max_capacity_mw.
    * Interactive Chart: A line chart showing PN (Planned Production) levels. Supports time window selection (6h, 24h, 48h, 7d, All).
    * Records Card: Displays top production values for different windows (7d, 30d, 90d, All Time).
    * Metadata: Shows the timestamp of the latest data point and the last successful fetch time.
* Panel 2: Real Output (Metered Data)
    * Similar structure to the Production panel but focuses on B1610 (Real Output) data.
    * Quantities are typically displayed in MW (calculated from MWh).

B. Graph Tab (Multi-Series Analysis)
A dedicated screen for correlation analysis.
* Dataset Selector: Toggle buttons (Filter Chips) to show/hide Wind Speed, PN, and Real Output.
* Dual-Axis Chart:
    * Left Y-Axis: Power output in MW.
    * Right Y-Axis: Wind speed in m/s.
* Time Window Selection: Synchronization of all series across the selected time frame.

C. REMIT Tab (Market Transparency)
* Notice List: A scrollable list of RemitNoticeCard elements showing active market notices.
* Filtering/Status: Distinguishes between active and historical events.
* Detail View: A dedicated drill-down screen (triggered on card click) showing:
    * Event headers and status chips.
    * Capacity Section: Normal, Available, and Unavailable MW.
    * Timeline Section: Event start, end, and publication times.
    * Asset Info: BMU ID, Participant ID, Asset ID.
    * Description: Detailed "Cause" and "Related Information" text blocks.
    * Outage Profile: Technical breakdown of the event's progression.

D. Weather Tab
* Wind Speed View: Dedicated focus on environmental data with a trend chart and current status.

E. Settings Tab
* Test Mode Toggle: Switches the entire app's data source from production BMUs to a test BMU (T_HEYM11).
⸻
2. Data Models & API Interface

The app interacts with a REST API. All timestamps are handled in UTC.

Core Data Structures
Model    Key Fields    Description
PnEntry    bmu_id, time_from, time_to, level_mw    Planned production levels.
B1610Entry    bmu_id, time_from, time_to, quantity    Actual metered output.
WeatherEntry    time_from, time_to, wind_speed    Environmental wind data.
RemitNotice    mrid, event_status, event_type, capacity_mw (Normal/Avail/Unavail), cause    Market transparency notices.
TopProduction    max_mw, max_date    Record-breaking production values.

Data Transformations
* Aggregation: Data from multiple BMUs is summed at the repository level to provide a "Total Sofia" view.
* Filtering: Clientside filtering based on TimeWindow (6h, 24h, etc.) using Instant comparisons.
* MW Conversion: B1610 data (often received as quantity per settlement period) is scaled to MW for visual consistency with PN data.
⸻
3. Interactive Features

* Pull-to-Refresh: Standardized across all data screens using Material 3 PullToRefreshBox.
* Floating Slider: Custom UI component for high-frequency switching between PN and B1610 views.
* Back Handling: Custom logic to navigate from REMIT details back to the list using the system back gesture.
* Error Banners: Non-intrusive, dismissible banners for network or API errors.
* Empty States: Context-aware cards displayed when no data is available for a selected time window.

Here is the model used : 
package com.lemarc.sofia.data.model

import java.time.Instant

data class GraphPoint( 
val id: String, 
val timeFrom: Instant, 
val timeTo: Instant, 
val quantity: Double, 
)

data class B1610Snapshot( 
val points: List<GraphPoint>, 
val latestDataTimestamp: Instant?, 
val topB1610: TopWindows, 
)

data class WeatherSnapshot( 
val points: List<GraphPoint>, 
val latestWindSpeed: Double?, 
val latestDataTimestamp: Instant?, 
)

data class ProductionSnapshot( 
val points: List<GraphPoint>, 
val currentMw: Double, 
val latestDataTimestamp: Instant?, 
val topProduction: TopWindows, 
)

data class TopPoint( 
val maxQuantity: Double, 
val maxDate: Instant?, 
)

data class TopWindows( 
val allTime: TopPoint, 
val last7Days: TopPoint, 
val last30Days: TopPoint, 
val last90Days: TopPoint, 
) { 
companion object { 
val Empty = TopWindows( 
allTime = TopPoint(0.0, null), 
last7Days = TopPoint(0.0, null), 
last30Days = TopPoint(0.0, null), 
last90Days = TopPoint(0.0, null), 
) 
} 
}

data class RemitNotice( 
val id: Int, 
val mrid: String, 
val revisionNumber: Int, 
val bmuId: String, 
val participantId: String, 
val assetId: String, 
val unavailabilityType: String, 
val eventType: String, 
val messageHeading: String, 
val fuelType: String, 
val normalCapacityMw: Double?, 
val availableCapacityMw: Double?, 
val unavailableCapacityMw: Double?, 
val eventStatus: String, 
val eventStartTime: Instant?, 
val eventEndTime: Instant?, 
val cause: String, 
val relatedInformation: String, 
val publishTime: Instant?, 
val outageProfile: String, 
)


{"openapi":"3.1.0","info":{"title":"Sofia Wind Farm API","version":"0.1.0"},"paths":{"/pn/date-range":{"get":{"tags":["PN"],"summary":"Pn Date Range","operationId":"pn_date_range_pn_date_range_get","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/PnDateRange"}}}}}}},"/pn/latest-settlement-period":{"get":{"tags":["PN"],"summary":"Pn Latest Settlement","operationId":"pn_latest_settlement_pn_latest_settlement_period_get","parameters":[{"name":"bmu_id","in":"query","required":false,"schema":{"anyOf":[{"type":"string"},{"type":"null"}],"title":"Bmu Id"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/PnLatestSettlementPeriod"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/pn/refresh":{"post":{"tags":["PN"],"summary":"Force Refresh Pn","operationId":"force_refresh_pn_pn_refresh_post","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{}}}}}}},"/pn/top-production":{"get":{"tags":["PN"],"summary":"Top Production Windows","operationId":"top_production_windows_pn_top_production_get","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/PnTopProductionWindows"}}}}}}},"/pn/{bmu_id}":{"get":{"tags":["PN"],"summary":"Get Pn","operationId":"get_pn_pn__bmu_id__get","parameters":[{"name":"bmu_id","in":"path","required":true,"schema":{"type":"string","title":"Bmu Id"}},{"name":"time_from","in":"query","required":true,"schema":{"type":"string","format":"date-time","title":"Time From"}},{"name":"time_to","in":"query","required":true,"schema":{"type":"string","format":"date-time","title":"Time To"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"type":"array","items":{"$ref":"#/components/schemas/PnResponse"},"title":"Response Get Pn Pn  Bmu Id  Get"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/remit":{"get":{"tags":["REMIT"],"summary":"List Remits","operationId":"list_remits_remit_get","parameters":[{"name":"bmu_id","in":"query","required":false,"schema":{"anyOf":[{"type":"string"},{"type":"null"}],"title":"Bmu Id"}},{"name":"event_status","in":"query","required":false,"schema":{"anyOf":[{"type":"string"},{"type":"null"}],"title":"Event Status"}},{"name":"limit","in":"query","required":false,"schema":{"type":"integer","maximum":500,"default":100,"title":"Limit"}},{"name":"offset","in":"query","required":false,"schema":{"type":"integer","minimum":0,"default":0,"title":"Offset"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"type":"array","items":{"$ref":"#/components/schemas/RemitResponse"},"title":"Response List Remits Remit Get"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/remit/active/{bmu_id}":{"get":{"tags":["REMIT"],"summary":"Active Remits","operationId":"active_remits_remit_active__bmu_id__get","parameters":[{"name":"bmu_id","in":"path","required":true,"schema":{"type":"string","title":"Bmu Id"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"type":"array","items":{"$ref":"#/components/schemas/RemitResponse"},"title":"Response Active Remits Remit Active  Bmu Id  Get"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/remit/{remit_id}":{"get":{"tags":["REMIT"],"summary":"Get Remit","operationId":"get_remit_remit__remit_id__get","parameters":[{"name":"remit_id","in":"path","required":true,"schema":{"type":"integer","title":"Remit Id"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/RemitResponse"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/remit/refresh":{"post":{"tags":["REMIT"],"summary":"Force Refresh Remit","description":"Force an immediate re-fetch of all active REMIT records from Elexon API.\n\nUseful after an incident, or to force an update without waiting for HH:00.\nReturns the number of persisted records.","operationId":"force_refresh_remit_remit_refresh_post","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{}}}}}}},"/weather/date-range":{"get":{"tags":["Weather"],"summary":"Weather Date Range","operationId":"weather_date_range_weather_date_range_get","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/WeatherDateRange"}}}}}}},"/weather/latest":{"get":{"tags":["Weather"],"summary":"Weather Latest","operationId":"weather_latest_weather_latest_get","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/WeatherLatestTimestamp"}}}}}}},"/weather":{"get":{"tags":["Weather"],"summary":"Get Weather","operationId":"get_weather_weather_get","parameters":[{"name":"time_from","in":"query","required":true,"schema":{"type":"string","format":"date-time","title":"Time From"}},{"name":"time_to","in":"query","required":true,"schema":{"type":"string","format":"date-time","title":"Time To"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"type":"array","items":{"$ref":"#/components/schemas/WeatherResponse"},"title":"Response Get Weather Weather Get"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/visual/pn":{"get":{"tags":["Visualisation"],"summary":"Visualise Sofia PN generation (full + 48h zoom)","description":"Returns an HTML report with 2 matplotlib charts for aggregated generation of the 4 Sofia BMUs (T_SOFOW-11/12/21/22): full period and recent zoom.","operationId":"visualise_pn_generation_visual_pn_get","parameters":[{"name":"from_date","in":"query","required":false,"schema":{"type":"string","format":"date-time","description":"Period start (UTC). Default: 2026-04-01T00:00:00Z.","default":"2026-04-01T00:00:00Z","title":"From Date"},"description":"Period start (UTC). Default: 2026-04-01T00:00:00Z."},{"name":"to_date","in":"query","required":false,"schema":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"description":"Period end (UTC). Default: latest available data.","title":"To Date"},"description":"Period end (UTC). Default: latest available data."},{"name":"zoom_hours","in":"query","required":false,"schema":{"type":"integer","maximum":168,"minimum":1,"description":"Zoom window (hours) at end of series. Default: 48.","default":48,"title":"Zoom Hours"},"description":"Zoom window (hours) at end of series. Default: 48."}],"responses":{"200":{"description":"HTML report with base64-encoded charts.","content":{"text/html":{"schema":{"type":"string"}}}},"400":{"description":"Invalid request (from_date > to_date)."},"404":{"description":"No generation data available for requested period."},"422":{"description":"Validation error (e.g. invalid zoom_hours) or requested to_date is too recent (beyond latest available data)."}}}},"/visual/all":{"get":{"tags":["Visualisation"],"summary":"Visualise Sofia generation with weather overlay","operationId":"visualise_generation_and_weather_visual_all_get","parameters":[{"name":"from_date","in":"query","required":false,"schema":{"type":"string","format":"date-time","description":"Period start (UTC). Default: 2026-04-01T00:00:00Z.","default":"2026-04-01T00:00:00Z","title":"From Date"},"description":"Period start (UTC). Default: 2026-04-01T00:00:00Z."},{"name":"to_date","in":"query","required":false,"schema":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"description":"Period end (UTC). Default: latest shared timestamp.","title":"To Date"},"description":"Period end (UTC). Default: latest shared timestamp."},{"name":"zoom_hours","in":"query","required":false,"schema":{"type":"integer","maximum":168,"minimum":1,"default":48,"title":"Zoom Hours"}}],"responses":{"200":{"description":"Successful Response","content":{"text/html":{"schema":{"type":"string"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/visual/b1610":{"get":{"tags":["Visualisation"],"summary":"Visualise Sofia B1610 generation (full + 48h zoom)","operationId":"visualise_b1610_generation_visual_b1610_get","parameters":[{"name":"from_date","in":"query","required":false,"schema":{"type":"string","format":"date-time","description":"Period start (UTC). Default: 2026-04-01T00:00:00Z.","default":"2026-04-01T00:00:00Z","title":"From Date"},"description":"Period start (UTC). Default: 2026-04-01T00:00:00Z."},{"name":"to_date","in":"query","required":false,"schema":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"description":"Period end (UTC). Default: latest available data.","title":"To Date"},"description":"Period end (UTC). Default: latest available data."},{"name":"zoom_hours","in":"query","required":false,"schema":{"type":"integer","maximum":168,"minimum":1,"description":"Zoom window (hours) at end of series. Default: 48.","default":48,"title":"Zoom Hours"},"description":"Zoom window (hours) at end of series. Default: 48."}],"responses":{"200":{"description":"Successful Response","content":{"text/html":{"schema":{"type":"string"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/b1610/latest-settlement-period":{"get":{"tags":["B1610"],"summary":"B1610 Latest Settlement","operationId":"b1610_latest_settlement_b1610_latest_settlement_period_get","parameters":[{"name":"bmu_id","in":"query","required":false,"schema":{"anyOf":[{"type":"string"},{"type":"null"}],"title":"Bmu Id"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/B1610LatestSettlementPeriod"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}},"/b1610/top-production":{"get":{"tags":["B1610"],"summary":"Top Production Windows","operationId":"top_production_windows_b1610_top_production_get","responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"$ref":"#/components/schemas/B1610TopProductionWindows"}}}}}}},"/b1610/{bmu_id}":{"get":{"tags":["B1610"],"summary":"Get B1610","operationId":"get_b1610_b1610__bmu_id__get","parameters":[{"name":"bmu_id","in":"path","required":true,"schema":{"type":"string","title":"Bmu Id"}},{"name":"time_from","in":"query","required":true,"schema":{"type":"string","format":"date-time","title":"Time From"}},{"name":"time_to","in":"query","required":true,"schema":{"type":"string","format":"date-time","title":"Time To"}}],"responses":{"200":{"description":"Successful Response","content":{"application/json":{"schema":{"type":"array","items":{"$ref":"#/components/schemas/B1610Response"},"title":"Response Get B1610 B1610  Bmu Id  Get"}}}},"422":{"description":"Validation Error","content":{"application/json":{"schema":{"$ref":"#/components/schemas/HTTPValidationError"}}}}}}}},"components":{"schemas":{"B1610LatestSettlementPeriod":{"properties":{"bmu_id":{"type":"string","title":"Bmu Id"},"settlement_period":{"anyOf":[{"type":"integer"},{"type":"null"}],"title":"Settlement Period"},"time_from":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Time From"}},"type":"object","required":["bmu_id","settlement_period","time_from"],"title":"B1610LatestSettlementPeriod"},"B1610Response":{"properties":{"bmu_id":{"type":"string","title":"Bmu Id"},"time_from":{"type":"string","format":"date-time","title":"Time From"},"time_to":{"type":"string","format":"date-time","title":"Time To"},"quantity":{"type":"number","title":"Quantity"},"settlement_period":{"type":"integer","title":"Settlement Period"}},"type":"object","required":["bmu_id","time_from","time_to","quantity","settlement_period"],"title":"B1610Response","description":"RÃ©ponse API."},"B1610TopProductionPoint":{"properties":{"quantity":{"type":"number","title":"Quantity","default":0.0},"max_date":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Max Date"}},"type":"object","title":"B1610TopProductionPoint"},"B1610TopProductionWindows":{"properties":{"all_time":{"$ref":"#/components/schemas/B1610TopProductionPoint","description":"Top production for all available data."},"last_7_days":{"$ref":"#/components/schemas/B1610TopProductionPoint","description":"Top production over the last 7 days."},"last_30_days":{"$ref":"#/components/schemas/B1610TopProductionPoint","description":"Top production over the last 30 days."},"last_90_days":{"$ref":"#/components/schemas/B1610TopProductionPoint","description":"Top production over the last 90 days."}},"type":"object","required":["all_time","last_7_days","last_30_days","last_90_days"],"title":"B1610TopProductionWindows"},"HTTPValidationError":{"properties":{"detail":{"items":{"$ref":"#/components/schemas/ValidationError"},"type":"array","title":"Detail"}},"type":"object","title":"HTTPValidationError"},"PnDateRange":{"properties":{"oldest":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Oldest"},"latest":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Latest"}},"type":"object","required":["oldest","latest"],"title":"PnDateRange"},"PnLatestSettlementPeriod":{"properties":{"bmu_id":{"type":"string","title":"Bmu Id"},"settlement_period":{"anyOf":[{"type":"integer"},{"type":"null"}],"title":"Settlement Period"},"time_from":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Time From"}},"type":"object","required":["bmu_id","settlement_period","time_from"],"title":"PnLatestSettlementPeriod"},"PnResponse":{"properties":{"bmu_id":{"type":"string","title":"Bmu Id"},"time_from":{"type":"string","format":"date-time","title":"Time From"},"time_to":{"type":"string","format":"date-time","title":"Time To"},"settlement_period":{"type":"integer","title":"Settlement Period"},"level_mw":{"type":"number","title":"Level Mw"},"source":{"type":"string","title":"Source","default":"pn"}},"type":"object","required":["bmu_id","time_from","time_to","settlement_period","level_mw"],"title":"PnResponse","description":"RÃ©ponse API."},"PnTopProductionPoint":{"properties":{"max_mw":{"type":"number","title":"Max Mw","default":0.0},"max_date":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Max Date"}},"type":"object","title":"PnTopProductionPoint"},"PnTopProductionWindows":{"properties":{"all_time":{"$ref":"#/components/schemas/PnTopProductionPoint","description":"Top production for all available data."},"last_7_days":{"$ref":"#/components/schemas/PnTopProductionPoint","description":"Top production over the last 7 days."},"last_30_days":{"$ref":"#/components/schemas/PnTopProductionPoint","description":"Top production over the last 30 days."},"last_90_days":{"$ref":"#/components/schemas/PnTopProductionPoint","description":"Top production over the last 90 days."}},"type":"object","required":["all_time","last_7_days","last_30_days","last_90_days"],"title":"PnTopProductionWindows"},"RemitResponse":{"properties":{"id":{"type":"integer","title":"Id"},"mrid":{"type":"string","title":"Mrid"},"revision_number":{"type":"integer","title":"Revision Number"},"bmu_id":{"type":"string","title":"Bmu Id"},"participant_id":{"type":"string","title":"Participant Id"},"asset_id":{"type":"string","title":"Asset Id"},"unavailability_type":{"type":"string","title":"Unavailability Type"},"event_type":{"type":"string","title":"Event Type"},"message_heading":{"type":"string","title":"Message Heading"},"fuel_type":{"type":"string","title":"Fuel Type"},"normal_capacity_mw":{"anyOf":[{"type":"number"},{"type":"null"}],"title":"Normal Capacity Mw"},"available_capacity_mw":{"anyOf":[{"type":"number"},{"type":"null"}],"title":"Available Capacity Mw"},"unavailable_capacity_mw":{"anyOf":[{"type":"number"},{"type":"null"}],"title":"Unavailable Capacity Mw"},"event_status":{"type":"string","title":"Event Status"},"event_start_time":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Event Start Time"},"event_end_time":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Event End Time"},"cause":{"type":"string","title":"Cause"},"related_information":{"type":"string","title":"Related Information"},"publish_time":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Publish Time"},"outage_profile":{"type":"string","title":"Outage Profile"}},"type":"object","required":["id","mrid","revision_number","bmu_id","participant_id","asset_id","unavailability_type","event_type","message_heading","fuel_type","normal_capacity_mw","available_capacity_mw","unavailable_capacity_mw","event_status","event_start_time","event_end_time","cause","related_information","publish_time","outage_profile"],"title":"RemitResponse","description":"RÃ©ponse API â€” raw_json exclu pour allÃ©ger."},"ValidationError":{"properties":{"loc":{"items":{"anyOf":[{"type":"string"},{"type":"integer"}]},"type":"array","title":"Location"},"msg":{"type":"string","title":"Message"},"type":{"type":"string","title":"Error Type"},"input":{"title":"Input"},"ctx":{"type":"object","title":"Context"}},"type":"object","required":["loc","msg","type"],"title":"ValidationError"},"WeatherDateRange":{"properties":{"oldest":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Oldest"},"latest":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Latest"}},"type":"object","required":["oldest","latest"],"title":"WeatherDateRange"},"WeatherLatestTimestamp":{"properties":{"time_from":{"anyOf":[{"type":"string","format":"date-time"},{"type":"null"}],"title":"Time From"}},"type":"object","required":["time_from"],"title":"WeatherLatestTimestamp"},"WeatherResponse":{"properties":{"time_from":{"type":"string","format":"date-time","title":"Time From"},"time_to":{"type":"string","format":"date-time","title":"Time To"},"wind_speed":{"type":"number","title":"Wind Speed"},"source":{"type":"string","title":"Source","default":"weather"}},"type":"object","required":["time_from","time_to","wind_speed"],"title":"WeatherResponse"}}}}
