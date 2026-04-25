import SwiftUI
import Charts 

struct OOTDCalendarView: View {
    @StateObject private var viewModel = OOTDViewModel()
    @State private var showLogEditor = false
    @State private var showingNeglectedItems = false 
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekDays = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                calendarHeader
                
                HStack {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day).font(.system(size: 12, weight: .bold)).foregroundColor(.secondary).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(generateDays(), id: \.self) { date in
                        if let date = date {
                            DayCell(date: date, 
                                    isSelected: calendar.isDate(date, inSameDayAs: viewModel.state.selectedDate),
                                    log: viewModel.state.logs.first { calendar.isDate($0.date, inSameDayAs: date) })
                                .onTapGesture { viewModel.send(intent: .selectDate(date)) }
                        } else {
                            Spacer().frame(height: 80)
                        }
                    }
                }
                .padding(.horizontal)
                
                selectedDayDetail
                insightDashboard
            }
            .padding(.vertical)
        }
        .navigationTitle("OOTD Diary")
        .background(Color.white)
        .sheet(isPresented: $showLogEditor) {
            AddClothingToOOTDView(selectedDate: viewModel.state.selectedDate) { itemIds in
                viewModel.send(intent: .addLog(itemIds: itemIds))
                showLogEditor = false
            }
        }
        .sheet(isPresented: $showingNeglectedItems) {
            NeglectedItemsSheet(items: viewModel.calculateInsights().neglected)
        }
    }
    
    private var calendarHeader: some View {
        HStack {
            Text(viewModel.state.currentMonth.formatted(.dateTime.year().month(.twoDigits)))
                .font(.system(size: 22, weight: .black))
            Spacer()
            HStack(spacing: 20) {
                Button(action: { moveMonth(by: -1) }) { Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.black) }
                Button(action: { moveMonth(by: 1) }) { Image(systemName: "chevron.right").font(.system(size: 18, weight: .bold)).foregroundColor(.black) }
            }
        }
        .padding(.horizontal, 25)
    }
    
    private var selectedDayDetail: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.state.selectedDate, format: .dateTime.day().month(.wide)).font(.system(size: 18, weight: .bold))
                    Text(viewModel.state.selectedDate, format: .dateTime.weekday(.wide)).font(.system(size: 14)).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { showLogEditor = true }) {
                    Text("기록하기").font(.system(size: 14, weight: .bold)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Color.black).cornerRadius(20)
                }
            }
            
            if let log = viewModel.state.logs.first(where: { calendar.isDate($0.date, inSameDayAs: viewModel.state.selectedDate) }) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(log.itemSnapshots) { snapshot in
                            VStack(alignment: .leading) {
                                Group {
                                    if let data = snapshot.imageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Rectangle().fill(Color.fashionGray).overlay(Image(systemName: "photo").foregroundColor(.gray))
                                    }
                                }
                                .frame(width: 100, height: 130).background(Color.fashionGray).cornerRadius(12).clipped()
                                Text(snapshot.name).font(.system(size: 12, weight: .medium)).lineLimit(1).frame(width: 100)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "plus.app.dashed").font(.system(size: 30)).foregroundColor(.gray.opacity(0.5))
                    Text("오늘의 코디를 기록해보세요").font(.system(size: 14)).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.gray.opacity(0.2), style: StrokeStyle(dash: [5])))
            }
        }
        .padding(25)
    }
    
    private var insightDashboard: some View {
        let insights = viewModel.calculateInsights()
        let styleStats = calculateStyleStats() 
        
        return VStack(alignment: .leading, spacing: 30) {
            Divider()
            
            Text("Monthly Insight")
                .font(.system(size: 22, weight: .black))
            
            // [수정] 자주 입는 스타일 통계 (꺾은선 그래프 버전)
            VStack(alignment: .leading, spacing: 20) {
                Text("나의 스타일 분포")
                    .font(.system(size: 16, weight: .bold))
                
                if styleStats.isEmpty {
                    Text("데이터가 부족하여 통계를 낼 수 없습니다.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(Color.fashionGray.opacity(0.3))
                        .cornerRadius(15)
                } else {
                    Chart {
                        ForEach(styleStats, id: \.style) { stat in
                            // 꺾은선 (Line)
                            LineMark(
                                x: .value("스타일", stat.style),
                                y: .value("횟수", stat.count)
                            )
                            .interpolationMethod(.monotone)
                            .foregroundStyle(Color.blue.opacity(0.8))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            
                            // 데이터 점 (Point)
                            PointMark(
                                x: .value("스타일", stat.style),
                                y: .value("횟수", stat.count)
                            )
                            .foregroundStyle(Color.black)
                            .symbolSize(30)
                            .annotation(position: .top) {
                                Text("\(stat.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .padding(.top, 10)
                }
            }
            
            if !insights.top.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("가장 자주 찾은 옷").font(.system(size: 16, weight: .bold))
                    HStack(spacing: 20) {
                        ForEach(insights.top) { snapshot in
                            VStack {
                                Group {
                                    if let data = snapshot.imageData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                    } else { Circle().fill(Color.fashionGray) }
                                }
                                .frame(width: 70, height: 70).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 2)).shadow(radius: 2)
                                Text(snapshot.name).font(.system(size: 11)).lineLimit(1).frame(width: 70)
                            }
                        }
                    }
                }
            }
            
            if !insights.neglected.isEmpty {
                Button(action: { showingNeglectedItems = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("관심이 필요한 옷").font(.system(size: 15, weight: .bold)).foregroundColor(.black)
                            Text("\(insights.neglected.count)개의 옷을 이번 달에 입지 않았어요.").font(.system(size: 13)).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                    }
                    .padding().background(Color.fashionGray.opacity(0.8)).cornerRadius(15)
                }
            }
        }
        .padding(25)
    }
    
    private func calculateStyleStats() -> [(style: String, count: Int)] {
        var counts: [String: Int] = [:]
        for log in viewModel.state.logs {
            for item in log.itemSnapshots {
                counts[item.style, default: 0] += 1
            }
        }
        // X축에 스타일 이름이 나오므로 사전순 혹은 빈도순 정렬
        return counts.map { (style: $0.key, count: $0.value) }
            .sorted { $0.style < $1.style }
    }
    
    private func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: viewModel.state.currentMonth) {
            viewModel.send(intent: .changeMonth(newMonth))
        }
    }
    
    private func generateDays() -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: viewModel.state.currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.state.currentMonth)) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = firstWeekday - 1
        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in monthRange { if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) { days.append(date) } }
        return days
    }
}

