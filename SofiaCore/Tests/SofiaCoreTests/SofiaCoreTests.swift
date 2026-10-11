import XCTest
@testable import SofiaCore

final class SofiaCoreTests: XCTestCase {
    func testParseApiUtcWithoutTimeZone() throws {
        let date = try XCTUnwrap(ApiTime.parseUtc("2026-10-10T00:30:00"))
        XCTAssertEqual(date.timeIntervalSince1970, 1_791_592_200)
    }

    func testParseApiInstantVariants() {
        XCTAssertNil(ApiTime.parseInstant(nil))
        XCTAssertNil(ApiTime.parseInstant("   "))
        XCTAssertEqual(
            ApiTime.parseInstant("2026-04-01T00:00:00Z"),
            SofiaConstants.historyStart
        )
        XCTAssertEqual(
            ApiTime.parseInstant("2026-04-01T02:00:00+02:00"),
            SofiaConstants.historyStart
        )
        XCTAssertEqual(
            ApiTime.parseInstant("2026-04-01T00:00:00.500Z")?.timeIntervalSince1970,
            SofiaConstants.historyStart.timeIntervalSince1970 + 0.5
        )
        XCTAssertNil(ApiTime.parseInstant("not a date"))
    }

    func testFormatMatchesInstantToString() {
        XCTAssertEqual(ApiTime.format(SofiaConstants.historyStart), "2026-04-01T00:00:00Z")
    }

    func testAggregateProductionSumsBmusPerSettlementPeriod() {
        let entries = [
            pn("T_SOFOW-11", "2026-10-10T00:30:00", "2026-10-10T01:00:00", 4, 168),
            pn("T_SOFOW-12", "2026-10-10T00:00:00", "2026-10-10T00:30:00", 3, 100),
            pn("T_SOFOW-11", "2026-10-10T00:00:00", "2026-10-10T00:30:00", 3, 168),
        ]
        let points = aggregateProduction(entries, testMode: false)
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].quantity, 268)
        XCTAssertEqual(points[1].quantity, 168)
        XCTAssertEqual(points[0].id, "SOFIA_TOTAL")
        XCTAssertLessThan(points[0].timeFrom, points[1].timeFrom)
        XCTAssertEqual(aggregateProduction(entries, testMode: true).first?.id, SofiaConstants.testBmu)
    }

    func testUnitStatusesUseActiveNotices() {
        let now = Date(timeIntervalSince1970: 1_791_592_200)
        let notice = remit(
            bmuId: "T_SOFOW-11",
            normal: 336,
            available: nil,
            unavailable: 148,
            start: now.addingTimeInterval(-3_600),
            end: now.addingTimeInterval(3_600)
        )
        let expired = remit(
            bmuId: "T_SOFOW-12",
            normal: 336,
            available: 0,
            unavailable: 336,
            start: now.addingTimeInterval(-7_200),
            end: now.addingTimeInterval(-3_600)
        )
        let units = computeUnitStatuses([notice, expired], testMode: false, now: now)
        XCTAssertEqual(units.map(\.bmuId), SofiaConstants.bmus)
        XCTAssertEqual(units[0].availableMw, 188)
        XCTAssertEqual(units[0].normalMw, 336)
        XCTAssertTrue(units[0].hasNotice)
        XCTAssertEqual(units[0].level, .warn)
        XCTAssertEqual(units[1].availableMw, 350)
        XCTAssertFalse(units[1].hasNotice)
        XCTAssertEqual(units[1].level, .good)
        XCTAssertEqual(units[0].label, "SOFOW-11")
        XCTAssertEqual(units[0].shortLabel, "11")
    }

    func testTopWindowsKeepsFirstMaximum() {
        let now = Date(timeIntervalSince1970: 1_791_592_200)
        let points = [
            GraphPoint(id: "A", timeFrom: now.addingTimeInterval(-100 * 86_400), timeTo: now, quantity: 500),
            GraphPoint(id: "A", timeFrom: now.addingTimeInterval(-2 * 86_400), timeTo: now, quantity: 300),
            GraphPoint(id: "A", timeFrom: now.addingTimeInterval(-86_400), timeTo: now, quantity: 300),
        ]
        let top = calculateTopWindows(points, now: now)
        XCTAssertEqual(top.allTime.maxQuantity, 500)
        XCTAssertEqual(top.last7Days.maxQuantity, 300)
        XCTAssertEqual(top.last7Days.maxDate, points[1].timeFrom)
        XCTAssertEqual(calculateTopWindows([], now: now), .empty)
    }

    // MARK: - Helpers

    private func pn(_ bmu: String, _ from: String, _ to: String, _ period: Int, _ mw: Double) -> PnEntryDto {
        PnEntryDto(bmuId: bmu, timeFrom: from, timeTo: to, settlementPeriod: period, levelMw: mw, source: "pn")
    }

    private func remit(
        bmuId: String,
        normal: Double?,
        available: Double?,
        unavailable: Double?,
        start: Date?,
        end: Date?
    ) -> RemitNotice {
        RemitNotice(
            id: Int.random(in: 1...1_000_000),
            mrid: "MRID",
            revisionNumber: 1,
            bmuId: bmuId,
            participantId: "SOFIA",
            assetId: bmuId,
            unavailabilityType: "Unplanned",
            eventType: "Production unavailability",
            messageHeading: "",
            fuelType: "Wind Offshore",
            normalCapacityMw: normal,
            availableCapacityMw: available,
            unavailableCapacityMw: unavailable,
            eventStatus: "Active",
            eventStartTime: start,
            eventEndTime: end,
            cause: "Ambient Conditions",
            relatedInformation: "",
            publishTime: start,
            outageProfile: ""
        )
    }
}
