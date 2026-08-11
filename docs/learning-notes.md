# Learning Notes — Publishing ScrollHot

A running archive of concepts that came up while turning this Xcode project into a public GitHub repo. Written to be re-read later.

## 1. Git: turning a folder into a repo

Git tracks a folder's history. Three states a file can be in: **untracked** (git ignores it), **staged** (marked for the next snapshot), **committed** (saved in history).

```bash
git init                 # start tracking this folder
git add .                # stage everything not covered by .gitignore
git commit -m "message"  # save a snapshot with a note
```

A **commit** is one snapshot. A **branch** is a moving pointer to a line of commits; the default is usually `main`. A **remote** is a copy of the repo hosted elsewhere (GitHub); `origin` is the conventional name for the primary remote.

```bash
git remote add origin <url>   # link local repo to GitHub
git push -u origin main       # upload; -u remembers the link so future pushes are just `git push`
```

## 2. `.gitignore` — why build output stays out

You commit **source**, not **generated files**. Xcode regenerates `DerivedData/`, `build/`, and per-developer state (`xcuserdata/`, `*.xcuserstate`) on every build. Committing them causes noise and merge conflicts, so `.gitignore` lists patterns git should never track. `.DS_Store` (macOS Finder metadata) is also excluded.

Rule of thumb: **if a clean checkout can rebuild it, ignore it.**

## 3. `gh` — the GitHub CLI

`gh` is GitHub's official command-line tool. Unlike plain `git`, it talks to GitHub's API, so it can create/rename repos, open PRs, etc.

```bash
gh auth status                 # confirm you're logged in
gh repo rename NEWNAME         # rename the repo tied to the current folder
gh repo list                   # see your repos (find the exact old name)
```

Rename vs. new repo: **renaming keeps stars, issues, and history**; the old URL auto-redirects for a while. That's why we renamed MouseyHot → ScrollHot instead of starting fresh.

## 4. Xcode / Swift concepts in this app

- **Menu-bar-only app**: `LSUIElement = true` in `Info.plist` hides the Dock icon. In code, `NSApp.setActivationPolicy(.accessory)` does the same at runtime.
- **`CGEventTap`**: a low-level hook that lets the app see (and optionally swallow) input events system-wide. Returning `nil` from the callback **consumes** the event so the normal middle-click never happens.
- **Accessibility permission**: any app that taps global input must be granted Accessibility access. `AXIsProcessTrusted()` checks it; `AXIsProcessTrustedWithOptions` prompts for it.
- **App Sandbox off**: the sandbox blocks system-wide event taps, so `ScrollHot.entitlements` sets `com.apple.security.app-sandbox = false`. This is why the app can't be distributed on the Mac App Store as-is.
- **`UserDefaults`**: simple key-value storage for small settings (the chosen shortcut, enabled flag) — persists across launches without a database.
- **SwiftUI + AppKit bridge**: the popover UI is SwiftUI (`ContentView`), but the key-recorder needs raw `keyDown` events, so it's an AppKit `NSView` wrapped with `NSViewRepresentable`.

## 5. Shell one-liners worth remembering

```bash
find . -type f            # list every file under the current folder, recursively
grep -E "PATTERN" file    # search with extended regex
cmd1 && cmd2              # run cmd2 only if cmd1 succeeded (chain steps safely)
```

---

_Add to this file as new concepts come up — it's meant to grow._
