import XCTest

@testable import PhotoExhibition

@MainActor
final class MockProfileSetupStoreDelegate: ProfileSetupStoreDelegate {
  var didCompleteProfileSetupCalled = false

  func didCompleteProfileSetup() {
    didCompleteProfileSetupCalled = true
  }

  func reset() {
    didCompleteProfileSetupCalled = false
  }
}
