import Foundation
import Vapor

struct Routes {
    let adaptationController =  AdaptationController()
    
    func registerRoutes(app: Application) throws {
        app.get(use: index(request:))
        app.get("register", use: register(request:))
        app.post("execute", use: execute(request:))
        app.get("test", use: testCancelTaskLocal(request:))
        app.get("runTask", "outsideEU", use: runOutsideEUBackgroundTask(request:))
        app.get("runTask", "sensitiveData", use: runSensitiveDataBackgroundTask(request:))
        app.get("help", use: help(request:))
        
        try app.register(collection: TodoController())
    }
    
    func index(request: Request) async throws -> String {
        return "Welcome to the thesis-server!"
    }
    
    func configureOptionsText(request: Request) -> String {
        let app = request.application
        return app.routes.all.description
    }
    
    func register(request: Request) async throws -> String {
        let app = request.application
        let result = try await adaptationController.registerThisAppOnRadar(app: app)
        if result != -1 {
            return "Completed and successfully registered application on radar."
        } else {
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
    
    func testCancelTaskLocal(request: Request) -> Bool {
        adaptationController.outsideEU.cancelTask()
        adaptationController.sensitiveData.cancelTask()
        print(adaptationController.outsideEU.task as Any)
        print(adaptationController.sensitiveData.task as Any)
        return true
    }
    
    func runOutsideEUBackgroundTask(request: Request) -> Bool {
        adaptationController.outsideEU.getFilesConstantly()
        return true
    }
    
    func runSensitiveDataBackgroundTask(request: Request) -> Bool {
        adaptationController.sensitiveData.getFilesConstantly()
        return true
    }
    
    func cancelRunningBackgroundTask(request: Request) -> Bool {
        adaptationController.outsideEU.cancelTask()
        adaptationController.sensitiveData.cancelTask()
        return true
    }
    
    func help(request: Request) -> String {
        let app = request.application
        return app.routes.all.description
    }
}
