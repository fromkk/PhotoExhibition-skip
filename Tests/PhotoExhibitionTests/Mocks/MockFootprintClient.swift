import Foundation

@testable import PhotoExhibition

@MainActor
final class MockFootprintClient: FootprintClient {
  var recordFootprintWasCalled = false
  var fetchFootprintsWasCalled = false
  var toggleFootprintWasCalled = false
  var getVisitorCountWasCalled = false
  var hasAddedFootprintWasCalled = false

  var recordFootprintExhibitionId: String?
  var recordFootprintUserId: String?
  var recordFootprintResult: Footprint?
  var recordFootprintError: Error?

  var fetchFootprintsExhibitionId: String?
  var fetchFootprintsCursor: String?
  var fetchFootprintsResult: ([Footprint], String?)?
  var fetchFootprintsError: Error?

  var toggleFootprintExhibitionId: String?
  var toggleFootprintUserId: String?
  var toggleFootprintResult = false
  var toggleFootprintError: Error?

  var getVisitorCountExhibitionId: String?
  var getVisitorCountResult = 0
  var getVisitorCountError: Error?

  var hasAddedFootprintExhibitionId: String?
  var hasAddedFootprintUserId: String?
  var hasAddedFootprintResult = false
  var hasAddedFootprintError: Error?

  func recordFootprint(exhibitionId: String, userId: String) async throws -> Footprint {
    recordFootprintWasCalled = true
    recordFootprintExhibitionId = exhibitionId
    recordFootprintUserId = userId

    if let error = recordFootprintError {
      throw error
    }

    return recordFootprintResult
      ?? Footprint(
        id: "mock-footprint-id",
        exhibitionId: exhibitionId,
        userId: userId,
        createdAt: Date()
      )
  }

  func fetchFootprints(exhibitionId: String, cursor: String?) async throws -> (
    footprints: [Footprint], nextCursor: String?
  ) {
    fetchFootprintsWasCalled = true
    fetchFootprintsExhibitionId = exhibitionId
    fetchFootprintsCursor = cursor

    if let error = fetchFootprintsError {
      throw error
    }

    return fetchFootprintsResult ?? ([], nil)
  }

  func toggleFootprint(exhibitionId: String, userId: String) async throws -> Bool {
    toggleFootprintWasCalled = true
    toggleFootprintExhibitionId = exhibitionId
    toggleFootprintUserId = userId

    if let error = toggleFootprintError {
      throw error
    }

    return toggleFootprintResult
  }

  func getVisitorCount(exhibitionId: String) async throws -> Int {
    getVisitorCountWasCalled = true
    getVisitorCountExhibitionId = exhibitionId

    if let error = getVisitorCountError {
      throw error
    }

    return getVisitorCountResult
  }

  func hasAddedFootprint(exhibitionId: String, userId: String) async throws -> Bool {
    hasAddedFootprintWasCalled = true
    hasAddedFootprintExhibitionId = exhibitionId
    hasAddedFootprintUserId = userId

    if let error = hasAddedFootprintError {
      throw error
    }

    return hasAddedFootprintResult
  }
}
