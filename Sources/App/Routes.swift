import Foundation
import Vapor

struct Routes {
    let adaptationController =  AdaptationController()
    let logger = Logger.shared
    
    func registerRoutes(app: Application) throws {
        app.get(use: index(request:))
        app.get("register", use: register(request:))
        app.post("execute", use: execute(request:))
        app.get("test", use: testCancelTaskLocal(request:))
        app.get("runTask", "outsideEU", use: runOutsideEUBackgroundTask(request:))
        app.get("runTask", "sensitiveData", use: runSensitiveDataBackgroundTask(request:))
        app.get("help", use: help(request:))
        app.get("saveLogs", use: saveLogToFile(request:))
        app.get("stress", use: stressTest(request:))
        
        try app.register(collection: TodoController())
    }
    
    func index(request: Request) async throws -> String {
        return "Welcome to the thesis-server!"
    }
    
    func register(request: Request) async throws -> String {
        logger.add(message: "Attempting to register application on RADAR.")
        let app = request.application
        let result = try await adaptationController.registerThisAppOnRadar(app: app)
        if result != -1 {
            logger.add(message: "Registered application on RADAR.")
            return "Completed and successfully registered application on radar."
        } else {
            logger.add(message: "Error occurred when registering the application on RADAR.")
            return "An error occurred registering the application. Check radar for more information."
        }
    }
    
    func executeLocal(request: Request) -> Bool {
        let adapt = 1 // The adaptation to execute locally (1 for OutsideEU and 2 for SensitiveData).
        let data = "{ \"model\": \"test-local\", \"adaptations\": [\(adapt)]} "
        _ = adaptationController.root(data: data)
        print(adaptationController.outsideEU.task as Any)
        print(adaptationController.sensitiveData.task as Any)
        return true
    }
    
    func execute(request: Request) -> Bool {
        guard let data = request.body.string else {
            fatalError("Getting string from POST request failed")
        }
        
        let result = adaptationController.root(data: data)
        return result
    }
    
    func stressTest(request: Request) -> Bool {
        guard let users = request.parameters.get("users"), let usersInt = Int(users) else { fatalError() }
        StressTestController.shared.httpBenchmark(users: usersInt)
        return true
    }
    
    func testCancelTaskLocal(request: Request) -> Bool {
        adaptationController.outsideEU.cancelTask()
        adaptationController.sensitiveData.cancelTask()
        print(adaptationController.outsideEU.task as Any)
        print(adaptationController.sensitiveData.task as Any)
        return true
    }
    
    func runOutsideEUBackgroundTask(request: Request) -> Bool {
        logger.add(message: "Start the outsideEU getFilesConstantly task.")
        adaptationController.outsideEU.getFilesConstantly()
        logger.add(message: "Started the outsideEU getFilesConstantly task.")
        return true
    }
    
    func runSensitiveDataBackgroundTask(request: Request) -> Bool {
        logger.add(message: "Start the sensitive data getFilesConstantly task.")
        adaptationController.sensitiveData.getFilesConstantly()
        logger.add(message: "Started the sensitive data getFilesConstantly task.")
        return true
    }
    
    func cancelRunningBackgroundTask(request: Request) -> Bool {
        adaptationController.outsideEU.cancelTask()
        adaptationController.sensitiveData.cancelTask()
        logger.add(message: "Cancelled the running background tasks.")
        return true
    }
    
    func saveLogToFile(request: Request) -> String {
        logger.saveLogs()
        return "Saved logs."
    }
    
    func help(request: Request) -> String {
        let app = request.application
        return app.routes.all.description
    }
}
