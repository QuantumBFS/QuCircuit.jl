using Compat
using Compat.Test
using Compat.LinearAlgebra
using Compat.SparseArrays

using Yao
using Yao.CacheServers
using Yao.Blocks

# @testset "primitive" begin
# g = cache(phase(0.1))
# update_cache(g)

# empty!(:all) # empty all
# @test_throws KeyError pull(g)
# update_cache(g)
# @test_throws KeyError pull(g)

# g = cache(phase(0.1))
# update_cache(g)
# empty!(g)
# @test_throws KeyError pull(g)

# g = cache(phase(0.1), 3)
# update_cache(g)
# empty!(g, 1)
# @test pull(g) == mat(g)
# empty!(g, 4)
# @test_throws KeyError pull(g)

# end

@testset "composite" begin
    # g = cache(chain(phase(0.1), phase(0.2)))
    # update_cache(g)

    # empty!(g)
    # @test_throws KeyError pull(g)

    @testset "recursive" begin
        g = cache(chain(phase(0.1), phase(0.2)), recursive=true)
        update_cache(g)
        empty!(g)
        # @test_throws KeyError pull(g)
        # @test pull(g[1]) ≈ mat(phase(0.1))

        update_cache(g)
        # @test pull(g) ≈ mat(g.block)

        empty!(g, recursive=true)
        @test_throws KeyError pull(g)
        @test_throws KeyError pull(g[1])
        @test_throws KeyError pull(g[2])
    end

# g = cache(chain(phase(0.1), phase(0.2)), 4, recursive=true)
# update_cache(g)
# empty!(g, 2)
# @test pull(g) ≈ mat(g)

# empty!(g, 5)
# @test_throws KeyError pull(g)
# @test pull(g[1]) ≈ mat(phase(0.1))

# update_cache(g)
# empty!(g, 2, recursive=true)
# @test pull(g) ≈ mat(g)
# @test pull(g[1]) ≈ mat(g[1])
# @test pull(g[2]) ≈ mat(g[2])

# empty!(g, 5, recursive=true)
# @test_throws KeyError pull(g)
# @test_throws KeyError pull(g[1])
# @test_throws KeyError pull(g[2])

end
