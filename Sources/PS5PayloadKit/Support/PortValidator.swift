public enum PortValidator {
    public static func clamped(_ port: Int) -> Int {
        min(max(port, 1), 65535)
    }
}
