import Foundation

@main
enum WPScanRegister {

    static let sessionID = "wpscan-\(Int(Date().timeIntervalSince1970))"
    private static let ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 Edg/537.36"

    static func run(_ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = Array(args)
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        defer { process.waitUntilExit() }
        guard process.terminationStatus == 0 else { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var result = String(decoding: data, as: UTF8.self)
        if result.hasSuffix("\n") { result.removeLast() }
        return result
    }

    static func doRun(_ args: [String]) -> Bool {
        do { try run(args); return true } catch { return false }
    }

    struct JElem: Codable, Sendable {
        var ref: String = ""
        var labelText: String? = nil
        var checked: Bool? = nil
    }

    struct JSnap: Codable, Sendable { let elements: [JElem] }

    static func doSnap() -> JSnap? {
        guard let raw = try? run(["agent-browser", "--session", sessionID, "snapshot", "-i", "--json"]) else { return nil }
        return try? JSONDecoder().decode(JSnap.self, from: Data(raw.utf8))
    }

    @discardableResult static func ag(_ cmds: [String]) -> Bool {
        var allArgs = ["agent-browser", "--session", sessionID] + cmds
        return doRun(allArgs)
    }

    private static func snapContains(_ substring: String) -> String? {
        guard let snap = doSnap() else { return nil }
        return snap.elements.first(where: { ($0.labelText ?? "").lowercased().contains(substring.lowercased()) })?.ref
    }

    static func main() throws {
        print("=== WPScan Registration ===\n")

        _ = ag(["close"])
        _ = doRun(["agent-browser", "close", "--all"])
        print("[1] Browser session opened (clean)")

        _ = ag(["open", "--user-agent", ua, "https://wpscan.com/register/"])
        _ = ag(["wait", "--load", "networkidle"])

        if let ref = snapContains("decline") {
            _ = ag(["click", "@\(ref)"]); print("[2] Cookies declined")
        } else { print("[2] No cookie popup found (skipping)") }

        let fnames = ["Alexander","Emily","Marcus","Sophia","Daniel","Isabella","Oliver","Ava"]
        let surnames = ["Chen","Johnson","Garcia","Patel","Kim","Brown","Mueller","Singh"]
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

        if let ref = snapContains("Name *") {
            try? run(["agent-browser", "--session", sessionID, "fill", "@\(ref)", fullName])
            print("[3] Name field filled")
        }

        if let ref = snapContains("Email *") {
            try? run(["agent-browser", "--session", sessionID, "fill", "@\(ref)", email])
            print("[4] Email field filled")
        }

        if let pwRef = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("password") && !($0.labelText ?? "").lowercased().contains("confirm") })?.ref {
            try? run(["agent-browser", "--session", sessionID, "fill", "@\(pwRef)", password])
            print("[5] Password field filled")

            if let cRef = doSnap()?.elements.first(where: { ($0.labelText ?? "").lowercased().contains("confirm") })?.ref {
                try? run(["agent-browser", "--session", sessionID, "fill", "@\(cRef)", password])
                print("[6] Password confirmation filled")
            } else {
                print("[6] Warning: password confirm may load after render delay")
            }
        }

        _ = ag(["wait", "--load", "domcontentloaded"])
        if let ref = snapContains("terms of service") {
            _ = try? run(["agent-browser", "--session", sessionID, "check", "@\(ref)"])
            print("[7] Terms of Service checked)")
        }

        if let ref = snapContains("newsletter") {
            if let csnap = doSnap(), csnap.elements.contains(where: { $0.ref == ref }) {
                _ = try? run(["agent-browser", "--session", sessionID, "uncheck", "@\(ref)"])
                print("[8] Newsletter unchecked")
            } else { print("[8] Newsletter already unchecked") }
        }

        _ = ag(["wait", "--load", "domcontentloaded"])
        let _ = doSnap()
        print("\n[9] Submitting registration...")

        if let ref = snapContains("register") {
            _ = ag(["click", "@\(ref)"]); _ = ag(["wait", "--load", "networkidle"]) }

        var body = ""
        do { body = try run(["agent-browser", "--session", sessionID, "read"]) } catch {}
        print("=== WPScan Response ===")

        if let firstLine = body.lowercased().split(separator: "\n").first,
           firstLine.contains("confirmation link") {
            let lines = body.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if let msg = lines.first(where: { $0.lowercased().contains("message") }) {
                print("\t\(msg)")
            } else {
                print("\tOK!")
            }
        }

        // Close browser session
        _ = ag(["cookies", "delete", "all"])
        _ = ag(["close"])
        print("\tBrowser closed\n=== Done ===\n")
    }
}
