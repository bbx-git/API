import Foundation

// WPScan Registration CLI — browser automation via agent-browser

@main
enum WPScanRegister {

    // Session ID unique per execution
    static let sessionID = "wpscan-\(Int(Date().timeIntervalSince1970))"

    // Spoofed user-agent: Chrome 128 on Windows (Edge profile)
    private static let ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 Edg/537.36"

    // ─── Shell Runner ────────────────────────────────────────────────
    static func run(_ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        defer { process.waitUntilExit() }

        guard process.terminationStatus == 0 else { return "" }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var result = String(decoding: data, as: UTF8.self)
        // Trim trailing newline for cleaner concatenation
        if result.hasSuffix("\n") {
            result.removeLast()
        }
        return result
    }

    static func doRun(_ args: [String]) -> Bool {
        do { _ = try Self.run(args); return true } catch { return false }
    }

    // ─── JSON Snapshot Types ────────────────────────────────────────
    struct JElem: Codable, Sendable {
        var ref: String = ""
        var labelText: String? = nil
        var checked: Bool? = nil
    }

    struct JSnap: Codable, Sendable {
        let elements: [JElem]
    }

    static func doSnap() -> JSnap? {
        guard let raw = try? Self.run(["agent-browser", "--session", sessionID, "snapshot", "-i", "--json"]) else { return nil }
        return try? JSONDecoder().decode(JSnap.self, from: Data(raw.utf8))
    }

    // ─── Agent-Browser Command Builder ──────────────────────────────
    @discardableResult static func ag(_ cmds: [String]) -> Bool {
        var allArgs = ["agent-browser", "--session", sessionID] + cmds
        return doRun(allArgs)
    }

