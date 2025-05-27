import SwiftUI

struct SleepRecordRow: View {
    let record: SleepRecord
    
    var body: some View {
        HStack(spacing: 15) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(record.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Sleep duration
            VStack(alignment: .leading, spacing: 2) {
                Text(record.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sleep score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(record.sleepScore))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(scoreColor)
                
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Sleep quality indicator
            Circle()
                .fill(scoreColor)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: record.date)
    }
    
    private var scoreColor: Color {
        switch record.sleepScore {
        case 80...:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    let record = SleepRecord(
        userId: UUID(),
        date: Date(),
        bedTime: Date().addingTimeInterval(-8 * 3600),
        wakeTime: Date(),
        totalSleepDuration: 7.5 * 3600
    )
    record.sleepQuality = 0.85
    
    return SleepRecordRow(record: record)
        .padding()
} 