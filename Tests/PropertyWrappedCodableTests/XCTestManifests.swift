import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PropertyWrappedCodableTests.allTests),
        testCase(FamilyCodableTests.allTests),
        testCase(YAAFirebaseTests.allTests),
    ]
}
#endif
