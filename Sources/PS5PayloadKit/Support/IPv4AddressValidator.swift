import Darwin
import Foundation

public enum IPv4AddressValidator {
    public static func isValid(_ value: String) -> Bool {
        var address = in_addr()
        return inet_pton(AF_INET, value, &address) == 1
    }
}
