import SwiftUI
import WidgetKit

/// 홈 화면 "D+일수" 위젯. 앱(lib/data/day_widget.dart)이 App Group에 넘긴 사귄 날짜로
/// 일수를 직접 계산하고, 자정마다 다음 날 일수로 바뀌도록 타임라인을 만든다.
/// 시작일이 D+1이다 (CoupleProfile.dayCountOn과 같다).

private let appGroupId = "group.com.junsupark.coupleCalendar"

struct Couple {
  let myName: String
  let partnerName: String
  let startDate: Date

  static let sample = Couple(
    myName: "우리",
    partnerName: "함께",
    startDate: Calendar.current.date(byAdding: .day, value: -99, to: Date())!
  )

  static func load() -> Couple? {
    let defaults = UserDefaults(suiteName: appGroupId)
    guard
      let start = defaults?.string(forKey: "startDate").flatMap(parseDate),
      let myName = defaults?.string(forKey: "myName"),
      let partnerName = defaults?.string(forKey: "partnerName")
    else { return nil }
    return Couple(myName: myName, partnerName: partnerName, startDate: start)
  }

  /// "yyyy-MM-dd" → 그 날짜의 자정(현지 시간).
  private static func parseDate(_ s: String) -> Date? {
    let parts = s.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    return Calendar.current.date(
      from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
  }

  func dayCount(on day: Date) -> Int {
    let calendar = Calendar.current
    let days = calendar.dateComponents(
      [.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: day)
    ).day ?? 0
    return days + 1
  }
}

struct DayEntry: TimelineEntry {
  let date: Date
  let couple: Couple?
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> DayEntry {
    DayEntry(date: Date(), couple: .sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
    // 위젯 갤러리에서는 연결 전이어도 예시를 보여준다.
    let couple = Couple.load() ?? (context.isPreview ? .sample : nil)
    completion(DayEntry(date: Date(), couple: couple))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
    let couple = Couple.load()
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    // 지금 + 앞으로 7일의 자정. 그 뒤에는 시스템이 타임라인을 다시 요청한다.
    var entries = [DayEntry(date: Date(), couple: couple)]
    for offset in 1...7 {
      let midnight = calendar.date(byAdding: .day, value: offset, to: today)!
      entries.append(DayEntry(date: midnight, couple: couple))
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

private extension Color {
  static let primary = Color(red: 0x9A / 255, green: 0x44 / 255, blue: 0x2D / 255)
  static let coral = Color(red: 0xE0 / 255, green: 0x7A / 255, blue: 0x5F / 255)
  static let onSurfaceVariant = Color(red: 0x55 / 255, green: 0x42 / 255, blue: 0x3E / 255)
  static let outline = Color(red: 0x88 / 255, green: 0x72 / 255, blue: 0x6D / 255)
  static let surface = Color(red: 0xFF / 255, green: 0xF8 / 255, blue: 0xF6 / 255)
  static let primaryFixed = Color(red: 0xFF / 255, green: 0xDB / 255, blue: 0xD2 / 255)
}

struct DayWidgetView: View {
  let entry: DayEntry

  var body: some View {
    VStack(spacing: 2) {
      if let couple = entry.couple {
        let count = couple.dayCount(on: entry.date)
        let next = (count / 100 + 1) * 100
        HStack(spacing: 4) {
          Text(couple.myName)
          Image(systemName: "heart.fill").foregroundColor(.coral).font(.system(size: 10))
          Text(couple.partnerName)
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.onSurfaceVariant)
        .lineLimit(1)
        Text("D+\(count)")
          .font(.system(size: 34, weight: .heavy, design: .rounded))
          .foregroundColor(.primary)
          .minimumScaleFactor(0.6)
          .lineLimit(1)
        Text("\(next)일까지 \(next - count)일")
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(.outline)
      } else {
        Image(systemName: "heart.fill").foregroundColor(.coral).font(.system(size: 26))
        Text("앱에서 커플을\n연결해 주세요")
          .font(.system(size: 12, weight: .semibold))
          .multilineTextAlignment(.center)
          .foregroundColor(.onSurfaceVariant)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetBackground(
      LinearGradient(colors: [.surface, .primaryFixed], startPoint: .top, endPoint: .bottom))
  }
}

private extension View {
  /// iOS 17부터는 위젯 배경을 containerBackground로 지정해야 한다.
  @ViewBuilder
  func widgetBackground<B: View>(_ background: B) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      self.padding().background(background)
    }
  }
}

@main
struct DayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DayWidget", provider: Provider()) { entry in
      // 위젯을 누르면 앱이 열린다 (기본 동작).
      DayWidgetView(entry: entry)
    }
    .configurationDisplayName("데이로그")
    .description("우리가 함께한 날을 홈 화면에서 봐요")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
