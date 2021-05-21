import XCTest
@testable import OpenMarket

class OpenMarketTests: XCTestCase {
    
    // MARK:- Tool for test preparation
    func readLocalFile(forName name: String) -> Data? {
        do {
            if let bundlePath = Bundle.main.path(forResource: name,
                                                 ofType: "json"),
               let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                return jsonData
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK:- JSONParsing Test with Local JSON files
    func test_JSONParser_for_Item() throws {
        guard let localJSONData = readLocalFile(forName: "Item") else { throw APIError.JSONParseError }
        let jsonParser = JSONParser()
        guard let parsedItemData: Item = try? jsonParser.parseJSONDataToValueObject(with: localJSONData) else { throw APIError.JSONParseError }
        XCTAssertNotNil(parsedItemData)
    }
    
    func test_JSONParser_for_ItemList() throws {
        guard let localJSONData = readLocalFile(forName: "Items") else { throw APIError.JSONParseError }
        let jsonParser = JSONParser()
        guard let parsedItemListData: ItemList = try? jsonParser.parseJSONDataToValueObject(with: localJSONData) else { throw APIError.JSONParseError }
        XCTAssertNotNil(parsedItemListData)
    }
    
    func test_APIError_description() {
        let notFoundErrorMessage = "[Error] Cannot find data"
        let JSONParseErrorMessge = "[Error] Cannot parse JSONData"
        guard let testNotFoundErrorMessage = APIError.NotFound404Error.errorDescription else { return }
        guard let testJSONParseErrorMessage = APIError.JSONParseError.errorDescription else { return }
        XCTAssertEqual(testNotFoundErrorMessage, notFoundErrorMessage)
        XCTAssertEqual(testJSONParseErrorMessage, JSONParseErrorMessge)
    }
}