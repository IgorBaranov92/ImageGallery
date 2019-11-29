import Foundation

struct Gallery {
    var name:String
    var images = [Image]()
    
    init(name:String) {
        self.name = name
    }
    
}
