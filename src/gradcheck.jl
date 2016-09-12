function gradcheck(f, w, x...; gcheck=10, o...)
    g = grad(f)
    d = g(w, x...; o...)
    if isa(w, Number)
        gc_number(d, f, w, x...; o...)
    elseif isa(w, KnetArray) || (isa(w, Array) && isbits(eltype(w)))
        gc_array(w, d, f, w, x...; gcheck=gcheck, o...)
    else
        k = indices(w)
        for i in k
            gc_index(w, d, i, f, w, x...; gcheck=gcheck, o...)
        end
    end
end

function gc_index(w, d, i, f, w0, x...; gcheck=10, o...)
    if isa(w[i], Number)
        gc_array(w, d, f, w0, x...; gcheck=1, icheck=i, o...)
    elseif isa(w[i],KnetArray) || (isa(w[i], Array) && isbits(eltype(w[i])))
        gc_array(w[i], d[i], f, w0, x...; gcheck=gcheck, o...)
    else
        k = indices(w[i])
        for j in k
            gc_index(w[i], d[i], j, f, w0, x...; gcheck=gcheck, o...)
        end
    end
end

function gc_array(w, d, f, worig, x...; gcheck=10, icheck=0, o...)
    irange = (icheck > 0 ? (icheck:icheck) :
              length(w) <= gcheck ? (1:length(w)) :
              sortperm(abs(vec(Array(d))),rev=true)[1:gcheck])
    (delta, atol, rtol) = gc_params(typeof(w[first(irange)]))
    for i in irange
        w0 = w[i]
        (w1, w2) = gc_interval(w0, delta)
        w[i] = w1
        f1 = f(worig, x...; o...)
        w[i] = w2
        f2 = f(worig, x...; o...)
        w[i] = w0
        nd = (f2-f1) / (w2-w1)
        if !isapprox(d[i], nd; rtol=rtol, atol=atol)
            warn("gc: d=$(d[i]) nd=$nd")
        else
            info("gc: d=$(d[i]) nd=$nd")
        end
    end
end

function gc_number(d, f, w, x...; o...)
    (delta, atol, rtol) = gc_params(typeof(w))
    (w1, w2) = gc_interval(w, delta)
    (f1, f2) = (f(w1,x...;o...), f(w2,x...;o...))
    nd = (f2-f1) / (w2-w1)
    if !isapprox(d, nd; rtol=rtol, atol=atol)
        warn("gc: d=$d nd=$nd")
    else
        info("gc: d=$d nd=$nd")
    end
end

gc_params(t)=(a=cbrt(eps(t)); (a,a,a))
indices(w)=eachindex(w)
indices(w::Tuple)=(1:length(w))

function gc_interval(w,d)
    w1=w-d/2
    w2=w+d/2
    sign(w1)==sign(w)||(w1=zero(w))
    sign(w2)==sign(w)||(w2=zero(w))
    return (w1,w2)
end
