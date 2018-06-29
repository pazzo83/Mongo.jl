mutable struct MongoCursor
    _wrap_::Ptr{Nothing}

    MongoCursor(_wrap_::Ptr{Nothing}) = begin
        cursor = new(_wrap_)
        finalizer(destroy, cursor)
        return cursor
    end
end
export MongoCursor

# Iterator

start(cursor::MongoCursor) = nothing
export start

next(cursor::MongoCursor, state::Nothing) =
    (BSONObject(ccall(
        (:mongoc_cursor_current, libmongoc),
        Ptr{Nothing}, (Ptr{Nothing},),
        cursor._wrap_
        ), Union{}), state)
export next

done(cursor::MongoCursor, state::Nothing) = begin
    return !ccall(
        (:mongoc_cursor_next, libmongoc),
        Bool, (Ptr{Nothing}, Ptr{Ptr{Nothing}}),
        cursor._wrap_,
        Array{Ptr{Nothing}}(1)
        )
end
export done

Base.iteratorsize(::Type{MongoCursor}) = Base.SizeUnknown()
Base.eltype(::Type{MongoCursor}) = BSONObject

destroy(collection::MongoCursor) =
    ccall(
        (:mongoc_cursor_destroy, libmongoc),
        Nothing, (Ptr{Nothing},),
        collection._wrap_
        )
