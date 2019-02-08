import Vapor

/// Creates an instance of Application. This is called from main.swift in the run target.
public func app(_ env: Environment) throws -> Application {
    var config = Config.default()
    var env = env
    var services = Services.default()
    var contentConfig = ContentConfig.default()

    /// Create custom JSON encoder
    let jsonEncoder = JSONEncoder()
    jsonEncoder.dateEncodingStrategy = .millisecondsSince1970
    

    /// Register JSON encoder and content config
    contentConfig.use(encoder: jsonEncoder, for: .json)
    services.register(contentConfig)
    try configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try boot(app)
    return app
}
