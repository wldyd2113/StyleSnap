import Foundation
import Combine

protocol OOTDRepositoryProtocol {
    func saveLog(_ log: OOTDLog)
    func fetchLogs(for month: Date) -> AnyPublisher<[OOTDLog], Never>
    func deleteLog(id: UUID)
    func getWearCount(for itemId: String) -> Int
}

class OOTDRepository: OOTDRepositoryProtocol {
    static let shared = OOTDRepository()
    private let storageKey = "style_snap_ootd_logs"
    
    // 로컬 저장을 위해 간단히 UserDefaults 활용 (실무에서는 SwiftData/CoreData 권장)
    @Published private var logs: [OOTDLog] = []
    
    private init() {
        loadLogs()
    }
    
    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([OOTDLog].self, from: data) {
            self.logs = decoded
        }
    }
    
    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func saveLog(_ log: OOTDLog) {
        // 동일 날짜 기록은 업데이트, 아니면 추가 (startOfDay 정규화)
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: log.date)
        
        if let index = logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: targetDate) }) {
            logs[index] = log
        } else {
            logs.append(log)
        }
        saveToDisk()
    }
    
    func fetchLogs(for month: Date) -> AnyPublisher<[OOTDLog], Never> {
        $logs.map { logs in
            logs.filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
        }.eraseToAnyPublisher()
    }
    
    func deleteLog(id: UUID) {
        logs.removeAll { $0.id == id }
        saveToDisk()
    }
    
    func getWearCount(for itemId: String) -> Int {
        logs.filter { $0.itemIds.contains(itemId) }.count
    }
}
