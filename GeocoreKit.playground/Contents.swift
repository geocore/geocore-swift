import UIKit

func test() -> [String: String] {
    return [String: String]()
}

var baba = test()
baba["bubu"] = "bebe"

if let bebe = baba["bubu"] {
    print(bebe)
}
    