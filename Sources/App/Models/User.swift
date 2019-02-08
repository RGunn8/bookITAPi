import Authentication
import FluentPostgreSQL
import Vapor

/// A registered user, capable of owning todo items.
final class User: PostgreSQLModel {
    var id: Int?
    var name: String
    var email: String
    var favBook:String?
    var passwordHash: String
    init(id: Int? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User: TokenAuthenticatable {
//    static func authenticate(token: UserToken, on connection: DatabaseConnectable) -> EventLoopFuture<User?> {
//        
//    }

    /// See `TokenAuthenticatable`.
    typealias TokenType = UserToken
}

/// Allows `User` to be used as a Fluent migration.
extension User: Migration {
    /// See `Migration`.
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return PostgreSQLDatabase.create(User.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.name)
            builder.field(for: \.email)
            builder.field(for: \.passwordHash)
            builder.unique(on: \.email)
        }
    }
}

extension User: Content { }

extension User: Parameter { }

extension User {
    var goals: Children<User, Goal>{
        return children(\.userID)
    }
}

struct CreateUserRequest: Content {
    var name: String
    var email: String
    var password: String
    var verifyPassword: String
    var favBook:String?
}

struct CreateUserResponse:Content,ResponseProtocol{
    var success: Bool
    var error:String?
    let createUser:CreateUser?
}
struct CreateUser:Content{
    var id:Int
    var name:String
    var email:String
    var favBook:String?
    var token:String
}

struct LoginUser: Content {
    var email:String
    var password:String
}

struct UserResponse: Content {
    var id: Int
    var name: String
    var email: String
    var favBook:String?
}

protocol ResponseProtocol:Codable{
    var success:Bool{get}
    var error:String? {get}
}

