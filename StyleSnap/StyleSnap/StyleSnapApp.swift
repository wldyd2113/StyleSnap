//
//  StyleSnapApp.swift
//  StyleSnap
//
//  Created by 차지용 on 4/17/26.
//

import SwiftUI
import RealmSwift

@main
struct StyleSnapApp: App {
    init() {
        // 앱 시작 시 데이터베이스 설정 초기화
        let config = Realm.Configuration(
            schemaVersion: 2,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
        print("DEBUG: Realm default configuration set at App start")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
