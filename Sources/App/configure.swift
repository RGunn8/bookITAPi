import Authentication
import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(SessionsMiddleware.self) // Enables sessions.
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    let databaseConfig:PostgreSQLDatabaseConfig
    let localConfig =  PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "ryanlgunn8", database: "bookit", password: nil, transport: .cleartext)
    if let url = Environment.get("DATABASE_URL"){
        let serverConfig = PostgreSQLDatabaseConfig(url: url)
        if let serverConfig = serverConfig{
            databaseConfig = serverConfig
        }else{
            databaseConfig = localConfig
        }
    }else{
        databaseConfig =  localConfig
    }
    let postgre =  PostgreSQLDatabase(config: databaseConfig)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.enableLogging(on: .psql)
    databases.add(database: postgre, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: UserToken.self, database: .psql)
    migrations.add(model: Todo.self, database: .psql)
    migrations.add(model: Goal.self, database: .psql)
    services.register(migrations)

}
