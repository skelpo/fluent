import Vapor

public final class FluentProvider: Provider {
    public init() { }
    
    public func register(_ app: Application) {
        app.register(MigrateCommand.self) { c in
            return .init(migrator: c.make())
        }
        
        app.register(Migrator.self) { app in
            return .init(
                databases: app.make(),
                migrations: app.make(),
                logger: app.make(),
                on: app.make()
            )
        }
        
        app.register(DatabaseSessions.self) { app in
            return .init(database: app.make())
        }
        
        app.register(singleton: Databases.self, boot: { app in
            return Databases(threadPool: app.make(), on: app.make())
        }, shutdown: { databases in
            databases.shutdown()
        })
        
        app.register(ConnectionPoolConfiguration.self) { app in
            return .init()
        }
        
        app.register(extension: CommandConfiguration.self) { commands, c in
            commands.use(c.make(MigrateCommand.self), as: "migrate")
        }
    }

    public func willBoot(_ app: Application) throws {
        struct Signature: CommandSignature {
            @Flag(name: "auto-migrate", help: "If true, Fluent will automatically migrate your database on boot")
            var autoMigrate: Bool

            @Flag(name: "auto-revert", help: "If true, Fluent will automatically revert your database on boot")
            var autoRevert: Bool

            init() { }
        }

        let signature = try Signature(from: &app.environment.commandInput)
        if signature.autoRevert {
            let migrator = app.make(Migrator.self)
            try migrator.setupIfNeeded().wait()
            try migrator.revertAllBatches().wait()
        }

        if signature.autoMigrate {
            let migrator = app.make(Migrator.self)
            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()
        }
    }
}

extension Application {
    public var databases: Databases {
        return self.make()
    }
}

extension Request {
    public var db: Database {
        return self.application.make(Database.self).with(self)
    }
    
    public func db(_ id: DatabaseID) -> Database {
        return self.application.make(Databases.self)
            .database(id, logger: self.logger, on: self.eventLoop)!
            .with(self)
    }
}

extension Database {
    public func with(_ request: Request) -> Database {
        return RequestSpecificDatabase(request: request, database: self, context: self.context)
    }
}

private struct RequestSpecificDatabase: Database {
    let request: Request
    let database: Database
    let context: DatabaseContext
    
    var logger: Logger {
        return self.request.logger
    }

    func execute(query: DatabaseQuery, onRow row: @escaping (DatabaseRow) -> ()) -> EventLoopFuture<Void> {
        self.database.execute(query: query, onRow: row)
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        self.database.execute(schema: schema)
    }

    func withConnection<T>(_ closure: @escaping (Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        self.database.withConnection(closure)
    }
}
