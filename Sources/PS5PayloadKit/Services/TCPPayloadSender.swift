import Darwin
import Foundation

public struct TCPPayloadSender: Sendable {
    public init() {}

    public func send(file: URL, to host: String, port: Int) throws {
        let data = try Data(contentsOf: file)
        try send(data: data, to: host, port: port)
    }

    public func send(data: Data, to host: String, port: Int) throws {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }
        defer { close(socketFD) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = UInt16(port).bigEndian

        guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
            throw PayloadError.invalidIP
        }

        let connected = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                Darwin.connect(socketFD, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard connected == 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }

        try data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            var sent = 0
            while sent < data.count {
                let result = Darwin.send(socketFD, baseAddress.advanced(by: sent), data.count - sent, 0)
                if result <= 0 {
                    throw PayloadError.sendFailed(String(cString: strerror(errno)))
                }
                sent += result
            }
        }
    }
}
