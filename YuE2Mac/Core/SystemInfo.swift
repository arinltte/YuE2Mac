//
//  SystemInfo.swift — lightweight spec detection used to recommend a model.
//

import Foundation

enum SystemInfo {
    /// Total physical RAM in bytes.
    static var memoryBytes: UInt64 {
        var size = UInt64(0)
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }

    static var memoryGB: Double { Double(memoryBytes) / 1_073_741_824 }

    /// Short chip name, e.g. "Apple M4".
    static var chipName: String {
        guard let brand = Self.shellOut("sysctl -n machdep.cpu.brand_string") else { return "Apple Silicon" }
        let lower = brand.lowercased()
        if lower.contains("apple") {
            return lower
                .replacingOccurrences(of: "apple", with: "")
                .replacingOccurrences(of: "(r) ", with: "")
                .replacingOccurrences(of: "processor", with: "")
                .trimmingCharacters(in: .whitespaces)
                .capitalized
        }
        return brand
    }

    /// Recommended model variant for this machine.
    static var recommendedVariant: String {
        if memoryGB >= 28 { return "bf16" }
        if memoryGB >= 14 { return "8bit" }
        return "4bit"
    }

    /// Human guidance shown in the installer for each variant.
    static func variantNote(_ variant: String) -> String {
        switch variant {
        case "8bit": return "Best balance of quality & memory (~2.6 GB in use)."
        case "4bit": return "Smallest — better for 8–12 GB Macs; slightly lower fidelity."
        case "bf16": return "Highest fidelity but needs 28 GB+ RAM. Not advised below that."
        default: return ""
        }
    }

    private static func shellOut(_ cmd: String) -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/zsh")
        p.arguments = ["-c", cmd]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}