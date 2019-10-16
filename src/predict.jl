# prediction from single tree - assign each observation to its final leaf
function predict!(pred, tree::Tree, X::AbstractArray{T, 2}) where {T<:Real}
    @inbounds @threads for i in 1:size(X, 1)
        id = 1
        x = view(X, i, :)
        while tree.nodes[id].split
            if x[tree.nodes[id].feat] < tree.nodes[id].cond
                id = tree.nodes[id].left
            else
                id = tree.nodes[id].right
            end
        end
        pred[i] += tree.nodes[id].pred
    end
    return pred
end

# prediction from single tree - assign each observation to its final leaf
function predict(tree::Tree, X::AbstractArray{T, 2}, K) where T<:Real
    pred = zeros(SVector{K,T}, size(X, 1))
    predict!(pred, tree, X)
    return pred
end

# prediction from single tree - assign each observation to its final leaf
function predict(model::GBTree, X::AbstractArray{T, 2}) where T<:Real
    pred = zeros(SVector{model.params.K,T}, size(X, 1))
    for tree in model.trees
        predict!(pred, tree, X)
    end
    pred = reinterpret(T, pred)
    if typeof(model.params.loss) == Logistic
        @. pred = sigmoid(pred)
    elseif typeof(model.params.loss) == Poisson
        @. pred = exp(pred)
    elseif typeof(model.params.loss) == Gaussian
        pred = transpose(reshape(pred, model.params.K, :))
        pred[:,2] = exp.(pred[:,2])
    elseif typeof(model.params.loss) == Softmax
        pred = transpose(reshape(pred, model.params.K, :))
        for row in eachrow(pred)
            row .= softmax(row)
        end
    end
    return pred
end


# prediction in Leaf - GradientRegression
function pred_leaf(loss::S, node::TrainNode{L,T}, params::EvoTreeRegressor, δ²) where {S<:GradientRegression,L,T}
    - params.η .* node.∑δ ./ (node.∑δ² .+ params.λ .* node.∑𝑤)
end

# prediction in Leaf - MultiClassRegression
function pred_leaf(loss::S, node::TrainNode{L,T}, params::EvoTreeRegressor, δ²) where {S<:MultiClassRegression,L,T}
    - params.η * node.∑δ ./ (node.∑δ² + params.λ * node.∑𝑤[1])
end

# prediction in Leaf - L1Regression
function pred_leaf(loss::S, node::TrainNode{L,T}, params::EvoTreeRegressor, δ²) where {S<:L1Regression,L,T}
    params.η .* node.∑δ ./ (node.∑𝑤 .* (1 .+ params.λ))
end

# prediction in Leaf - QuantileRegression
function pred_leaf(loss::S, node::TrainNode{L,T}, params::EvoTreeRegressor, δ²) where {S<:QuantileRegression,L,T}
    SVector{1,Float64}(params.η * quantile(reinterpret(Float64, δ²[collect(node.𝑖)]), params.α) / (1 + params.λ))
    # pred = params.η * quantile(δ²[collect(node.𝑖)], params.α) / (1 + params.λ)
end

# prediction in Leaf - GaussianRegression
function pred_leaf(loss::S, node::TrainNode{L,T}, params::EvoTreeRegressor, δ²) where {S<:GaussianRegression,L,T}
    - params.η * node.∑δ ./ (node.∑δ² + params.λ * node.∑𝑤[1])
end
