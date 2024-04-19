//
//  ErrorView.swift
//  SummaryAI
//
//  Created by 超方 on 2024/3/29.
//

import SwiftUI

struct ErrorView: View {
    let errorWrapper: ErrorWrapper
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("An error has occured")
                    .font(.title)
                    .padding(.bottom)
                Text(errorWrapper.error.localizedDescription)
                    .font(.headline)
                Text(errorWrapper.guidance)
                    .font(.caption)
                    .padding(.top)
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum SampleError: Error {
    case errorRequired
}

var wrapper: ErrorWrapper {
    ErrorWrapper(error: SampleError.errorRequired,
    guidance: "Ignore it safely")
}

#Preview {
    ErrorView(errorWrapper: wrapper)
}
