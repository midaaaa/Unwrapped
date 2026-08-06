<img src="docs/media/App%20Icon.png" width="96" alt="Unwrapped app icon" />

# Unwrapped

Spotify tells you what you listened to once a year. Unwrapped is for the rest of the time.

It's an iOS app for logging how you actually feel about the music you're listening to, right as you're listening to it — a quick tap on a mood, or a proper note if a track deserves one. Over time those little moments turn into a real diary of your listening life, and the app turns that diary back into something closer to a running, personal version of Wrapped: streaks, mood trends, the tracks and artists that quietly took over a given week, and how your taste has been drifting.

<img src="docs/media/1%20Player%20Active%20Entry.png" width="280" alt="Player screen with an active logged entry on the current track" />

https://github.com/user-attachments/assets/fdadee25-7d0e-428c-822f-3c4e316125fd

## What it's actually like to use

You open the app, and whatever's currently playing on Spotify is right there — album art, progress bar, play/pause that actually controls playback. Underneath it, a strip of mood chips: happy, nostalgic, hyped, whatever fits. Tap one and it's logged, timestamped to the exact second you were at in the track. If a track deserves more than an emoji, you can drop into a proper entry instead — a title, a note, a spot on the track's own timeline where the moment happened.

https://github.com/user-attachments/assets/427d328a-c3aa-4469-a2e4-ae96bd3aab3e

Every entry you've ever logged lives in a diary you can actually browse — not just a flat list. Switch between looking at it by entry, by track, or by artist; sort however makes sense that day; filter down to a mood or a date range. Tap into anything to read it back or edit it.

<img src="docs/media/3%20Diary%20Sort%20Filter%20Menu.png" width="280" alt="Diary browse/sort menu, grouped by track and sorted oldest first" />

And then there's Stats. Recap is the part that pulls it all together: a grid of cards that update week to week or month to month — your biggest mover, a new favorite artist, the mood that defined the week, how your logging streak is holding up. Underneath that, a deeper layer for when you want to dig in: genre breakdowns, how your Spotify top tracks compare to what you actually bothered to log, a heatmap of when you listen, discovery and replay patterns.

<table>
<tr>
<td><img src="docs/media/5%20Stats%20Recap%20Period.png" width="280" alt="Stats Recap card grid" /></td>
<td><img src="docs/media/6%20Stats%20Mood%20Activity.png" width="280" alt="Stats mood distribution and activity charts" /></td>
</tr>
</table>

<details>
<summary>More screenshots</summary>
<br>

<table>
<tr>
<td><img src="docs/media/7%20Player%20Active%20Entry%20Alt%20Track.png" width="280" alt="Player screen, a different track" /></td>
<td><img src="docs/media/10%20Stats%20Period%20Insights.png" width="280" alt="Stats period stats and insights" /></td>
</tr>
<tr>
<td><img src="docs/media/11%20Stats%20Top%20Tracks.png" width="280" alt="Stats top tracks list" /></td>
<td><img src="docs/media/12%20Stats%20Top%20Artists.png" width="280" alt="Stats top artists list" /></td>
</tr>
<tr>
<td><img src="docs/media/13%20Log%20Swipe%20Spotify%20Link.png" width="280" alt="Log tab, swiped row revealing the Spotify deep-link button" /></td>
<td><img src="docs/media/14%20Diary%20Entry%20Detail.png" width="280" alt="Diary entry detail viewer" /></td>
</tr>
</table>

https://github.com/user-attachments/assets/eee247db-1220-4973-8058-33858c0fc3f7

https://github.com/user-attachments/assets/dc56caf9-b361-4197-9aa6-bc07f50e261d

</details>

## Under the hood

Layered SwiftUI app: `Domain` (entities, repository protocols), `Data` (Spotify Web API + SwiftData), `Presentation` (`@Observable` view models + views). No server — API calls go directly from the device to Spotify.

Stack, no third-party dependencies:

- SwiftUI, iOS 26+
- SwiftData — diary, track/artist/taste cache
- Swift Concurrency — async/await, actors, `@Observable` (no Combine)
- `ASWebAuthenticationSession` — Spotify OAuth via PKCE (no client secret)
- Keychain — token storage
- `BGTaskScheduler` — periodic taste-snapshot refresh
- Swift Charts — Stats visualizations
- String Catalog — EN/RU localization
- XCTest — pure-logic unit tests

## Running it yourself

You'll need your own Spotify app registered at the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) — a redirect URI of `unwrapped://callback` and the usual read/playback scopes are enough. Drop your client ID into `Unwrapped/Support/SpotifyConfig.swift`, open the project in Xcode, and run it on a device or simulator running iOS 26. Since Spotify's developer program caps unverified apps at 25 authorized users, you'll need to add your own Spotify account as a user on the app in the dashboard before login will work.

## What this isn't

There's no account system beyond Spotify's own, no server, and no sync between devices — everything lives locally on the one device you're using, which means uninstalling the app takes your diary with it. That's a real limitation, not a feature.
