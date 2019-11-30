import Foundation


struct Galleries: Codable {
    
    var existing = [Gallery]()
    var removed  = [Gallery]()
    
    var json:Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init?(json: Data) {
        if let value = try? JSONDecoder().decode(Galleries.self, from: json) {
            self = value
        } else {
            return nil
        }
    }
    
    init() {}
    
}
