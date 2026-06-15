//
//  DefinitionCard.swift
//  Sofia
//
//  Created by Marc Brunet on 15/06/2026.
//


import SwiftUI

struct DefinitionCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 4)
    }
}