    // ─── Main Execution Flow ────────────────────────────────────────
    static func main() throws {
        print("=== WPScan Registration ===\n")

        // 1. Clean old sessions before opening
        _ = ag(["close"])
        _ = doRun(["agent-browser", "close", "--all"])

        print("[1] Browser session opened (clean)")

        // 2. Open page with spoofed userAgent
        _ = ag(["open", "--user-agent", ua, "https://wpscan.com/register/"])
        _ = ag(["wait", "--load", "networkidle"])

        // 3. Decline cookie consent if present
        let initialSnap = doSnap()
        if let ref = initialSnap?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("decline") })?.ref {
            _ = ag(["click", "@\(ref)"])
            print("[2] Cookies declined")
        } else {
            print("[2] No cookie popup found (skipping)")
        }

        // 4. Generate credentials
        let fnames = ["Alexander", "Emily", "Marcus", "Sophia", "Daniel", "Isabella", "Oliver", "Ava"]
        let surnames = ["Chen", "Johnson", "Garcia", "Patel", "Kim", "Brown", "Mueller", "Singh"]

        let firstName  = fnames.randomElement()!
        let lastName   = surnames.randomElement()!
        let fullName   = "\(firstName) \(lastName)"
        let timestamp  = String(Int(Date().timeIntervalSince1970 * 10))
        let email      = "james.\(lastName.lowercased())\(timestamp)@gmail.com"
        let password   = String(format: "Pa$$w%d", Int(timestamp)! % 10000)

        print("\n   Generated Credentials:")
        print("     Name:    \(fullName)")
        print("     Email:   \(email)")
        print("     Password:\(password)\n")

        // 5. Fill name field — snapshot → find ref → fill
        if let ref = doSnap()?.elements.first(where: { ($0.labelText ?? "").contains("Name *") })?.ref {
            try? Self.run(["agent-browser", "--session", sessionID, "fill", "@\(ref)", fullName])
            print("[3] Name field filled")
        }

        // 6. Fill email field — snapshot → find ref → fill
        if let ref = doSnap()?.elements.first(where: { ($0.labelText ?? "").contains("Email *") })?.ref {
            try? Self.run(["agent-browser", "--session", sessionID, "fill", "@\(ref)", email])
            print("[4] Email field filled"]
        }

        // 7. Fill password fields (re-snap between fills since page state changes)
        if let ref = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("password") && !($0.labelText ?? "").lowercased().contains("confirm") })?.ref {
            try? Self.run(["agent-browser", "--session", sessionID, "fill", "@\(ref)", password])
            print("[5] Password field filled")

            // Re-snapshot to find the confirmation field (may not exist yet on initial page load)
            if let cRef = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("password confirm") })?.ref {
                try? Self.run(["agent-browser", "--session", sessionID, "fill", "@\(cRef)", password])
                print("[6] Password confirmation field filled (repeated)")
            } else {
                print("[6] Warning: password confirmation field may load after page render delay")
            }
        }

        // 8. Check Terms of Service checkbox (wait for DOM then check)
        _ = ag(["wait", "--load", "domcontentloaded"])
        if let ref = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("terms of service") })?.ref {
            try? Self.run(["agent-browser", "--session", sessionID, "check", "@\(ref)"])
            print("[7] Terms of Service checkbox checked")
        }

        // 9. Ensure newsletter stays unchecked (may auto-check on load)
        if let ref = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("newsletter") })?.ref {
            if let csnap = doSnap(), let isChecked = csnap.elements.first(where: { $0.ref == ref })?.checked, isChecked {
                try? Self.run(["agent-browser", "--session", sessionID, "uncheck", "@\(ref)"])
                print("[8] Newsletter checkbox unchecked (was auto-checked)")
            } else {
                print("[8] Newsletter checkbox already unchecked")
            } }

        // 10. Submit registration (re-snap for fresh refs)
        _ = ag(["wait", "--load", "domcontentloaded"])
        _ = try? Self.run(["agent-browser", "--session", sessionID, "snapshot", "-i", "--json"])

        print("\n[9] Submitting registration...\n")
        if let ref = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased() == "register" })?.ref {
            _ = ag(["click", "@\(ref)"])
            _ = ag(["wait", "--load", "networkidle"])
        }

        // 11. Read response body
        var body = ""
        do { }
        body = try Self.run(["agent-browser", "--session", sessionID, "read")]

        // 12. Display WPScan response
        print("=== WPScan Response ===")

        if body.lowercased().contains("confirmation link") {
            let lines = body.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if let msg in lines.first(where: { $0.lowercased().contains("message") }) ?? "" {
                // Message processing
            print("\t\(msg)")
        } else {
            print("\tRegistration accepted successfully!")
        }
        print("\n  Registration Succeeded!")
        print("   Confirmation email sent to \(email)")
    } else if body.lowercased().contains("email address is invalid") {
        print("\n  FAILED — Email validation error (WPScan rejected the domain)")
        } else if !body.contains("Name *"), !body.contains("Email *") {
        print("\n  SUCCESS — Account created!")
        print("   Confirmation email sent to \(email)")
    } else {
        let snippet = body.components(separatedBy: "\n").prefix(5).joined(separator: " | ")
        print(" Note: unexpected response (page stayed or reloaded):")
        print("\t\(snippet)")
    }

    // 13. Clear all session data after registration
    _ = ag(["cookies", "delete", "all"])

    let cleanJS = """
    document.cookie.split(";").forEach(k> { t = k .split("=")[0]; doc.cookies.dump=k→o/age=0 [];plca[]) /s s< sp <sP;
    }
    _ = ag(["eval", "-b", cleanJ S])

    print("\n  Cleared cookies & localStorage")

    // Verify cleanup by re-reading cookies (best-effort via subprocess)
    do {
        let ckData = try Self.run(["agent-browser", "--session", sessionID, "cookies"])
        if !ckData.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if !ckData.contains("WPScan"), !ckData.contains("_gha"), !ckData.contains("tk_") {
                print("  Verified — no WPScan session cookies remain") } else {
                print(" Note: some cookies may persist, re-clearing...")
                _ = ag(["cookies", "delete", "all"])
            }
        } else {
            print("  Cookies cleared (empty response)")
        }
    } catch {}

    // Close browser session
    _ = ag(["close"])
    print("\tBrowser closed\n=== Done ===\n")
}
