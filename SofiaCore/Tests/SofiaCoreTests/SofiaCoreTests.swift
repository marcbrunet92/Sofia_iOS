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
        let points = aggregateProduction(entries)
        XCTAssertEqual(points.count, 2)
        XCTAssertEqual(points[0].quantity, 268)
        XCTAssertEqual(points[1].quantity, 168)
        XCTAssertEqual(points[0].id, "SOFIA_TOTAL")
        XCTAssertLessThan(points[0].timeFrom, points[1].timeFrom)
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
        let units = computeUnitStatuses([notice, expired], now: now)
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

    func testUnitNumber() {
        XCTAssertEqual(unitNumber("T_SOFOW-11"), "11")
        XCTAssertEqual(unitNumber("T_HEYM11"), "HEYM11")
    }

    func testGroupOutageProfileSumsUnitsStepByStep() {
        let now = Date(timeIntervalSince1970: 1_791_592_200)
        let first = remit(
            bmuId: "T_SOFOW-11", normal: 350, available: 0, unavailable: 350, start: now, end: nil,
            outageProfile: """
            [{"startTime":"2026-10-10T00:00:00Z","endTime":"2026-10-10T02:00:00Z","capacity":100}]
            """
        )
        let second = remit(
            bmuId: "T_SOFOW-12", normal: 350, available: 0, unavailable: 350, start: now, end: nil,
            outageProfile: """
            [{"startTime":"2026-10-10T00:00:00Z","endTime":"2026-10-10T01:00:00Z","capacity":50},
             {"startTime":"2026-10-10T01:00:00Z","endTime":"2026-10-10T02:00:00Z","capacity":200}]
            """
        )
        let withoutProfile = remit(bmuId: "T_SOFOW-21", normal: 350, available: 0, unavailable: 350, start: now, end: nil)
        let group = RemitGroup(id: "group", phase: .current, notices: [first, second], isFarmWide: true)
        XCTAssertEqual(group.title, "Ambient Conditions")
        let profile = group.outageProfile()
        XCTAssertEqual(profile.map(\.capacityMw), [150, 300])
        XCTAssertEqual(profile.first?.start, ApiTime.parseInstant("2026-10-10T00:00:00Z"))
        XCTAssertEqual(profile.last?.end, ApiTime.parseInstant("2026-10-10T02:00:00Z"))

        // Une unité sans profil : pas de profil de groupe
        let partial = RemitGroup(id: "partial", phase: .current, notices: [first, withoutProfile], isFarmWide: true)
        XCTAssertTrue(partial.outageProfile().isEmpty)
    }

    // MARK: - Statistiques

    func testPeriodStatsOverTheLastDay() throws {
        let now = Date(timeIntervalSince1970: 1_791_592_200)
        let points = [
            // Hors période (plus de 24 h)
            halfHour(now.addingTimeInterval(-30 * 3_600), 1_400),
            halfHour(now.addingTimeInterval(-2 * 3_600), 700),
            halfHour(now.addingTimeInterval(-1.5 * 3_600), 0),
            halfHour(now.addingTimeInterval(-1 * 3_600), 350),
            halfHour(now.addingTimeInterval(-0.5 * 3_600), 350),
            // À venir : ignoré
            halfHour(now, 1_000),
        ]
        let stats = try XCTUnwrap(periodStats(points, period: .day, capacityMw: 1_400, now: now))
        XCTAssertEqual(stats.hours, 2, accuracy: 1e-9)
        XCTAssertEqual(stats.energyMwh, 700, accuracy: 1e-9)
        XCTAssertEqual(stats.averageMw, 350, accuracy: 1e-9)
        XCTAssertEqual(stats.capacityFactor, 0.25, accuracy: 1e-9)
        XCTAssertEqual(stats.peakMw, 700)
        XCTAssertEqual(stats.peakDate, points[1].timeFrom)
        XCTAssertEqual(stats.generatingShare, 0.75, accuracy: 1e-9)
        XCTAssertEqual(stats.from, points[1].timeFrom)
        XCTAssertEqual(stats.to, now)
        XCTAssertEqual(stats.equivalentHomes, 350 * 8_760 / 2.7, accuracy: 1e-6)

        let all = try XCTUnwrap(periodStats(points, period: .all, capacityMw: 1_400, now: now))
        XCTAssertEqual(all.peakMw, 1_400)
        XCTAssertEqual(all.hours, 2.5, accuracy: 1e-9)
        XCTAssertNil(periodStats([], period: .all, capacityMw: 1_400, now: now))
        XCTAssertNil(periodStats([halfHour(now, 10)], period: .day, capacityMw: 1_400, now: now))
    }

    func testDailyEnergyPrefersMeteredDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        // 2026-10-10T12:00:00Z
        let now = try XCTUnwrap(ApiTime.parseInstant("2026-10-10T12:00:00Z"))
        let today = calendar.startOfDay(for: now)
        let yesterday = today.addingTimeInterval(-86_400)

        var pn: [GraphPoint] = []
        var b1610: [GraphPoint] = []
        for index in 0..<48 {
            let start = yesterday.addingTimeInterval(Double(index) * 1_800)
            pn.append(halfHour(start, 100))
            // Compteur : 40 MWh par demi-heure (soit 80 MW)
            b1610.append(halfHour(start, 40))
        }
        // Aujourd'hui : 12 h de PN à 200 MW, compteur partiel (1 h seulement)
        for index in 0..<24 {
            pn.append(halfHour(today.addingTimeInterval(Double(index) * 1_800), 200))
        }
        b1610.append(halfHour(today, 90))
        b1610.append(halfHour(today.addingTimeInterval(1_800), 90))

        let days = dailyEnergy(pnMw: pn, b1610Mwh: b1610, days: 3, now: now, calendar: calendar)
        XCTAssertEqual(days.map(\.day), [yesterday.addingTimeInterval(-86_400), yesterday, today])
        // Jour sans donnée
        XCTAssertEqual(days[0].energyMwh, 0)
        XCTAssertFalse(days[0].metered)
        // Jour couvert par le compteur : 48 × 40 MWh
        XCTAssertEqual(days[1].energyMwh, 1_920, accuracy: 1e-9)
        XCTAssertTrue(days[1].metered)
        // Jour en cours : estimation PN, 12 h × 200 MW
        XCTAssertEqual(days[2].energyMwh, 2_400, accuracy: 1e-9)
        XCTAssertFalse(days[2].metered)
        XCTAssertTrue(dailyEnergy(pnMw: pn, b1610Mwh: b1610, days: 0, now: now, calendar: calendar).isEmpty)
    }

    func testPowerCurveAveragesOutputPerWindClass() throws {
        let now = try XCTUnwrap(ApiTime.parseInstant("2026-10-10T12:00:00Z"))
        let hour0 = now.addingTimeInterval(-3 * 3_600)
        let hour1 = now.addingTimeInterval(-2 * 3_600)
        let hour2 = now.addingTimeInterval(-1 * 3_600)
        // 18 km/h = 5 m/s (classe 4–6), 36 km/h = 10 m/s (classe 10–12)
        let wind = [
            GraphPoint(id: "WEATHER", timeFrom: hour0, timeTo: hour1, quantity: 18),
            GraphPoint(id: "WEATHER", timeFrom: hour1, timeTo: hour2, quantity: 18),
            GraphPoint(id: "WEATHER", timeFrom: hour2, timeTo: now, quantity: 36),
        ]
        let pn = [
            halfHour(hour0, 100), halfHour(hour0.addingTimeInterval(1_800), 200),
            halfHour(hour1, 300), halfHour(hour1.addingTimeInterval(1_800), 400),
            halfHour(hour2, 900), halfHour(hour2.addingTimeInterval(1_800), 1_100),
            // À venir et sans météo : ignorés
            halfHour(now, 5_000),
        ]
        let curve = powerCurve(pnMw: pn, windKmh: wind, from: nil, now: now, binWidthMs: 2, minSamples: 2)
        XCTAssertEqual(curve.map(\.lowerMs), [4, 10])
        XCTAssertEqual(curve.map(\.upperMs), [6, 12])
        XCTAssertEqual(curve[0].averageMw, 250, accuracy: 1e-9)
        XCTAssertEqual(curve[0].samples, 4)
        XCTAssertEqual(curve[0].centerMs, 5)
        XCTAssertEqual(curve[1].averageMw, 1_000, accuracy: 1e-9)

        // Classes trop peu fournies écartées ; début de période respecté
        XCTAssertEqual(powerCurve(pnMw: pn, windKmh: wind, from: nil, now: now, minSamples: 3).map(\.lowerMs), [4])
        XCTAssertEqual(powerCurve(pnMw: pn, windKmh: wind, from: hour2, now: now, minSamples: 2).map(\.lowerMs), [10])
    }

    func testWindSpeedUnitConvertsFromKmh() {
        XCTAssertEqual(WindSpeedUnit.metersPerSecond.fromKmh(36), 10, accuracy: 1e-9)
        XCTAssertEqual(WindSpeedUnit.kilometersPerHour.fromKmh(36), 36)
        XCTAssertEqual(WindSpeedUnit.knots.fromKmh(18.52), 10, accuracy: 1e-9)
        XCTAssertEqual(WindSpeedUnit(rawValue: "kn"), .knots)
    }

    func testLatestUnitOutputsKeepTheLastEntryOfEachUnit() {
        let entries = [
            [
                pn("T_SOFOW-11", "2026-10-10T00:30:00", "2026-10-10T01:00:00", 4, 168),
                pn("T_SOFOW-11", "2026-10-10T00:00:00", "2026-10-10T00:30:00", 3, 100),
            ],
            [],
        ]
        let outputs = latestUnitOutputs(bmus: ["T_SOFOW-11", "T_SOFOW-12"], entries: entries)
        XCTAssertEqual(outputs.map(\.bmuId), ["T_SOFOW-11", "T_SOFOW-12"])
        XCTAssertEqual(outputs[0].outputMw, 168)
        XCTAssertEqual(outputs[0].capacityMw, 336)
        XCTAssertEqual(outputs[0].fraction, 0.5, accuracy: 1e-9)
        XCTAssertEqual(outputs[0].shortLabel, "11")
        XCTAssertEqual(outputs[0].timeFrom, ApiTime.parseUtc("2026-10-10T00:30:00"))
        XCTAssertNil(outputs[1].outputMw)
        XCTAssertEqual(outputs[1].fraction, 0)
        XCTAssertEqual(
            SofiaConstants.unitCapacitiesMw.values.reduce(0, +),
            SofiaConstants.maxCapacityMw
        )
        XCTAssertEqual(Set(SofiaConstants.unitCapacitiesMw.keys), Set(SofiaConstants.bmus))
    }

    func testAlertRemindersAtStartAndEnd() {
        let now = Date(timeIntervalSince1970: 1_791_592_200)
        let ongoing = remit(
            bmuId: "T_SOFOW-11", normal: 336, available: 0, unavailable: 336,
            start: now.addingTimeInterval(-3_600), end: now.addingTimeInterval(7_200)
        )
        let openEnded = remit(
            bmuId: "T_SOFOW-12", normal: 350, available: 0, unavailable: 350,
            start: now.addingTimeInterval(-3_600), end: nil
        )
        let upcoming = remit(
            bmuId: "T_SOFOW-21", normal: 406, available: 0, unavailable: 406,
            start: now.addingTimeInterval(3_600), end: now.addingTimeInterval(10_800)
        )
        let endingNow = remit(
            bmuId: "T_SOFOW-22", normal: 308, available: 0, unavailable: 308,
            start: now.addingTimeInterval(-3_600), end: now.addingTimeInterval(30)
        )
        let sections = groupRemits([ongoing, openEnded, upcoming, endingNow], units: SofiaConstants.bmus, now: now)
        XCTAssertEqual(sections.current.count, 3)
        XCTAssertEqual(sections.upcoming.count, 1)

        let reminders = planAlertReminders(sections, now: now)
        XCTAssertEqual(reminders.map(\.kind), [.start, .end, .end])
        XCTAssertEqual(reminders.map(\.fireDate), [
            now.addingTimeInterval(3_600), now.addingTimeInterval(7_200), now.addingTimeInterval(10_800),
        ])
        XCTAssertEqual(reminders[0].group.first.bmuId, "T_SOFOW-21")
        XCTAssertEqual(reminders[1].group.first.bmuId, "T_SOFOW-11")
        XCTAssertEqual(Set(reminders.map(\.id)).count, 3)
        XCTAssertEqual(planAlertReminders(sections, now: now, limit: 1).count, 1)
        XCTAssertTrue(planAlertReminders(RemitSections(), now: now).isEmpty)
    }

    // MARK: - Helpers

    private func halfHour(_ start: Date, _ quantity: Double) -> GraphPoint {
        GraphPoint(id: "SOFIA_TOTAL", timeFrom: start, timeTo: start.addingTimeInterval(1_800), quantity: quantity)
    }

    private func pn(_ bmu: String, _ from: String, _ to: String, _ period: Int, _ mw: Double) -> PnEntryDto {
        PnEntryDto(bmuId: bmu, timeFrom: from, timeTo: to, settlementPeriod: period, levelMw: mw, source: "pn")
    }

    private func remit(
        bmuId: String,
        normal: Double?,
        available: Double?,
        unavailable: Double?,
        start: Date?,
        end: Date?,
        outageProfile: String = ""
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
            outageProfile: outageProfile
        )
    }
}
