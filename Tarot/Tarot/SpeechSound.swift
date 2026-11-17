//
//  SpeechSound.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/17/26.
//
//  Soft "talking" blips played as a reading types out, in the spirit of Animal Crossing.
//  The tones are made in code, so there are no audio files. They use the ambient audio
//  session, which follows the silent switch and mixes with whatever else is playing.

import AVFoundation
import Foundation

final class SpeechSound {
    static let shared = SpeechSound()
    /// The Settings toggle. On unless the person turns it off.
    static let defaultsKey = "speechSounds"

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    private var notes: [AVAudioPCMBuffer] = []
    private var lowNote: AVAudioPCMBuffer?
    private var lastNote = -1
    private var ready = false

    /// A gentle pentatonic spread, so the babble never sounds sour.
    private let frequencies: [Double] = [293.7, 329.6, 392.0, 440.0, 523.3, 587.3, 659.3]

    private init() {
        UserDefaults.standard.register(defaults: [Self.defaultsKey: true])
    }

    var isEnabled: Bool { UserDefaults.standard.bool(forKey: Self.defaultsKey) }

    /// One short blip for a word. A word that ends a sentence falls to a lower note.
    func blip(endsSentence: Bool = false) {
        guard isEnabled, prepare() else { return }
        let buffer: AVAudioPCMBuffer
        if endsSentence, let low = lowNote {
            buffer = low
        } else {
            var i = Int.random(in: 0..<notes.count)
            if i == lastNote { i = (i + 3) % notes.count }
            lastNote = i
            buffer = notes[i]
        }
        if !engine.isRunning { try? engine.start() }
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    // MARK: - Setup

    @discardableResult
    private func prepare() -> Bool {
        if ready { return true }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            return false
        }
        notes = frequencies.map { render(frequency: $0, duration: 0.055) }
        lowNote = render(frequency: 246.9, duration: 0.09)

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.volume = 0.5
        do { try engine.start() } catch { return false }
        ready = true
        return true
    }

    /// A soft sine with a touch of overtone, a quick fade in and a smooth fade out.
    private func render(frequency: Double, duration: Double) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let frames = AVAudioFrameCount(rate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let out = buffer.floatChannelData![0]
        let attack = 0.006
        for n in 0..<Int(frames) {
            let t = Double(n) / rate
            let envelope = min(1, t / attack) * pow(1 - t / duration, 2)
            let tone = sin(2 * .pi * frequency * t) + 0.25 * sin(4 * .pi * frequency * t)
            out[n] = Float(0.22 * envelope * tone)
        }
        return buffer
    }
}
