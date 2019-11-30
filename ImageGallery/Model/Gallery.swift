import Foundation

struct Gallery: Codable {
    var name:String
    var images = [Image]()
    
    init(name:String) {
        self.name = name
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
}
