import CleanerCore
import SwiftUI

/// "Older than  All 1d 1w 1m" with a pill that slides to the selection.
struct AgePicker: View {
    @Binding var days: Int
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            Text(AgeOption.caption(forDays: days))
                .contentTransition(.interpolate)
                .frame(width: 80, alignment: .leading)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 2) {
                ForEach(AgeOption.allCases) { option in
                    let selected = option.days == days
                    Text(option.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected ? AnyShapeStyle(.background) : AnyShapeStyle(.secondary))
                        .frame(width: 34, height: 24)
                        .background {
                            if selected {
                                Capsule().fill(.primary).matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { days = option.days }
                        }
                }
            }
        }
    }
}
