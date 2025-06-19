//
//  WordDetailSheet.swift
//  Tutor
//
//  Created by Nolan Price on 6/19/25.
//

import Foundation
import SwiftUI

struct WordDetailSheet: View {
    let word: TokenizedWord

    var body: some View {
        VStack(spacing: 20) {
            Text(word.word)
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                Text("Reading: \(word.reading)")
                Text("Definition: \(word.definition)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}

