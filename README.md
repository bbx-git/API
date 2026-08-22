# WPSpan Registration CLI

[![Swift](https://img.shields.io/badge/Swift-6.4-orange?style=flat-square&logo=swift)](https://www.swift.org)
[![macOS](https://img.shields.io/badge/macOS-12.0+-purple?style=flat-square&logo=apple)](https://developer.apple.com/macos/)
[![Build](https://img.shields.io/badge/build-passed-brightgreen?style=flat-square)]()
[![Xcode](https://img.shields.io/badge/Xcode-beta-blue?style=flat-square&logo=xcode)]()
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)]()

A Swift CLI program that automates user registration on **WPScan.com** with headless browser testing.

## Overview

Generates random credentials, fills in the form via `agent-browser`, and handles cookies, localStorage, and session cleanup automatically — all using Apple frameworks and pure Swift.

## Features

- Random first/last name generation
- Timestamp-based email addresses (gmail format)
- Dynamic password creation with special characters
- Custom User-Agent spoofing (Chrome 128 / Windows Edge profile)
- Cookie clearing before and after registration
- localStorage & sessionStorage auto-cleanup via eval
- Full browser session isolation

## Requirements

| Tool | Version |
|------|---------|
| **Swift** | 6.4+ (`swiftlang-6.4.0.30.4`) |
| **macOS** | 12.0 (Monterey+) |
| **Xcode** | Beta (latest) |
| **agent-browser** | `npm i -g agent-browser` |

## Installation / Setup

```bash
# 1. Install browser automation
npm i -g agent-browser

# 2. Build and run
swift build --configuration release

# or just use swift run
swift run wpscan-register
```

The binary is deployed to `~/Applications/wpscan-register` on every successful build.

## Usage

Run the built-in registration flow:

```bash
swift run wpscan-register     # generates credentials & submits via browser
./wpscan-register              # or launch the compiled binary directly
```

Output includes generated fields, form actions, and WPScan confirmation status.

## Project Structure

```
api/                                  ← workspace root
├── CLAUDE.md
├── README.md
├── SESSION_STATE.md
├── Package.swift                     ← swift-tools-version: 6.0
└── SourceFile.swift                  (@main enum entry point)
└── Sources/wpscan/                   ← modular targets
└── temp/                             ← transient files (gitignored)
```

## Build & Deploy

```bash
xcodebuild -scheme wpscan-register \
           -configuration Release \
           -derivedDataPath .build/DerivedData \
           SYMROOT=.build/output
cp -R .build/output/Release/wpscan-register ~/Applications/
```

This follows the **Build & Deployment Rules** from `CLAUDE.md`.

## Roadmap / TODO

- [x] Browser automation via agent-browser
- [x] Random name/email/password generation
- [x] Cookie clearing (before & after)
- [x] Custom User-Agent header spoofing
- [x] Terms of Service checkbox handling
- [ ] Configurable test accounts via CLI args
- [ ] Confirmation email verification (imap fetch)
- [ ] Retry logic for failed submissions
