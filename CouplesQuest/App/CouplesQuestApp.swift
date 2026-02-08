import SwiftUI
import SwiftData

@main
struct CouplesQuestApp: App {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            PlayerCharacter.self,
            Stats.self,
            EquipmentLoadout.self,
            GameTask.self,
            AFKMission.self,
            ActiveMission.self,
            Equipment.self,
            Achievement.self,
            Dungeon.self,
            DungeonRun.self,
            DailyQuest.self,
            Bond.self,
            PartnerInteraction.self,
            WeeklyRaidBoss.self,
            ArenaRun.self,
            CraftingMaterial.self,
            Consumable.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Schema migration failed — delete old store and retry
            // This only happens during development when model fields change
            print("⚠️ ModelContainer failed, resetting database: \(error)")
            let url = modelConfiguration.url
            let fileManager = FileManager.default
            let storePath = url.path(percentEncoded: false)
            
            // Remove the main store file and all related side-car files
            for suffix in ["", "-shm", "-wal"] {
                let filePath = storePath + suffix
                if fileManager.fileExists(atPath: filePath) {
                    try? fileManager.removeItem(atPath: filePath)
                }
            }
            
            // Also remove the containing directory's .store files if present
            let storeDir = url.deletingLastPathComponent()
            if let contents = try? fileManager.contentsOfDirectory(
                at: storeDir,
                includingPropertiesForKeys: nil
            ) {
                for file in contents where file.lastPathComponent.contains("default.store") {
                    try? fileManager.removeItem(at: file)
                }
            }
            
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not initialize ModelContainer after reset: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GameEngine())
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}

