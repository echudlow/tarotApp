//
//  FlipCard.swift
//  The Read
//
//  Created by Elijah Hudlow on 10/31/26.
//

import SwiftUI

struct FlipCard: View {
    let imageName: String?
    let isReversed: Bool
    let width: CGFloat
    let revealed: Bool
    var cornerRadius: CGFloat = 6

    var body: some View {
        ZStack {
            Image("CardBacks")
                .resizable()
                .aspectRatio(2/3, contentMode: .fit)
                .frame(width: width)
                .cornerRadius(cornerRadius)
                .rotation3DEffect(.degrees(revealed ? 90 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(revealed ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: revealed)

            if let imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(width: width)
                    .cornerRadius(cornerRadius)
                    .rotationEffect(.degrees(isReversed ? 180 : 0))
                    .rotation3DEffect(.degrees(revealed ? 0 : -90), axis: (x: 0, y: 1, z: 0))
                    .opacity(revealed ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3).delay(0.3), value: revealed)
            }
        }
    }
}
