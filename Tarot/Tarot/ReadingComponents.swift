//
//  ReadingComponents.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//


import SwiftUI

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
    let isReversed: Bool
    let position: String
}

struct SpreadButton: View {
    let label: String
    let sublabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 4) {
                Text(label)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundStyle(.white)
                Text(sublabel)
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct CardRow: View {
    let drawn: DrawnCard
    var reading: String? = nil
    var isLoadingReading: Bool = false
    var onImageTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(drawn.position.uppercased())
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .kerning(2)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(drawn.card.name)
                            .font(.system(size: 17, weight: .light, design: .serif))
                            .foregroundStyle(.white)
                        if drawn.isReversed {
                            Text("reversed")
                                .font(.system(size: 11, weight: .light, design: .serif))
                                .foregroundStyle(.white.opacity(0.4))
                                .italic()
                        }
                    }
                }
                Spacer()
                if let arcana = drawn.card.arcana {
                    Text(arcana == "Major" ? "★" : "·")
                        .font(.system(size: arcana == "Major" ? 14 : 20))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }

            if let imageName = drawn.card.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .aspectRatio(2/3, contentMode: .fit)
                    .rotationEffect(drawn.isReversed ? .degrees(180) : .degrees(0))
                    .cornerRadius(6)
                    .opacity(0.9)
                    .contentShape(Rectangle())
                    .onTapGesture { onImageTap?() }
            }

            Text(drawn.isReversed ? drawn.card.reversedMeaning : drawn.card.uprightMeaning)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(.white.opacity(0.4))
                .lineSpacing(3)

            if let reading, !reading.isEmpty {
                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.top, 4)
                Text((try? AttributedString(markdown: reading, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(reading))
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(6)
            } else if isLoadingReading {
                Text("Reading the cards…")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .kerning(2)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

/// Card positions for the spreads with their own shape (Connection, Celtic Cross, Year Ahead).
/// Centers are in points inside a canvas of `size`. Shared by the reading screen and the share image.
struct SpreadGeometry {
    let size: CGSize
    let centers: [CGPoint]
    let rotations: [Double]

    static func supports(_ spreadType: String, count: Int) -> Bool {
        (spreadType == "connection" && count == 5)
            || (spreadType == "celtic_cross" && count == 10)
            || (spreadType == "year_ahead" && count == 13)
    }

    /// Card width that fits a 342pt content column.
    static func tileWidth(for spreadType: String) -> CGFloat {
        switch spreadType {
        case "connection": return 72
        case "celtic_cross": return 54
        default: return 44
        }
    }

    static func make(spreadType: String, count: Int, tileW w: CGFloat, tileH h: CGFloat, gap: CGFloat = 8) -> SpreadGeometry? {
        guard supports(spreadType, count: count) else { return nil }

        switch spreadType {
        case "connection":
            // 5 on top, 2 and 4 on the outside, 1 and 3 low in the middle.
            let step = w + gap
            let ystep = h + gap
            func x(_ col: CGFloat) -> CGFloat { w / 2 + col * step }
            let top = h / 2
            let mid = h / 2 + 0.9 * ystep
            let low = h / 2 + 1.25 * ystep
            let centers = [
                CGPoint(x: x(1), y: low),      // 1 You
                CGPoint(x: x(0), y: mid),      // 2 Your Challenge
                CGPoint(x: x(2), y: low),      // 3 The Other Person
                CGPoint(x: x(3), y: mid),      // 4 Their Challenge
                CGPoint(x: x(1.5), y: top)     // 5 The Uniting Force
            ]
            return SpreadGeometry(size: CGSize(width: x(3) + w / 2, height: low + h / 2),
                                  centers: centers, rotations: Array(repeating: 0, count: 5))

        case "celtic_cross":
            // The whole shape (cross plus column) is centered on screen. 5, 1, 3 share a center
            // line, 2 lies across 1, and the column of four is centered on the cross's height.
            let cs = w * 1.25 + gap
            let rs = h + gap
            let left = w / 2
            let cx = left + cs
            let right = left + 2 * cs
            let colX = right + w + gap + 18           // column of four, a little clear of the cross
            func y(_ row: CGFloat) -> CGFloat { h / 2 + row * rs }
            let centers = [
                CGPoint(x: cx, y: y(1.5)),     // 1 Heart of the Matter
                CGPoint(x: cx, y: y(1.5)),     // 2 Opposing Factors (crossing)
                CGPoint(x: cx, y: y(2.5)),     // 3 Root Cause
                CGPoint(x: left, y: y(1.5)),   // 4 Past
                CGPoint(x: cx, y: y(0.5)),     // 5 Goal
                CGPoint(x: right, y: y(1.5)),  // 6 Future
                CGPoint(x: colX, y: y(3)),     // 7 You
                CGPoint(x: colX, y: y(2)),     // 8 External Influences
                CGPoint(x: colX, y: y(1)),     // 9 Hopes and Fears
                CGPoint(x: colX, y: y(0))      // 10 Final Outcome
            ]
            var rot = Array(repeating: 0.0, count: 10)
            rot[1] = 90
            return SpreadGeometry(size: CGSize(width: colX + w / 2, height: y(3) + h / 2),
                                  centers: centers, rotations: rot)

        default:
            // Year Ahead: January at the top, the months clockwise, the theme in the middle.
            let rx = w * 3.38      // as wide as the screen allows
            let ry = h * 2.1
            let cx = rx + w / 2
            let cy = ry + h / 2
            // Walk around the ellipse in equal steps, measured in card sizes (so tall cards at
            // 3 and 9 o'clock get the same breathing room as the ones at the top).
            let samples = 720
            var pts: [CGPoint] = []
            var cum: [CGFloat] = [0]
            for k in 0...samples {
                let a = 2 * Double.pi * Double(k) / Double(samples)
                let p = CGPoint(x: cx + rx * CGFloat(sin(a)), y: cy - ry * CGFloat(cos(a)))
                if let prev = pts.last {
                    let dx = (p.x - prev.x) / w
                    let dy = (p.y - prev.y) / h
                    cum.append(cum[cum.count - 1] + (dx * dx + dy * dy).squareRoot())
                }
                pts.append(p)
            }
            let total = cum[cum.count - 1]
            var centers: [CGPoint] = []
            for i in 0..<12 {
                let target = total * CGFloat(i) / 12
                let idx = cum.firstIndex(where: { $0 >= target }) ?? 0
                centers.append(pts[idx])
            }
            centers.append(CGPoint(x: cx, y: cy))
            return SpreadGeometry(size: CGSize(width: 2 * rx + w, height: 2 * ry + h),
                                  centers: centers, rotations: Array(repeating: 0, count: 13))
        }
    }
}

struct CardFanView: View {
    let spread: [DrawnCard]
    let isHomePreview: Bool
    let spreadType: String
    var revealedCards: Set<Int> = []
    var focusedIndex: Int? = nil
    var interactive: Bool = false
    var onTap: (Int) -> Void = { _ in }

    private func revealed(_ index: Int) -> Bool {
        !interactive || revealedCards.contains(index)
    }

    private var nextIndex: Int? {
        (0..<spread.count).first { !revealedCards.contains($0) }
    }

    private func tile(_ i: Int, width: CGFloat, cornerRadius: CGFloat = 6) -> some View {
        let isRevealed = revealed(i)
        let locked = interactive && !isRevealed && i != nextIndex
        let dimmed = interactive && isRevealed && focusedIndex != nil && focusedIndex != i

        return FlipCard(imageName: spread[i].card.imageName, isReversed: spread[i].isReversed,
                        width: width, revealed: isRevealed, cornerRadius: cornerRadius)
            .saturation(locked ? 0.35 : 1)
            .opacity(locked ? 0.45 : (dimmed ? 0.6 : 1))
            .animation(.easeInOut(duration: 0.25), value: focusedIndex)
            .animation(.easeInOut(duration: 0.25), value: revealedCards)
            .contentShape(Rectangle())
            .onTapGesture { if interactive { onTap(i) } }
            .fadeSlideIn(delay: Double(i) * 0.25)
    }

    /// In the Celtic Cross, card 2 lies across card 1. Keep 1 on top until it has been turned.
    private func stackOrder(_ i: Int) -> Double {
        guard spreadType == "celtic_cross" else { return 0 }
        if i == 1 { return revealed(0) ? 2 : 0 }
        return i == 0 ? 1 : 0
    }

    var body: some View {
        let count = spread.count
        let tw = SpreadGeometry.tileWidth(for: spreadType)
        if !isHomePreview,
           let geo = SpreadGeometry.make(spreadType: spreadType, count: count, tileW: tw, tileH: tw * 1.5) {
            ZStack(alignment: .topLeading) {
                ForEach(0..<count, id: \.self) { i in
                    tile(i, width: tw, cornerRadius: 5)
                        .rotationEffect(.degrees(geo.rotations[i]))
                        .position(geo.centers[i])
                        .zIndex(stackOrder(i))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } else if count == 1 {
            tile(0, width: 120)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else if count <= 4 {
            if spreadType == "clarity" {
                VStack(spacing: 12) {
                    tile(0, width: 78)
                    HStack(spacing: 12) {
                        ForEach(1..<count, id: \.self) { i in
                            tile(i, width: 78)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 12) {
                    ForEach(0..<count, id: \.self) { i in
                        tile(i, width: count == 3 ? 90 : 78)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        } else {
            if isHomePreview {
                let arcAngles: [Double] = [-20, -10, 0, 10, 20]
                let arcOffsets: [CGFloat] = [-85, -42, 0, 42, 85]
                let arcVertical: [CGFloat] = [20, 8, 0, 8, 20]

                ZStack {
                    ForEach(Array(spread.enumerated()), id: \.offset) { index, drawn in
                        FlipCard(imageName: drawn.card.imageName, isReversed: drawn.isReversed,
                                 width: 72, revealed: true)
                            .rotationEffect(.degrees(arcAngles[index]))
                            .offset(x: arcOffsets[index], y: arcVertical[index])
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                let drops: [CGFloat] = [0, 19, 38, 19, 0]

                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<5, id: \.self) { i in
                        tile(i, width: 58, cornerRadius: 5)
                            .padding(.top, drops[i])
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
}
