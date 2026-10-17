/// The age choices offered in the popover.
public enum AgeOption: Int, CaseIterable, Identifiable, Sendable {
    case all = 0
    case day = 1
    case week = 7
    case month = 30

    public var id: Int { rawValue }
    public var days: Int { rawValue }

    public var label: String {
        switch self {
        case .all: "All"
        case .day: "1d"
        case .week: "1w"
        case .month: "1m"
        }
    }

    /// Lead-in shown beside the picker for a given selection.
    public static func caption(forDays days: Int) -> String {
        days == 0 ? "Any age" : "Older than"
    }
}
