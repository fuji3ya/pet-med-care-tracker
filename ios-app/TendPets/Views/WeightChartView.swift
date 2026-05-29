import SwiftUI
import Charts

/// Weight trend line chart built from a pet's weight records. Shown in the
/// vet summary (Plus). Renders nothing useful with < 2 points, so callers
/// should check `points.count` first.
struct WeightChartView: View {
    let points: [(date: Date, value: Double)]
    var unit: String

    var body: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Weight", p.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(TPColor.primary)

                PointMark(
                    x: .value("Date", p.date),
                    y: .value("Weight", p.value)
                )
                .foregroundStyle(TPColor.primary)
            }
        }
        .chartYAxisLabel("Weight (\(unit))")
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 180)
        .padding(.vertical, 4)
    }
}
