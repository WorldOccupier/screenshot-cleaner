/// The age range offered in the popover.
public enum AgeOption {
    /// Selected until the user drags the field; also the MCP server's default when the app has no setting saved.
    public static let `default` = 7
    public static let minimumDays = 1
    public static let maximumDays = 30

    /// Clamps a day count to the picker's 1…30 range.
    public static func clamp(_ days: Int) -> Int {
        min(max(days, minimumDays), maximumDays)
    }

    /// Lead-in shown beside the picker for a given selection.
    public static func caption(forDays days: Int) -> String {
        days == 0 ? "Any age" : "Older than"
    }
}
