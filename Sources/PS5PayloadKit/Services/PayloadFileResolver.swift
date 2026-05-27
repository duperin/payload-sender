import Foundation

public enum PayloadFileResolver {
    public static func selectPayloadFile(from files: [URL], preferredFileName: String? = nil) throws -> URL {
        let sorted = files.sorted { lhs, rhs in
            lhs.lastPathComponent.localizedStandardCompare(rhs.lastPathComponent) == .orderedAscending
        }

        if let preferredFileName,
           let preferred = sorted.first(where: { $0.lastPathComponent.caseInsensitiveCompare(preferredFileName) == .orderedSame }) {
            return preferred
        }

        if let elf = sorted.first(where: { $0.pathExtension.lowercased() == "elf" }) {
            return elf
        }

        if let bin = sorted.first(where: { $0.pathExtension.lowercased() == "bin" }) {
            return bin
        }

        if let js = sorted.first(where: { $0.pathExtension.lowercased() == "js" }) {
            return js
        }

        throw PayloadError.payloadFileNotFound
    }

    public static func recursiveFiles(under directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL else { return nil }
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
            return values?.isRegularFile == true ? url : nil
        }
    }
}