// ... 나머지 DayCell 등 헬퍼 뷰는 동일 ...
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let log: OOTDLog?
    var body: some View {
        VStack(spacing: 6) {
            Text("\(Calendar.current.component(.day, from: date))").font(.system(size: 13, weight: isSelected ? .bold : .medium)).foregroundColor(isSelected ? .white : .primary).frame(width: 28, height: 28).background(isSelected ? Color.black : Color.clear).clipShape(Circle())
            ZStack {
                if let firstSnapshot = log?.itemSnapshots.first {
                    Group { if let data = firstSnapshot.imageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill) } else { Rectangle().fill(Color.fashionGray) } }
                    .frame(width: 40, height: 55).cornerRadius(8).clipped().overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.05), lineWidth: 1))
                } else { RoundedRectangle(cornerRadius: 8).fill(Color.fashionGray.opacity(0.3)).frame(width: 40, height: 55) }
            }
        }.frame(maxWidth: .infinity).padding(.vertical, 5)
    }
}

struct AddClothingToOOTDView: View {
    let selectedDate: Date
    let onSave: ([String]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var allItems: [ClothingItem] = []
    @State private var selectedIds: Set<String> = []
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("\(selectedDate, format: .dateTime.day().month().weekday()) 코디 기록").font(.subheadline).foregroundColor(.secondary).padding(.vertical, 10)
                Divider()
                if allItems.isEmpty {
                    VStack(spacing: 20) { Image(systemName: "hanger").font(.system(size: 50)).foregroundColor(.gray.opacity(0.3)); Text("옷장이 비어있습니다.\n먼저 옷을 등록해주세요.").multilineTextAlignment(.center).foregroundColor(.secondary) }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView { LazyVGrid(columns: columns, spacing: 15) { ForEach(allItems) { item in ClothingSelectionCard(item: item, isSelected: selectedIds.contains(item.id)).onTapGesture { if selectedIds.contains(item.id) { selectedIds.remove(item.id) } else { selectedIds.insert(item.id) } } } }.padding(20) }
                }
                Button(action: { onSave(Array(selectedIds)) }) { Text("\(selectedIds.count)개 옷 선택 완료").font(.system(size: 16, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(selectedIds.isEmpty ? Color.gray : Color.black).cornerRadius(15) }.disabled(selectedIds.isEmpty).padding(20)
            }.navigationTitle("옷 선택하기").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("취소") { dismiss() } } }.onAppear { self.allItems = WardrobeRepository.shared.getAllItems() }
        }
    }
}

struct ClothingSelectionCard: View {
    let item: ClothingItem
    let isSelected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let data = item.imageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().aspectRatio(1, contentMode: .fill) } else { Rectangle().fill(Color.fashionGray) }
                if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.black).background(Circle().fill(Color.white)).padding(8) }
            }.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.black : Color.clear, lineWidth: 3)).clipped()
            Text(item.name).font(.system(size: 12, weight: isSelected ? .bold : .regular)).lineLimit(1)
        }
    }
}

struct NeglectedItemsSheet: View {
    let items: [ClothingItem]
    @Environment(\.dismiss) var dismiss
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationView {
            ScrollView {
                if items.isEmpty { VStack(spacing: 20) { Image(systemName: "checkmark.circle.fill").font(.system(size: 50)).foregroundColor(.green); Text("모든 옷을 골고루 입고 계시네요!").foregroundColor(.secondary) }.padding(.top, 100)
                } else { LazyVGrid(columns: columns, spacing: 15) { ForEach(items) { item in Group { if let data = item.imageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().aspectRatio(1, contentMode: .fill) } else { Rectangle().fill(Color.fashionGray) } }.aspectRatio(1, contentMode: .fit).cornerRadius(12).clipped() } }.padding(20) }
            }.navigationTitle("잠자고 있는 옷들").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }
}
