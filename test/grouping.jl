module TestGrouping
    using Base.Test
    using DataFrames

    df = DataFrame(a = repeat([1, 2, 3, 4], outer=[2]),
                   b = repeat([2, 1], outer=[4]),
                   c = randn(8))
    #df[6, :a] = NA
    #df[7, :b] = NA

    cols = [:a, :b]

    f(df) = DataFrame(cmax = maximum(df[:c]))

    sdf = unique(df[cols])

    # by() without groups sorting
    bdf = by(df, cols, f)
    @test bdf[cols] == sdf

    # by() with groups sorting
    sbdf = by(df, cols, f, sort=true)
    @test sbdf[cols] == sort(sdf)

    byf = by(df, :a, df -> DataFrame(bsum = sum(df[:b])))

    @test all(T -> T <: AbstractArray, map(typeof, colwise([sum], df)))
    @test all(T -> T <: AbstractArray, map(typeof, colwise(sum, df)))

    # groupby() without groups sorting
    gd = groupby(df, cols)
    ga = map(f, gd)
    @test bdf == combine(ga)

    # groupby() with groups sorting
    gd = groupby(df, cols, sort=true)
    ga = map(f, gd)
    @test sbdf == combine(ga)

    g(df) = DataFrame(cmax1 = df[:cmax] + 1)
    h(df) = g(f(df))

    @test combine(map(h, gd)) == combine(map(g, ga))

    # testing pool overflow
    df2 = DataFrame(v1 = pool(collect(1:1000)), v2 = pool(fill(1, 1000)))
    @test groupby(df2, [:v1, :v2]).starts == collect(1:1000)
    @test groupby(df2, [:v2, :v1]).starts == collect(1:1000)

    # grouping empty frame
    @test groupby(DataFrame(A=Int[]), :A).starts == Int[]
    # grouping single row
    @test groupby(DataFrame(A=Int[1]), :A).starts == Int[1]

    # issue #960
    x = pool(collect(1:20))
    df = DataFrame(v1=x, v2=x)
    groupby(df, [:v1, :v2])

    a = DataFrame(x=pool(1:200))
    b = DataFrame(x=pool(100:300))
    vcat(a,b)

    df2 = by(e->1, DataFrame(x=Int64[]), :x)
    @test size(df2) == (0,1)
    @test sum(df2[:x]) == 0
end
