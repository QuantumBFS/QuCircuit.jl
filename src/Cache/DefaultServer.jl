struct DefaultServer{TM} <: AbstractCacheServer
    storage::Dict{UInt, CacheElement{TM}}
end

DefaultServer(::Type{TM}) where TM = DefaultServer(Dict{UInt, CacheElement{TM}}())

########################
# Direct Access Methods
########################

function iscacheable(server::DefaultServer, k::UInt, level::UInt)
    k in keys(server.storage) || return false
    iscacheable(server.storage[k], level)
end

function iscacheable(server::DefaultServer, k::UInt)
    k in keys(server.storage)
end

function iscached(server::DefaultServer, block::MatrixBlock)
    k = object_id(block)
    k in keys(server.storage) || return false
    iscached(server.storage[k], block)
end

function setlevel!(server::DefaultServer{TM}, k::UInt, level::UInt) where TM
    if !(k in keys(server.storage))
        setlevel!(server.storage[k], level)
    end
    server
end

"""
    cache!(server, key, level) -> server

add a new cacheable block with cache level `level`
by upload its `key` to the server.
"""
function cache!(server::DefaultServer{TM}, key::UInt, level::UInt) where TM
    if !(key in keys(server.storage))
        server.storage[key] = CacheElement(TM, level)
    end
    server
end

"""
    push!(server, key, pkey, val[, level]) -> server

push (block, level) in hash key form to the server. update original
cache with `val`. if input level is greater than stored level (input > stored).
"""
function push!(server::DefaultServer{TM}, key::UInt, pkey::MatrixBlock, val::TM, level::UInt) where TM
    if key in keys(server.storage)
        push!(server.storage[key], pkey, val, level)
    end
    server
end

# force push
function push!(server::DefaultServer{TM}, key::UInt, pkey::MatrixBlock, val::TM) where TM
    if key in keys(server.storage)
        push!(server.storage[key], pkey, val)
    end
    server
end

"""
    pull(server, key, pkey) -> valtype

get block's cache by (key, pkey)
"""
@inline function pull(server::DefaultServer, key::UInt, pkey::MatrixBlock)
    pull(server.storage[key], pkey)
end

"""
    empty!(server, key)

empty key's cache.
"""
function empty!(server::DefaultServer, key::UInt)
    empty!(server.storage[key])
end

##########################
# Wrap to call object_id
##########################

"""
    iscaheable(server, block, level) -> Bool

whether this block is cacheable with current cache level.
"""
@inline function iscacheable(server::DefaultServer, block::MatrixBlock, level::UInt)
    iscacheable(server, object_id(block), level)
end

@inline function iscacheable(server::DefaultServer, block::MatrixBlock)
    iscacheable(server, object_id(block))
end

"""
    setlevel!(server, block, level)

set block's cache level
"""
@inline function setlevel!(server::DefaultServer, block::MatrixBlock, level::UInt)
    setlevel!(server, object_id(block), level)
end

"""
    cache!(server, block, level) -> server

add a new cacheable block with cache level `level` to the server.
"""
@inline function cache!(server::DefaultServer{TM}, block::MatrixBlock, level::UInt) where TM
    cache!(server, object_id(block), level)
end

"""
    push!(server, block, val, level) -> server

push `val` to cache server, it will be cached if `level` is greater
than stored level. Or it will do nothing.
"""
@inline function push!(server::DefaultServer{TM}, block::MatrixBlock, val::TM, level::UInt) where TM
    push!(server, object_id(block), block, val, level)
end

# force push
@inline function push!(server::DefaultServer{TM}, block::MatrixBlock, val::TM) where TM
    push!(server, object_id(block), block, val)
end

"""
    pull(server, block)

pull current block's cache from server
"""
@inline function pull(server::DefaultServer, block::MatrixBlock)
    pull(server, object_id(block), block)
end

@inline function empty!(server::DefaultServer, block::MatrixBlock)
    empty!(server, object_id(block))
end

function empty!(server::DefaultServer)
    empty!(server.storage)
end

function show(io::IO, c::DefaultServer{TM}) where TM
    println(io, "Default Server {$TM}")
    print(io, "entries: ", length(values(c.storage)))
end
