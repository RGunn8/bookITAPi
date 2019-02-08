import Vapor
import FluentPostgreSQL

/// Simple todo-list controller.
final class TodoController {
    /// Returns a list of all todos for the auth'd user.
    func index(_ req: Request) throws -> Future<TodoResponse> {
        // fetch auth'd user
        let user = try req.requireAuthenticated(User.self)

        // query all todo's belonging to user
        return try Todo.query(on: req)
            .filter(\.userID == user.requireID()).all().map(to:TodoResponse.self){todos in
                return  TodoResponse(success: true, error: nil, todos: todos)
        }
    }

    /// Creates a new todo for the auth'd user.
    func create(_ req: Request) throws -> Future<Todo> {
        // fetch auth'd user
        let user = try req.requireAuthenticated(User.self)
        
        // decode request content
        return try req.content.decode(CreateTodoRequest.self).flatMap { todo in
            // save new todo
            return try Todo(title: todo.title, userID: user.requireID())
                .save(on: req)
        }
    }

    /// Deletes an existing todo for the auth'd user.
    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        // fetch auth'd user
        let user = try req.requireAuthenticated(User.self)
        
        // decode request parameter (todos/:id)
        return try req.parameters.next(Todo.self).flatMap { todo -> Future<Void> in
            // ensure the todo being deleted belongs to this user
            guard try todo.userID == user.requireID() else {
                throw Abort(.forbidden)
            }
            
            // delete model
            return todo.delete(on: req)
        }.transform(to: .ok)
    }
}

// MARK: Content

/// Represents data required to create a new todo.
struct CreateTodoRequest: Content {
    /// Todo title.
    var title: String
}

struct TodoResponse:Content,ResponseProtocol{
    var success: Bool
    var error:String?
    let todos:[Todo]?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(success, forKey: .success)
        try container.encode(error, forKey: .error)
        try container.encode(todos, forKey: .todos)
    }
}
