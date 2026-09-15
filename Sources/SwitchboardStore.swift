import AppKit
import Combine
import Darwin
import Foundation

@_silgen_name("proc_pidpath")
private func proc_pidpath(_ pid: Int32, _ buffer: UnsafeMutableRawPointer?, _ buffersize: UInt32) -> Int32

enum PrefKey {
    static let prefix = "engineer.badry.localhostswitchboard."
    static let refreshMs = prefix + "refreshMs"
    static let confirmKill = prefix + "confirmKill"
    static let pinnedPorts = prefix + "pinnedPorts"
    static let hideAppleSystem = prefix + "hideAppleSystem"
}

struct SwitchboardError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct Listener: Identifiable, Equatable, Sendable {
    var id: String { "\(pid)-\(host)-\(port)" }
    let command: String
    let pid: Int32
    let host: String
    let port: Int
    let path: String?

    var url: URL {
        let scheme = (port == 443 || port == 8443) ? "https" : "http"
        return URL(string: "\(scheme)://127.0.0.1:\(port)")!
    }

    var isAppleSystem: Bool {
        guard let path else { return false }
        return Self.applePrefixes.contains { prefix in
            path == prefix || path.hasPrefix(prefix + "/")
        }
    }

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        if command.lowercased().contains(q) { return true }
        if host.lowercased().contains(q) { return true }
        if String(port).contains(q) { return true }
        if String(pid).contains(q) { return true }
        if let path, path.lowercased().contains(q) { return true }
        return false
    }

    private static let applePrefixes = ["/usr/libexec", "/System", "/sbin", "/usr/sbin"]
}

struct LsofResult: Sendable {
    let listeners: [Listener]
    let stderr: String
    let status: Int32
}

enum ProcessPath {
    static func resolve(pid: Int32) -> String? {
        if let path = pidPath(pid), !path.isEmpty {
            return path
        }
        return psComm(pid: pid)
    }

    private static func pidPath(_ pid: Int32) -> String? {
        var buffer = [CChar](repeating: 0, count: 4096)
        let n = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard n > 0 else { return nil }
        return String(cString: buffer)
    }

    private static func psComm(pid: Int32) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "comm=", "-p", String(pid)]
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let text, !text.isEmpty {
            return text
        }
        return nil
    }
}

enum LsofScanner {
    private static let lineRegex: NSRegularExpression = {
        do {
            return try NSRegularExpression(
                pattern: #"^(\S+)\s+(\d+)\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(.+)$"#
            )
        } catch {
            preconditionFailure("lsof line regex failed: \(error.localizedDescription)")
        }
    }()

