import Foundation

struct Gallery: Codable {
    
    var name:String
    var scale = 1.0
    var images = [Image]()
    
    init(name:String) {
        self.name = name
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init?(json:Data) {
        if let newValue = try? JSONDecoder().decode(Gallery.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
    
}
