//
//  TyperwriterText.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/17/26.

//  Shows text one word at a time with a soft tap now and then, so a reading feels like
//  it is being spoken to you. The full text is laid out from the start (unshown words are
//  just clear), so nothing jumps around while it types. Tap the text to show it all.

import SwiftUI
import UIKit

struct TypewriterText: View {
    let text: AttributedString
    /// False shows everything at once (restored readings, Reduce Motion).
    var animate: Bool = true
    /// True once the full text has arrived. While a reading is still streaming in, the last
    /// word is held back because it may be half written.
    var streamDone: Bool = true
    /// Called at the start and every few words, so the screen can follow along.
    var onProgress: (() -> Void)? = nil
    /// Called once, when the last word has been shown.
    var onFinished: (() -> Void)? = nil
    /// Wait this long before the first word (lets a scroll settle first).
    var startDelay: Double = 0
    /// Whether to call onProgress before the first word as well as every few words.
    var scrollAtStart: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0
    @State private var finished = false

    private let wordDelay: UInt64 = 70_000_000      // about 14 words a second
    private let tapEvery = 2                        // a haptic tick every other word
    private let progressEvery = 10

    /// The end of every word in the text.
    private var wordEnds: [AttributedString.Index] {
        var ends: [AttributedString.Index] = []
        var inWord = false
        var i = text.characters.startIndex
        while i < text.characters.endIndex {
            let isSpace = text.characters[i].isWhitespace
            let next = text.characters.index(after: i)
            if isSpace, inWord { ends.append(i); inWord = false }
            else if !isSpace { inWord = true }
            i = next
        }
        if inWord { ends.append(text.characters.endIndex) }
        return ends
    }

    /// True when the given word (1 based) ends with . ! or ?
    private func endsSentence(word: Int) -> Bool {
        let ends = wordEnds
        guard ends.indices.contains(word - 1) else { return false }
        let end = ends[word - 1]
        guard end > text.startIndex else { return false }
        let last = text.characters[text.characters.index(before: end)]
        return last == "." || last == "!" || last == "?"
    }

    private var revealable: Int {
        let n = wordEnds.count
        return streamDone ? n : max(0, n - 1)
    }

    private var visible: AttributedString {
        guard animate, !reduceMotion, !finished else { return text }
        let ends = wordEnds
        guard shown < ends.count else { return text }
        var t = text
        let start = shown == 0 ? t.startIndex : ends[shown - 1]
        t[start..<t.endIndex].foregroundColor = Color.clear
        return t
    }

    var body: some View {
        Text(visible)
            .contentShape(Rectangle())
            .onTapGesture { finish() }
            .task(id: TaskKey(animate: animate, words: revealable, done: streamDone)) {
                await run()
            }
    }

    private struct TaskKey: Equatable { let animate: Bool; let words: Int; let done: Bool }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinished?()
    }

    @MainActor
    private func run() async {
        guard animate, !reduceMotion else { finish(); return }
        guard !finished else { return }
        let gen = UIImpactFeedbackGenerator(style: .soft)
        gen.prepare()
        if shown == 0 {
            if scrollAtStart { onProgress?() }
            if startDelay > 0 { try? await Task.sleep(nanoseconds: UInt64(startDelay * 1_000_000_000)) }
            if Task.isCancelled { return }
        }
        let total = revealable
        while shown < total, !Task.isCancelled, !finished {
            try? await Task.sleep(nanoseconds: wordDelay)
            if Task.isCancelled { return }
            shown += 1
            SpeechSound.shared.blip(endsSentence: endsSentence(word: shown))
            if shown % tapEvery == 0 { gen.impactOccurred(intensity: 0.45) }
            if shown % progressEvery == 0 { onProgress?() }
        }
        // Caught up with everything that exists. Done only when the stream has ended.
        if shown >= wordEnds.count, streamDone { finish() }
    }
}
