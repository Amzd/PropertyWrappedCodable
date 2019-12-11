import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CodableCollectionTests.allTests),
        testCase(PropertyWrappedCodableTests.allTests),
        testCase(FamilyCodableTests.allTests),
    ]
}
#endif
