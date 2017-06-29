import Foundation

// Responsibility: Convert to/from JSON, interact w/ Acronym class
class AcronymAPI {

  static func acronymsToDictionary(_ acronyms: [Acronym]) -> [[String: Any]] {
    var acronymsJson: [[String: Any]] = []
    for row in acronyms {
      acronymsJson.append(row.asDictionary())
    }
    return acronymsJson
  }

  static func allAsDictionary() throws -> [[String: Any]] {
    let acronyms = try Acronym.all()
    return acronymsToDictionary(acronyms)
  }

  static func all() throws -> String {
    return try allAsDictionary().jsonEncodedString()
  }


  static func matchingShort(_ matchingShort: String) throws -> String {
    let acronyms = try Acronym.getAcronyms(matchingShort: matchingShort)
    return try acronymsToDictionary(acronyms).jsonEncodedString()
  }

  static func notMatchingShort(_ notMatchingShort: String) throws -> String {
    let acronyms = try Acronym.getAcronyms(notMatchingShort: notMatchingShort)
    return try acronymsToDictionary(acronyms).jsonEncodedString()
  }

  static func delete(id: Int) throws {
    let acronym = try Acronym.getAcronym(matchingId: id)
    try acronym.delete()
  }

  static func test() throws -> String {
    let acronym = Acronym()
    acronym.short = "AFK"
    acronym.long = "Away From Keyboard"
    try acronym.save { id in
      acronym.id = id as! Int
    }

    return try all()
  }

  static func newAcronym(withShort short: String, long: String) throws -> [String: Any] {
    let acronym = Acronym()
    acronym.short = short
    acronym.long = long
    try acronym.save { id in
      acronym.id = id as! Int
    }
    return acronym.asDictionary()
  }

  static func newAcronym(withJSONRequest json: String?) throws -> String {
    guard let json = json,
          let dict = try json.jsonDecode() as? [String: String],
          let short = dict["short"],
          let long = dict["long"] else {
      return "Invalid parameters"
    }

    return try newAcronym(withShort: short, long: long).jsonEncodedString()
  }

  static func updateAcronym(withJSONRequest json: String?) throws -> String {
    guard let json = json,
          let dict = try json.jsonDecode() as? [String: Any],
          let id = dict["id"] as? Int,
          let short = dict["short"] as? String,
          let long = dict["long"] as? String else {
      return "Invalid parameters"
    }

    let acronym = try Acronym.getAcronym(matchingId: id)
    acronym.short = short
    acronym.long = long
    try acronym.save()

    return try acronym.asDictionary().jsonEncodedString()
  }

}
