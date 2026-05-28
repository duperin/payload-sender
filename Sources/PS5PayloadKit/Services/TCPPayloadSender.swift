import Darwin
import Foundation

public struct TCPPayloadSender: Sendable {
    public init() {}

    public func testConnection(to host: String, port: Int, timeout: TimeInterval = 3) throws {
        let socketFD = try openSocket(to: host, port: port, timeout: timeout)
        close(socketFD)
    }

    public func send(file: URL, to host: String, port: Int) throws {
        let data = try Data(contentsOf: file)
        try send(data: data, to: host, port: port)
    }

    public func send(data: Data, to host: String, port: Int) throws {
        let socketFD = try openSocket(to: host, port: port, timeout: 8)
        defer { close(socketFD) }

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

    private func openSocket(to host: String, port: Int, timeout: TimeInterval) throws -> Int32 {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }

        do {
            try configureNonBlocking(socketFD)
            try connect(socketFD: socketFD, host: host, port: port, timeout: timeout)
            try configureBlocking(socketFD)
            return socketFD
        } catch {
            close(socketFD)
            throw error
        }
    }

    private func connect(socketFD: Int32, host: String, port: Int, timeout: TimeInterval) throws {
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

        if connected == 0 {
            return
        }

        guard errno == EINPROGRESS else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }

        var pollFD = pollfd(fd: socketFD, events: Int16(POLLOUT), revents: 0)
        let timeoutMilliseconds = Int32(max(1, timeout * 1000))
        let pollResult = Darwin.poll(&pollFD, 1, timeoutMilliseconds)

        guard pollResult > 0 else {
            if pollResult == 0 {
                throw PayloadError.connectionFailed("Timed out.")
            }
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }

        var socketError: Int32 = 0
        var socketErrorLength = socklen_t(MemoryLayout<Int32>.size)
        let optionResult = withUnsafeMutablePointer(to: &socketError) { pointer in
            getsockopt(socketFD, SOL_SOCKET, SO_ERROR, pointer, &socketErrorLength)
        }

        guard optionResult == 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }

        guard socketError == 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(socketError)))
        }
    }

    private func configureNonBlocking(_ socketFD: Int32) throws {
        let flags = fcntl(socketFD, F_GETFL, 0)
        guard flags >= 0, fcntl(socketFD, F_SETFL, flags | O_NONBLOCK) >= 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }
    }

    private func configureBlocking(_ socketFD: Int32) throws {
        let flags = fcntl(socketFD, F_GETFL, 0)
        guard flags >= 0, fcntl(socketFD, F_SETFL, flags & ~O_NONBLOCK) >= 0 else {
            throw PayloadError.connectionFailed(String(cString: strerror(errno)))
        }
    }
}
