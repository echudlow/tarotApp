// Privacy policy page, served at /privacy

export const PRIVACY_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>The Read: Privacy Policy</title>
<style>
  body { font-family: Georgia, serif; max-width: 640px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #222; }
  h1 { font-weight: 400; } h2 { font-weight: 400; margin-top: 2em; font-size: 1.15em; }
  .meta { color: #777; font-size: 0.9em; }
  @media (prefers-color-scheme: dark) { body { background: #000; color: #ddd; } .meta { color: #888; } a { color: #e8dfc4; } }
</style>
</head>
<body>
<h1>The Read: Privacy Policy</h1>
<p class="meta">Last updated: November 1, 2026</p>

<p>The Read is a tarot app for reflection and entertainment. This page explains what information the app uses and where it goes.</p>

<h2>What we collect</h2>
<p>We do not ask you to create an account, and we do not collect your name, email address, location, contacts, or advertising identifiers. The app has no analytics or tracking.</p>

<h2>What is sent when you do a reading</h2>
<p>To write a reading, the app sends the following to our server, which passes it to Anthropic, an AI company, to generate the text:</p>
<ul>
  <li>the cards you drew, their positions, and whether each is upright or reversed;</li>
  <li>the question you typed, if you used the Ask spread.</li>
</ul>
<p>Anthropic processes this to write your reading. How Anthropic handles data is described in its own privacy policy at <a href="https://www.anthropic.com/legal/privacy">anthropic.com/legal/privacy</a>. Please do not include personal or sensitive details in your questions.</p>

<h2>Usage limits</h2>
<p>The app creates a random identifier when it is first opened. It is not linked to your name or any account. It is sent with each reading request so we can limit the number of readings per device per day, and it is kept on our server for about a day and a half. Our server runs on Cloudflare, which may process standard technical request information, such as your IP address, to deliver the service.</p>

<h2>What stays on your device</h2>
<p>Your readings, journal, daily card, and reminder settings are stored only on your device. We cannot see them. Deleting the app deletes them.</p>

<h2>Notifications</h2>
<p>If you turn on the daily reminder, it is scheduled locally on your device. We do not send push notifications from a server.</p>

<h2>Not advice</h2>
<p>Readings are written by AI for reflection and entertainment. They are not professional, medical, legal, or financial advice.</p>

<h2>Children</h2>
<p>The Read is not directed to children under 13, and we do not knowingly collect information from them.</p>

<h2>Changes</h2>
<p>If this policy changes, we will update the date above.</p>

<h2>Contact</h2>
<p>Questions: <a href="mailto:CONTACT_EMAIL">CONTACT_EMAIL</a></p>
</body>
</html>`;
