# Thesis Server

This repository is the source code of the server used in Filippo Lobisch's Master thesis project.
This web server is developed in Swift, using the Vapor framework. 


## Getting Started

To get started using this software one can install Swift on the operating system or use docker containers. 
(Note: *docker containers do not communicate with each other*.)

### Prerequisites

To use this created server, ensure that Swift is installed on the device you want to execute this server from. 
To install Swift you can follow [this](https://www.swift.org/getting-started/) guide.
Alternatively, if the server will be used on macOS you can install swift by install Xcode.

### Installation

Firstly, ensure that your device satisfies all the preconditions.
Installing this web server application is as simple as downloading the *zip* of this repository and extracting it, or cloning it using `git clone`. 

### Building

To build this project, execute the following command: `swift build`.

This will build the project, from scratch if no prior build has even been performed. 
Otherwise, it will use already built components from a prior build and only rebuild the modified sources. 

### Running

To run this web server, use the following command: `swift run`.

This will build the project, if no build has been done for the current codebase, and then start the server. 
A logger message will be displayed indicating the URL to access the functionalities of this server application.

### Testing

To execute the tests included in the `Tests` directory, run the following command: `swift test`.

This will build the project, if no build has been done for the current codebase, and then execute the tests.


## Architecture

This server follows a *separation of concerns* technique.
Each component has a *need to know* thought process behind it so each element is only aware of its functionality and can only invoke the exposed methods of other classes/structures.
Furthermore, this server uses object-oriented-programming to achieve this separation through the use of inheritance.

### Adaptation

Adaptations are defined as Swift structures. 
They inherit from the `Adaptation` protocol, that has a set of required methods. 
The protocol is defined as follows:
```swift
protocol Adaptation {
    mutating func executeAdaptation() async throws -> Bool
    func stress() async
}
```

Finally, an enumeration is also created and used, through the use of a `switch` statement, to handle the incoming data and call the correct adaptation method.
It is defined as follows:
```swift
enum AdaptationType: Int {
    case outsideEU = 1
    case sensitiveData = 2
    case encryptData = 3
    
    init(_ string: String) {
        guard let key = Int(string), let adaptation = AdaptationType(rawValue: key) else {
            fatalError("The returned key does not contain an appropriate adaptation key.")
        }
        
        self = adaptation
    }
}
```

#### How to define/support a new adaptation

To extend this server and include additional adaptations, there are two steps:
1. Ensure that the adaptation object *inherits* the `Adaptation` protocol.
2. Implement the adaptation specific code in the `executeAdaptation` method and in the new object.
3. Add the adaptation, with its associated Integer value, to the `AdaptationType` enumeration.
4. Add the respective case wherever a switch is performed for an `AdaptationType`.

The resulting code should look along these lines:
```swift
struct MyNewAdaptation: Adaptation {
    mutating func executeAdaptation() async throws -> Bool {
        // Adaptation specific code.
    }
    
    func stress() async {
        // Adaptation specific stress test.
    }
    
    // Other methods and computed properties if needed.
}

enum AdaptationType: Int {
    case outsideEU = 1
    case sensitiveData = 2
    case encryptData = 3
    case myNewAdaptation = 4
    
    // ...
}
```

And inside the `AdaptationController class:
```swift
class AdaptationController {
    var myNewAdaptation = MyNewAdaptation()
    
    // ...
    
    final func main(data: String) async -> Bool {
        let adaptation = AdaptationType(data)
        
        switch adaptation {
        case .outsideEU:
            return await execute(adaptation: &outsideEU)
        case .sensitiveData:
            return await execute(adaptation: &sensitiveData)
        case .encryptData:
            return await execute(adaptation: &encryptData)
        case .myNewAdaptation:
            return await execute(adaptation: &myNewAdaptation)
        }
    }
    
    // ...
    
    func stress(data: String) async {
        let adaptation = AdaptationType(data)
        
        switch adaptation {
        case .outsideEU:
            await outsideEU.stress()
        case .sensitiveData:
            await sensitiveData.stress()
        case .encryptData:
            await encryptData.stress()
        case .myNewAdaptation:
            await myNewAdaptation.stress()
        }
    }
}
```


### Component

Like adaptations, components are defined as Swift structures.
They inherit from the `Component` protocol, that includes an `endpoint` property (used to connect to the component) and a method `stress` (used to stress the component).

```swift
protocol Component {
    var endpoint: String { get }
    
    func stress() async throws -> Bool
}
```

#### How to define/support a new component

To extend this server and include additional components, there are two steps:
1. Ensure that the new component controller object *inherits* the `Component` protocol.
2. Add the adaptation, with its associated Integer value, to the `ComponentHelper` enumeration, for easier storage of constants (*i.e.*, the endpoint).
3. Add an instance of the component controller wherever it is required for the new adaptation.


The resulting code should look along these lines:
```swift
enum ComponentHelper: Int {
    case componentA = 1
    case thesisServer = 2
    case componentB = 3
    case myNewComponent = 4
    
    var endpoint: String {
        switch self {
        case .componentA: return "http://127.0.0.1:3000"
        case .thesisServer: return "http://127.0.0.1:8080"
        case .componentB: return "http://127.0.0.1:3030"
        case .myNewComponent: return "http://127.0.0.1:0000"
        }
    }
}

struct MyNewComponentController: Component {
    var endpoint = ComponentHelper.myNewComponent.endpoint
    
    func stress() async throws -> Bool {
        // ...
    }
}
```

### Other components

This server also includes other necessary classes to retrieve, save, and delete files. 
This can be found in the `LocalManager` class located in the `Managers` folder.

Since we need to communicate with other components, a `NetworkManager` is also included. 
It contains generic methods to sending and getting data.

Lastly, included are some helper objects and extensions that are used throughout the codebase to aid the development.
