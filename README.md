# WPScan Registration CLI

A simple Swift CLI program that registers a new user on the WPScan.com website using agent-browser for browser automation.

## Overview

This tool automates the WPScan registration process: generates a random name, fills in the registration form (name, email, password), agrees to terms of service, and submits the form via a headless Chrome browser launched through the `agent-browser` CLI. Designed as a proof-of-concept Swift-based browser automation demo that runs outside Xcode.

## Features

- Generates random first/last names for the registration
- Creates timestamps-based email addresses (user{timestamp}@outlook.com format)
- Generates random secure passwords
- Custom User-Agent header spoofing (Chrome on Windows via Edge)
- Cookie clearing before and after session
- localStorage/sessionStorage cleanup
- Full browser session isolation

## Installation / Setup

1. Install `agent-browser`: `npm i -g agent-browser`
2. Run the Swift CLI from this directory: `swift run wpscan-register`
3. No other dependencies — only Apple frameworks and pure Swift

## Usage

Run the binary directly or via `swift run`. The program generates all credentials internally.

```bash
swift run wpscan-register
```

This will launch a headless browser, navigate to WPScan's registration page, fill in the form, and report the result.

## Project structure

```
Project/
├── CLAUDE.md
├── README.md
├── SESSION_STATE.md
├── Package.swift
└── Sources/
    └── wpscan-register/
        └── main.swift
```

## Roadmap / TODO

- [x] Base registration flow
- [ ] Configurable test accounts via command-line args
- [ ] Verify the confirmation email was received (imap fetch)
- [ ] Add retry logic for failed form submissions
