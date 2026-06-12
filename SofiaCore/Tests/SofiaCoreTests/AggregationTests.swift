import XCTest
@testable import SofiaCore

final class AggregationTests: XCTestCase {

    private func date(_ iso: String) -> Date {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.date(from: iso)!
    }

    func testAggregatedProductionPointsSumsAcrossBMUs() {
        let entries = [
            PnResponse(bmuId: "T_SOFOW-11", timeFrom: date("2024-01-01T00:00:00Z"), timeTo: date("2024-01-01T00:30:00Z"), settlementPeriod: 1, levelMw: 10.0, source: nil),
            PnResponse(bmuId: "T_SOFOW-12", timeFrom: date("2024-01-01T00:00:00Z"), timeTo: date("2024-01-01T00:30:00Z"), settlementPeriod: 1, levelMw: 15.0, source: nil),
            PnResponse(bmuId: "T_SOFOW-11", timeFrom: date("2024-01-01T00:30:00Z"), timeTo: date("2024-01-01T01:00:00Z"), settlementPeriod: 2, levelMw: 20.0, source: nil),
        ]

        let points = entries.aggregatedProductionPoints(seriesId: "SOFIA_TOTAL")

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].quantity, 25.0, accuracy: 0.0001)
        XCTAssertEqual(points[0].seriesId, "SOFIA_TOTAL")
        XCTAssertEqual(points[1].quantity, 20.0, accuracy: 0.0001)
        XCTAssertEqual(points[0].timeFrom, date("2024-01-01T00:00:00Z"))
        XCTAssertEqual(points[1].timeFrom, date("2024-01-01T00:30:00Z"))
    }

    func testAggregatedProductionPointsEmpty() {
        let entries: [PnResponse] = []
        XCTAssertEqual(entries.aggregatedProductionPoints(seriesId: "SOFIA_TOTAL"), [])
    }

    func testAggregatedB1610PointsSumsAcrossBMUs() {
        let entries = [
            B1610Response(bmuId: "T_SOFOW-11", timeFrom: date("2024-01-01T00:00:00Z"), timeTo: date("2024-01-01T00:30:00Z"), quantity: 5.0, settlementPeriod: 1),
            B1610Response(bmuId: "T_SOFOW-21", timeFrom: date("2024-01-01T00:00:00Z"), timeTo: date("2024-01-01T00:30:00Z"), quantity: 7.0, settlementPeriod: 1),
        ]

        let points = entries.aggregatedB1610Points(seriesId: "SOFIA_TOTAL")

        XCTAssertEqual(points.count, 1)
        XCTAssertEqual(points[0].quantity, 12.0, accuracy: 0.0001)
    }

    func testWeatherToGraphPointsSortedAndTagged() {
        let entries = [
            WeatherResponse(timeFrom: date("2024-01-01T01:00:00Z"), timeTo: date("2024-01-01T01:30:00Z"), windSpeed: 8.0, source: "test"),
            WeatherResponse(timeFrom: date("2024-01-01T00:00:00Z"), timeTo: date("2024-01-01T00:30:00Z"), windSpeed: 5.0, source: "test"),
        ]

        let points = entries.toGraphPoints()

        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points.first?.seriesId, "WEATHER")
        XCTAssertEqual(points.first?.quantity ?? -1, 5.0, accuracy: 0.0001)
        XCTAssertEqual(points.last?.quantity ?? -1, 8.0, accuracy: 0.0001)
    }

    func testCalculateTopWindows() {
        let now = date("2024-04-01T00:00:00Z")
        let day: TimeInterval = 24 * 60 * 60

        let points = [
            GraphPoint(seriesId: "S", timeFrom: now.addingTimeInterval(-100 * day), timeTo: now.addingTimeInterval(-100 * day + 1800), quantity: 50.0),
            GraphPoint(seriesId: "S", timeFrom: now.addingTimeInterval(-10 * day), timeTo: now.addingTimeInterval(-10 * day + 1800), quantity: 30.0),
            GraphPoint(seriesId: "S", timeFrom: now.addingTimeInterval(-1 * day), timeTo: now.addingTimeInterval(-1 * day + 1800), quantity: 20.0),
        ]

        let top = calculateTopWindows(from: points, now: now)

        // All time max is the 50.0 point, 100 days ago.
        XCTAssertEqual(top.allTime.maxQuantity, 50.0, accuracy: 0.0001)
        XCTAssertEqual(top.allTime.maxDate, now.addingTimeInterval(-100 * day))

        // Last 90 days excludes the 100-day-old point; max becomes 30.0.
        XCTAssertEqual(top.last90Days.maxQuantity, 30.0, accuracy: 0.0001)

        // Last 30 days: same, max 30.0.
        XCTAssertEqual(top.last30Days.maxQuantity, 30.0, accuracy: 0.0001)

        // Last 7 days: only the -1 day point, max 20.0.
        XCTAssertEqual(top.last7Days.maxQuantity, 20.0, accuracy: 0.0001)
    }

    func testCalculateTopWindowsEmpty() {
        let top = calculateTopWindows(from: [])
        XCTAssertEqual(top, .empty)
    }

    func testFilterPointsAllReturnsAll() {
        let now = Date()
        let points = [
            GraphPoint(seriesId: "S", timeFrom: now, timeTo: now.addingTimeInterval(1800), quantity: 1.0),
            GraphPoint(seriesId: "S", timeFrom: now.addingTimeInterval(1800), timeTo: now.addingTimeInterval(3600), quantity: 2.0),
        ]
        XCTAssertEqual(filterPoints(points, window: .all), points)
    }

    func testFilterPointsLast7Days() {
        let now = Date()
        let day: TimeInterval = 24 * 60 * 60
        let points = [
            GraphPoint(seriesId: "S", timeFrom: now.addingTimeInterval(-10 * day), timeTo: now.addingTimeInterval(-10 * day + 1800), quantity: 1.0),
            GraphPoint(seriesId: "S", timeFrom: now.addingTimeInterval(-1 * day), timeTo: now.addingTimeInterval(-1 * day + 1800), quantity: 2.0),
            GraphPoint(seriesId: "S", timeFrom: now, timeTo: now.addingTimeInterval(1800), quantity: 3.0),
        ]

        let filtered = filterPoints(points, window: .last7Days)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered.map { $0.quantity }, [2.0, 3.0])
    }

    func testFilterPointsEmptyInput() {
        XCTAssertEqual(filterPoints([], window: .last7Days), [])
    }
}