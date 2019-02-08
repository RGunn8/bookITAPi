import Authentication
import Crypto
import FluentPostgreSQL
import Vapor

/// An ephermal authentication token that identifies a registered user.
final class UserToken: PostgreSQLModel {
    /// Creates a new `UserToken` for a given user.
    static func create(userID: User.ID) throws -> UserToken {
        // generate a random 128-bit, base64-encoded string.
        let string = try CryptoRandom().generateData(count: 16).base64EncodedString()
        // init a new `UserToken` from that string.
        return .init(string: string, userID: userID)
    }

    static var deletedAtKey: TimestampKey? { return \.expiresAt }

    var id: Int?

    var tokenString: String

    var userID: User.ID
    
    /// Expiration date. Token will no longer be valid after this point.
    var expiresAt: Date?
    
    /// Creates a new `UserToken`.
    init(id: Int? = nil, string: String, userID: User.ID) {
        self.id = id
        self.tokenString = string
        // set token to expire after 5 hours
        self.expiresAt = Date.init(timeInterval: 60 * 60 * 5, since: .init())
        self.userID = userID
    }
}

extension UserToken {
    /// Fluent relation to the user that owns this token.
    var user: Parent<UserToken, User> {
        return parent(\.userID)
    }
}

/// Allows this model to be used as a TokenAuthenticatable's token.
extension UserToken: Token {
    /// See `Token`.
    typealias UserType = User
    
    /// See `Token`.
    static var tokenKey: WritableKeyPath<UserToken, String> {
        return \.tokenString
    }
    
    /// See `Token`.
    static var userIDKey: WritableKeyPath<UserToken, User.ID> {
        return \.userID
    }
}

/// Allows `UserToken` to be used as a Fluent migration.
extension UserToken: Migration {
    /// See `Migration`.
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(UserToken.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.tokenString)
            builder.field(for: \.userID)
            builder.field(for: \.expiresAt)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

/// Allows `UserToken` to be encoded to and decoded from HTTP messages.
extension UserToken: Content { }

/// Allows `UserToken` to be used as a dynamic parameter in route definitions.
extension UserToken: Parameter { }

