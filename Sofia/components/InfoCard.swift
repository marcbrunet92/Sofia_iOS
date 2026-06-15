//
//  InfoCard.swift
//  Sofia
//
//  Created by Marc Brunet on 15/06/2026.
//


import SwiftUI

struct InfoCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
