# The Read

A tarot app for iOS by Paper Moon, built with SwiftUI and SwiftData. It draws a spread from a full Rider-Waite-Smith deck and sends the cards to Claude (Anthropic) for the interpretation. The app never holds an API key. Requests go through a small Cloudflare Worker (`proxy/`) that keeps the key, enforces daily limits, and streams the reply back.

## What it does

- Four tabs: **Today**, **Read**, **Journal**, **Deck**.
- **Today**: the daily card, drawn once per day and kept until midnight, plus a morning reminder.
- **Read**: choose a spread: Daily, Three, Four, Clarity, Ask (5 cards plus your question), and Read Me (4 cards, no holding back). Cards are turned one at a time, in order.
- **Journal**: every reading is saved on the device. Browse, select, and delete.
- **Deck**: all 78 cards with upright and reversed meanings.
- Free: the daily card plus 3 sample spreads. A one-time unlock (`theread.unlock`) opens every spread, up to 5 a day.
- First launch shows a short onboarding. The first reading asks for consent before anything is sent to the AI service.

## Requirements

- A Mac with Xcode (the project was built with Xcode 26)
- An iPhone or the iOS simulator
- Node.js and a Cloudflare account, only if you are working on the proxy

## Setup (app)

1. Clone the repo and check out your own branch (see Branches below).
2. Open `Tarot/The Read.xcodeproj`. Open the `.xcodeproj` file itself, not the folder. If you open the folder, Xcode will say the scheme has no targets.
3. Under the project's Signing & Capabilities tab, choose your own Team. If the bundle identifier (`com.papermoonstudio.theread`) belongs to another team, change it locally to something unique. Do not commit that change.
4. Pick a destination (simulator is best) and press Cmd+R.

No API key is needed to run the app. It talks to the deployed Worker.

## Testing purchases

Purchases are tested with a local StoreKit configuration file, so no App Store account is needed:

1. The scheme's Run, Options, StoreKit Configuration is set to `Products.storekit`. That file is not added to any target.
2. It holds one Non-Consumable product with ID `theread.unlock`.
3. Use the simulator. Test purchases are unreliable on a physical phone.
4. To reset, use Debug, StoreKit, Manage Transactions in Xcode, and delete the app from the simulator to restart the free samples.

## The proxy (`proxy/`)

A Cloudflare Worker that holds the Anthropic key and sits between the app and the API.

- Pins the model and caps `max_tokens`.
- Limits readings per device per day and across everyone per day (KV counters).
- Serves the privacy policy at `/privacy`.

Deploy:

```bash
cd proxy
npm install -g wrangler
wrangler login
wrangler kv namespace create LIMITS     # paste the id into wrangler.toml
wrangler secret put ANTHROPIC_API_KEY
wrangler deploy
```

The Anthropic key lives only as a Worker secret. Never put it in the app or in the repo. GitHub push protection will block the push if a key ends up in a commit. The limits are constants at the top of `proxy/src/index.js`.

## Branches

- `main` is the stable branch. Nothing goes straight to it.
- Each person works on their own branch (`elijah`, and your own).
- When something is ready, open a pull request from your branch into `main`.

```bash
git checkout -b yourname
git push -u origin yourname
```

## Project layout

App shell and screens:
- `ContentView.swift`: the tab shell, onboarding, and notification routing
- `TodayView.swift`: the Today tab and the daily card
- `ReadView.swift`: the Read tab, spread rows, locked spreads
- `ReadingView.swift`: a single reading: draw, turn cards, stream the interpretation, share
- `JournalRoot.swift`, `HistoryView.swift`: the Journal tab and its empty state
- `AllCardsView.swift`: the Deck tab and the card detail sheet
- `SettingsSheet.swift`, `ReminderSettingsSheet.swift`: settings and the daily reminder time
- `OnboardingView.swift`, `ConsentView.swift`, `PaywallView.swift`: first launch, AI consent, and the unlock screen

Logic and data:
- `Spread.swift`: one definition per spread (name, blurb, positions)
- `TarotAPI.swift`: request models, the prompt for each spread, and the call to the proxy
- `TarotSeed.swift`: the 78 card definitions, seeded into SwiftData on first launch
- `DailyCardStore.swift`: remembers today's daily card
- `PurchaseStore.swift`: the one-time unlock and the free sample counter (StoreKit 2)
- `NotificationHandler.swift`, `NotificationScheduler.swift`: the daily reminder
- `TarotIntent.swift`: App Intents for Siri and Shortcuts (still unreliable, see below)

Shared UI: `Theme.swift`, `ReadingComponents.swift`, `FlipCard.swift`, `ShareCardView.swift`, `ShareSheet.swift`, `Haptics.swift`, `QuestionInputSheet.swift`, `InterpretationParsing.swift`.

## Known issues

- Siri phrases are unreliable. The intents work when added as shortcuts in the Shortcuts app.
- Test purchases fail on physical phones under Xcode's StoreKit testing. Use the simulator, or TestFlight once the app is in App Store Connect.
- The Worker does not yet verify purchases. Unlocked limits are enforced in the app only.

## Before release

- Register the app and the `theread.unlock` product in App Store Connect.
- Verify purchases on the Worker (signed transactions).
- Fill in `shareLink` in `ReadingView.swift` once there is an App Store URL.
- Set a monthly spend limit in the Anthropic console.
