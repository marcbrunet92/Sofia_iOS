//
//  CapacityText.swift
//  Sofia
//
//  Created by Marc Brunet on 15/06/2026.
//


import SwiftUI

struct CapacityText: View {
    let label: String
    let valueMw: Double?

    var formattedValue: String {
        guard let valueMw else { return "—" }
        return String(Int(valueMw.rounded()))
    }

    var body: some View {
        Text("\(label): \(formattedValue) MW")
            .font(.caption)
    }
}