# The Read

An iOS tarot app built with SwiftUI and SwiftData. It draws a spread from a full Rider-Waite deck and sends the cards to Claude (Anthropic API) for the interpretation.

Spreads: Daily, Three, Four, Clarity, Ask (5 cards plus your question), and Read Me (4 cards, no holding back). Readings are saved to a history you can browse, select, and delete. A daily notification reminds you to draw a card.

## Requirements

- A Mac with Xcode (the project was built with Xcode 26)
- An iPhone or the iOS simulator
- An Anthropic API key from https://console.anthropic.com

## Setup

1. Clone the repo and check out your own branch (see Branches below).
2. Open `Tarot/Tarot.xcodeproj`. Open the `.xcodeproj` file itself, not the folder. If you open the folder, Xcode will say the scheme has no targets.
3. Create your API key file. It is gitignored on purpose, so it will not be in the repo:
   - In Xcode, right-click the inner `Tarot` folder, then New File, then Property List, and name it `Config`.
   - Add a row with key `ANTHROPIC_API_KEY`, type `String`, and your key as the value.
   - Select `Config.plist` and, in the File Inspector, make sure the `Tarot` target is checked under Target Membership.
4. Under the project's Signing & Capabilities tab, choose your own Team so you can run on your device.
5. Pick a destination (simulator or your phone) and press Cmd+R.

Never commit `Config.plist` or paste a key into the code. GitHub push protection will block the push if a key ends up in a commit.

## Branches

- `main` is the stable branch. Nothing goes straight to it.
- Each person works on their own branch (`elijah`, and your own).
- When something is ready, open a pull request from your branch into `main`.

```bash
git checkout -b yourname
git push -u origin yourname
```

## Project layout

- `ContentView.swift`: home screen, spread buttons, the card fan and flip, interpretation
- `TarotAPI.swift`: request models, prompt building for each spread, and the Anthropic call
- `TarotSeed.swift`: the 78 card definitions, seeded into SwiftData on first launch
- `AllCardsView.swift`: the deck browser, grouped by suit
- `HistoryView.swift`: saved readings
- `QuestionInputSheet.swift`: the question prompt for the Ask spread
- `TarotIntent.swift`: App Intents for Siri and Shortcuts (still unreliable, see below)

## Known issues

- Siri phrases are unreliable. The intents work when added as shortcuts in the Shortcuts app.
- The API key is bundled in the app, so this is meant for personal builds. Do not distribute it publicly without moving the key to a small backend.
