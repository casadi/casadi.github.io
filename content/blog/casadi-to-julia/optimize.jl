# A minimal source-to-source pass over the Expr that Umlaut.compile would eval.
# Two jobs: (1) turn ONNX.jl's value-domain ops into native Julia operations,
#           (2) re-assemble the flat SSA tape into expression trees, so broadcasts fuse.
using ONNX, Umlaut

# Umlaut embeds the actual function *objects* in the Expr, so match on identity.
const BINOP = Dict(ONNX.add => :.+, ONNX.sub => :.-, ONNX.mul => :.*)
const UNOP  = Dict(ONNX._sin => :sin, ONNX._cos => :cos, ONNX._abs => :abs)

isliteral(x) = !(x isa Symbol) && !(x isa Expr)

function rewrite(ex)
    ex isa Expr && ex.head === :call || return ex
    fn, args = ex.args[1], ex.args[2:end]
    if haskey(UNOP, fn)
        return :($(UNOP[fn]).($(args[1])))
    elseif haskey(BINOP, fn)
        return foldl((a, b) -> Expr(:call, BINOP[fn], a, b), args)
    elseif fn === ONNX.onnx_slice && all(isliteral, args[2:end])
        data, starts, ends, axes, steps = args
        ranges = [s+1 : st : e for (s, st, e) in zip(starts, steps, ends)]
        d2r = Dict(zip(length(ranges) .- axes, ranges))   # ONNX axes: reversed and 0-based
        return Expr(:ref, data, [get(d2r, i, :(:)) for i in 1:length(ranges)]...)
    end
    return ex
end

subst(ex, d) = ex isa Symbol ? get(d, ex, ex) :
               ex isa Expr   ? Expr(ex.head, [subst(a, d) for a in ex.args]...) : ex

countsym!(c, ex) = ex isa Symbol ? (c[ex] = get(c, ex, 0) + 1) :
                   ex isa Expr   ? foreach(a -> countsym!(c, a), ex.args) : nothing

"""
    optimize(fn_ex::Expr)

Rewrite the function expression produced by `Umlaut.to_expr`. Valid because the tape is
SSA and the ops involved are pure: a definition used at most once can be substituted
into its single use site, which is what lets Julia fuse the broadcasts.
"""
function optimize(fn_ex::Expr)
    header, body = fn_ex.args[1], fn_ex.args[2]
    stmts = filter(a -> a isa Expr, body.args)
    uses = Dict{Symbol,Int}()
    for s in stmts, a in (s.head === :(=) ? s.args[2:end] : s.args)
        countsym!(uses, a)
    end
    out, d = Any[], Dict{Symbol,Any}()
    for s in stmts
        if s.head === :return
            push!(out, Expr(:return, subst(s.args[1], d)))
        else
            name, rhs = s.args[1], rewrite(subst(s.args[2], d))
            get(uses, name, 0) <= 1 || isliteral(rhs) ? (d[name] = rhs) :
                                                        push!(out, Expr(:(=), name, rhs))
        end
    end
    return Expr(:function, header, Expr(:block, out...))
end
