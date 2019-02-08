import Crypto
import Vapor
import FluentSQLite

/// Creates new users and logs them in.
final class UserController {
    /// Logs a user in, returning a token for accessing protected endpoints.
    func login(_ req: Request) throws -> Future<CreateUserResponse> {
        // get user auth'd by basic auth middleware
        var loginUserPasword = ""
        return try req.content.decode(LoginUser.self).flatMap(to: User?.self) {user  in
            loginUserPasword = user.password
               return  User.query(on: req).filter(\.email == user.email).first()
            }.flatMap(to:CreateUserResponse.self){ queryUser in
                if let queryUser = queryUser{
                    if try BCrypt.verify(loginUserPasword, created: queryUser.passwordHash){
                        let token = try UserToken.create(userID: queryUser.requireID())
                        return  token.save(on: req).map(to: CreateUserResponse.self) { token  in
                            return try CreateUserResponse(success: true, error: nil, createUser:  CreateUser(id: queryUser.requireID(), name: queryUser.name, email: queryUser.email, favBook:queryUser.favBook, token: token.tokenString))

                        }
                    }
                }
                 return req.future(CreateUserResponse(success: false, error: "Invaild Password or email try again", createUser: nil))
        }

    }
    
    /// Creates a new user.
    func create(_ req: Request) throws -> Future<CreateUserResponse> {
        // decode request content
        return try req.content.decode(CreateUserRequest.self).flatMap { user -> Future<CreateUserResponse> in
            // verify that passwords match
            guard user.password == user.verifyPassword else {
                   return req.future(CreateUserResponse(success: false, error: "Password and verification must match.", createUser: nil))
            }

            let hash = try BCrypt.hash(user.password)
            return User(id: nil, name: user.name, email: user.email, passwordHash: hash).save(on: req)
                .flatMap(to:CreateUserResponse.self){ user in
                    let token = try UserToken.create(userID: user.requireID())
                    return  token.save(on: req).map(to: CreateUserResponse.self) { token  in
                        return try CreateUserResponse(success: true, error: nil, createUser:  CreateUser(id: user.requireID(), name: user.name, email: user.email, favBook:user.favBook, token: token.tokenString))

                    }
            }
        }
    }
}


