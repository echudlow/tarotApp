//
//  PurchaseStore.swift
//  The Read
//
//  Created by Elijah Hudlow on 11/1/26.
//

import SwiftUI
import StoreKit

@MainActor
@Observable
final class PurchaseStore {
    static let shared = PurchaseStore()

    /// Must match the product ID you create in App Store Connect and in the StoreKit config file.
    static let productID = "theread.unlock"

    /// TESTING SWITCH. While true, Xcode builds (DEBUG) behave as if the unlock were bought,
    /// so the store never needs to work on a physical phone. Set it to false to test the
    /// real purchase flow again. Release and TestFlight builds ignore this: always false there.
    #if DEBUG
    static let debugUnlockAll = true
    #else
    static let debugUnlockAll = false
    #endif

    private(set) var isUnlocked = PurchaseStore.debugUnlockAll || UserDefaults.standard.bool(forKey: "unlockedCache")
    private(set) var product: Product?
    private(set) var isWorking = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { await listen() }
        Task {
            await load()
            await refresh()
        }
    }

    func load() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            print("Product load failed:", error)
        }
    }

    /// Re-check what this Apple ID owns.
    func refresh() async {
        if Self.debugUnlockAll { isUnlocked = true; return }
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               t.productID == Self.productID,
               t.revocationDate == nil {
                found = true
            }
        }
        isUnlocked = found
        UserDefaults.standard.set(found, forKey: "unlockedCache")
    }

    private func listen() async {
        for await result in Transaction.updates {
            if case .verified(let t) = result {
                await t.finish()
                await refresh()
            }
        }
    }

    /// Returns true if the person ends up unlocked.
    func purchase() async -> Bool {
        errorMessage = nil
        if product == nil { await load() }
        guard let product else {
            errorMessage = "Couldn't reach the App Store. Try again in a moment."
            return false
        }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    await refresh()
                    return isUnlocked
                }
                errorMessage = "The purchase couldn't be verified."
                return false
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refresh()
            if !isUnlocked { errorMessage = "No earlier purchase found for this Apple ID." }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// The 3 free sample spreads (the daily card is always free and never counts).
enum FreeSampleStore {
    static let limit = 3
    private static let key = "freeSpreadsUsed"

    static var used: Int { UserDefaults.standard.integer(forKey: key) }
    static var remaining: Int { max(0, limit - used) }

    static func use() {
        UserDefaults.standard.set(used + 1, forKey: key)
    }
}
