module EvoTrees

export grow_tree!, grow_gbtree, Tree, Node, Params, predict, EvoTreeRegressor, EvoTreeRegressorR

using DataFrames
using Statistics
using CSV
using Base.Threads: @threads
using StatsBase: sample, quantile
import MLJ
import MLJBase

include("struct.jl")
include("loss.jl")
include("eval.jl")
include("predict.jl")
include("tree_vector.jl")
include("histogram.jl")
include("MLJ.jl")

end # module