    static func scan() throws -> LsofResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN"]
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            throw error
        }
        process.waitUntilExit()
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        guard let stdout = String(data: outData, encoding: .utf8) else {
            throw SwitchboardError(message: "Cannot decode lsof stdout")
        }
        let stderr = String(data: errData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return LsofResult(
            listeners: parse(stdout),
            stderr: stderr,
            status: process.terminationStatus
        )
    }

    static func parse(_ stdout: String) -> [Listener] {
        var result: [Listener] = []
        var seen = Set<String>()
        for rawLine in stdout.split(whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let nsRange = NSRange(line.startIndex..., in: line)
            guard let match = lineRegex.firstMatch(in: line, options: [], range: nsRange),
                  match.numberOfRanges >= 4,
                  let commandRange = Range(match.range(at: 1), in: line),
                  let pidRange = Range(match.range(at: 2), in: line),
                  let nameRange = Range(match.range(at: 3), in: line),
                  let pid = Int32(line[pidRange])
            else {
                continue
            }
            let command = String(line[commandRange])
            var name = String(line[nameRange])
            if let range = name.range(of: " (LISTEN)", options: .backwards) {
                name.removeSubrange(range)
            } else if name.hasSuffix("(LISTEN)") {
                name = String(name.dropLast("(LISTEN)".count))
                    .trimmingCharacters(in: .whitespaces)
            }
            guard let colon = name.lastIndex(of: ":") else { continue }
            let host = String(name[..<colon])
            let portText = String(name[name.index(after: colon)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let port = Int(portText), (1...65535).contains(port) else { continue }
            let listener = Listener(
                command: command,
                pid: pid,
                host: host,
                port: port,
                path: ProcessPath.resolve(pid: pid)
            )
            if seen.insert(listener.id).inserted {
                result.append(listener)
            }
        }
        return result
    }
}

final class SwitchboardStore: ObservableObject {
    @Published var listeners: [Listener] = []
    @Published var errorMessage: String?
    @Published var persistenceError: String?
    @Published var filter: String = ""
    @Published var refreshMs: Int {
        didSet {
            UserDefaults.standard.set(refreshMs, forKey: PrefKey.refreshMs)
            restartTimer()
        }
    }
    @Published var confirmKill: Bool {
        didSet {
            UserDefaults.standard.set(confirmKill, forKey: PrefKey.confirmKill)
        }
    }
    @Published var hideAppleSystem: Bool {
        didSet {
            UserDefaults.standard.set(hideAppleSystem, forKey: PrefKey.hideAppleSystem)
        }
    }
    @Published var pinnedPorts: [Int] {
        didSet {
            savePinnedPorts()
        }
    }

    private var timer: Timer?
    private var inFlight = false
    private var pendingRefresh = false

    var visibleListeners: [Listener] {
        var items = listeners
        if hideAppleSystem {
            items = items.filter { !$0.isAppleSystem }
        }
        let query = filter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            items = items.filter { $0.matches(query) }
        }
        return items.sorted { a, b in
            let aPinned = pinnedPorts.contains(a.port)
            let bPinned = pinnedPorts.contains(b.port)
            if aPinned != bPinned { return aPinned && !bPinned }
            if a.port != b.port { return a.port < b.port }
            if a.pid != b.pid { return a.pid < b.pid }
            return a.host < b.host
        }
    }

    init() {
        let defaults = UserDefaults.standard
        if let stored = defaults.object(forKey: PrefKey.refreshMs) as? Int, stored > 0 {
            refreshMs = stored
        } else {
            refreshMs = 2000
        }
        if let stored = defaults.object(forKey: PrefKey.confirmKill) as? Bool {
            confirmKill = stored
        } else {
            confirmKill = true
        }
        if let stored = defaults.object(forKey: PrefKey.hideAppleSystem) as? Bool {
            hideAppleSystem = stored
        } else {
            hideAppleSystem = true
        }
        if let data = defaults.data(forKey: PrefKey.pinnedPorts) {
            do {
                pinnedPorts = try JSONDecoder().decode([Int].self, from: data)
            } catch {
                pinnedPorts = []
                persistenceError = error.localizedDescription
            }
        } else {
            pinnedPorts = []
        }
        restartTimer()
        refresh()
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        if inFlight {
            pendingRefresh = true
            return
        }
        inFlight = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let outcome: Result<LsofResult, Error>
            do {
                outcome = .success(try LsofScanner.scan())
            } catch {
                outcome = .failure(error)
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.inFlight = false
                switch outcome {
                case .success(let result):
                    self.apply(result)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                if self.pendingRefresh {
                    self.pendingRefresh = false
                    self.refresh()
                }
            }
        }
    }

    func togglePin(port: Int) {
        if let index = pinnedPorts.firstIndex(of: port) {
            pinnedPorts.remove(at: index)
        } else {
            pinnedPorts.append(port)
        }
    }

    func open(_ listener: Listener) {
        let ok = NSWorkspace.shared.open(listener.url)
        if !ok {
            errorMessage = "Could not open \(listener.url.absoluteString)"
        }
    }

    func copyURL(_ listener: Listener) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(listener.url.absoluteString, forType: .string)
    }

    func copyKill9(_ listener: Listener) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("kill -9 \(listener.pid)", forType: .string)
    }

    func killListener(_ listener: Listener) {
        if confirmKill {
            let alert = NSAlert()
            alert.messageText = "Kill \(listener.command)?"
            alert.informativeText =
                "Send SIGTERM to pid \(listener.pid) on port \(listener.port). If it is still listening after 3 seconds, send SIGKILL."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Kill")
            alert.addButton(withTitle: "Cancel")
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() != .alertFirstButtonReturn {
                return
            }
        }
        let pid = listener.pid
        errno = 0
        let term = Darwin.kill(pid, SIGTERM)
        if term != 0 {
            let code = Int(errno)
            errorMessage = NSError(domain: NSPOSIXErrorDomain, code: code).localizedDescription
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            Thread.sleep(forTimeInterval: 3)
            let still: Bool
            do {
                still = try LsofScanner.scan().listeners.contains { $0.pid == pid }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = error.localizedDescription
                }
                return
            }
            if still {
                _ = Darwin.kill(pid, SIGKILL)
            }
            DispatchQueue.main.async {
                self?.refresh()
            }
        }
    }

    private func apply(_ result: LsofResult) {
        listeners = result.listeners
        if result.status != 0 {
            if !result.stderr.isEmpty {
                errorMessage = result.stderr
            } else if result.listeners.isEmpty && result.status != 1 {
                errorMessage = "lsof exited with status \(result.status)"
            } else {
                errorMessage = nil
            }
        } else {
            errorMessage = nil
        }
    }

    private func savePinnedPorts() {
        do {
            let data = try JSONEncoder().encode(pinnedPorts)
            UserDefaults.standard.set(data, forKey: PrefKey.pinnedPorts)
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = max(0.2, Double(refreshMs) / 1000.0)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
