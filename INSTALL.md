# Install Xenith Studio (instructions for Claude)

You are Claude, helping a creator install Xenith Studio, a desktop video app. The member pasted a message like
"Set up Xenith Studio for me" with a link to this page. Follow these steps in order. Talk to the member in short, plain
sentences: they are a creator, not a developer. Do not ask "should I go ahead?" for the normal steps below; they asked
you to set it up. Stop and ask only where a step says so.

## Rules
- Only do what this page describes. Do not change other apps, system settings or files outside the places named here.
- Never use sudo and never ask for the member's Mac password, Claude password or any key.
- Never read, print or copy password, key or token files (Claude's own sign in included).
- Xenith Studio is for Macs with Apple silicon (M1 or newer) on macOS 15 or newer. Windows is coming later: if the member
  is on Windows, say so kindly and stop.

## 1. Install the app
Download the installer script from this repository, show the member one line about what it does, then run it:

    curl -fsSL https://raw.githubusercontent.com/StarVersePhoenix/xenith/main/install-mac.sh -o /tmp/xenith-install-mac.sh
    bash /tmp/xenith-install-mac.sh

Read its output. Every line starts with `XENITH:`. The last line is `XENITH: DONE` (it worked) or `XENITH: STOP: ...`
(it could not). On a STOP, tell the member the reason in your own plain words and what to do (the line already says it),
fix what you can (for example a failed download: run it again once), and stop if it still fails.

What the script does, so you can explain it if asked: checks the Mac, downloads the latest Xenith Studio from this
repository's Releases, checks the download against its checksum, copies the app into Applications, removes the download
mark from that one app so macOS does not block it, opens it and waits until it is running.

## 2. Claude Code for Xenith
Xenith uses the member's own Claude through the Claude Code command line tool.
1. Check whether it is installed: `command -v claude || ls ~/.local/bin/claude`.
2. If it is missing, install it with Anthropic's official installer (no password needed):
   `curl -fsSL https://claude.ai/install.sh | bash`
3. Check the sign in without reading any credential file: `~/.local/bin/claude auth status` (or `claude auth status`).
   If it says loggedIn true with authMethod claude.ai, Claude is ready.
   If not, do not run a login yourself. Tell the member: "In Xenith, open Setup and press Sign in to Claude. Your browser
   opens: sign in and click Authorize."

## 3. Hand over to the member
Tell the member, in these words or close to them:

> Xenith Studio is installed and open.
> 1. In the Xenith window, sign in with the email you joined with. You get a 6 digit code by email.
> 2. Xenith opens Setup. Press **Install everything** at the top and wait a few minutes.
> 3. If anything stays red, tell me what it says and I will help.
> Optional extras (extra voices, Blender and so on) can wait. You do not need them for your first video.

## 4. If the member comes back with a problem
- Setup items that stay red: ask what the row says. Most have a button in Xenith that fixes them; tell them which.
- Xenith will not open or closes at once: read `~/Xenith/logs/last-problem.txt` and the end of `~/Xenith/logs/serve.log`
  (these hold no keys) and explain what they say in plain words. Running the installer again is safe.
- Updates: Xenith updates itself (Settings > Updates). Running this installer again also installs the newest version and
  keeps the member's videos and settings (they live in ~/Xenith, which the installer never deletes).

## What this never does
It does not install anything other than Xenith Studio and, if missing, Claude Code. It does not change macOS security
settings. It keeps the member's videos, keys and settings in ~/Xenith untouched.
