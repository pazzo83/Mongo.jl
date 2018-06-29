mutable struct MongoClient
    uri::String
    _wrap_::Ptr{Nothing}

    MongoClient(uri::AbstractString) = begin
        uriCStr = string(uri)
        client = new(
            uri,
            ccall(
                (:mongoc_client_new, libmongoc),
                Ptr{Nothing}, (Ptr{UInt8}, ),
                uriCStr
                )
            )
        finalizer(destroy, client)
        return client
    end

MongoClient(host::AbstractString, port::Int) = MongoClient("mongodb://$host:$port/")
MongoClient(host::AbstractString, port::Int, user::AbstractString, password::AbstractString) = MongoClient("mongodb://$user:$password@$host:$port/")
MongoClient(host::AbstractString, user::AbstractString, password::AbstractString) = MongoClient("mongodb://$user:$password@$host/")
MongoClient(host::AbstractString, user::AbstractString, password::AbstractString, db::AbstractString) = MongoClient("mongodb://$user:$password@$host/$db")
    MongoClient() = MongoClient("localhost", 27017)
end
export MongoClient

show(io::IO, client::MongoClient) = print(io, "MongoClient($(client.uri))")
export show

"""
Issues a command to MongoDB client through `mongoc_client_command_simple`.

Possible commands: https://docs.mongodb.org/manual/reference/command/
"""
command_simple(
    client::MongoClient, # mongoc_client_t
    db_name::AbstractString, # const char
    command::BSONObject#, # const bson_t
    ) = begin
    dbCStr = String(db_name)
    reply = BSONObject() # bson_t
    bsonError = BSONError() # bson_error_t
    ccall(
        (:mongoc_client_command_simple, libmongoc),
        Bool, (Ptr{Nothing}, Ptr{UInt8}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}, Ptr{UInt8}),
        client._wrap_,
        dbCStr,
        command._wrap_,
        C_NULL,
        reply._wrap_,
        bsonError._wrap_
        ) || error("update: $(string(bsonError))")
    return reply
end
command_simple(
    client::MongoClient,
    db_name::AbstractString,
    command::AbstractDict
    ) = command_simple(
        client,
        db_name,
        BSONObject(command)
        )
command_simple(
    client::MongoClient,
    db_name::AbstractString,
    command::NakedDict
    ) = command_simple(
        client,
        db_name,
        BSONObject(command)
        )
export command_simple

# Private

destroy(client::MongoClient) =
    ccall(
        (:mongoc_client_destroy, libmongoc),
        Nothing, (Ptr{Nothing},),
        client._wrap_
        )
