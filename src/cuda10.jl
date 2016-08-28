using CUDArt
importall Base

cuda10 = [
# ("add",".+","s+xi"),
# ("sub",".-","s-xi"),
# ("mul",".*","s*xi"),
# ("div","./","s/xi"),
("pow",".^","pow(xi,s)"),
# "hypot",
# "rhypot",
# "atan2",
# "frexp",
# "ldexp",
# "scalbn",
# "scalbln",
# "jn",
# "yn",
# "fmod",
# "remainder",
# "mod",
# "fdim",
]

(.^){T}(a::KnetArray{T},s::Number)=(.^)(a,T(s))

function cuda10def(f, j=f, o...)
    libknet8 = Pkg.dir("Knet/cuda/libknet8")
    J=Symbol(j)
    for S in (32,64)
        T = Symbol("Float$S")
        F = "$(f)_$(S)_10"
        @eval begin
            function $J(x::KnetArray{$T},s::$T)
                y = tmplike(x)
                ccall(($F,$libknet8),Void,(Cint,Ptr{$T},$T,Ptr{$T}),length(y),x,s,y)
                return y
            end
        end
    end
end
    
for f in cuda10
    isa(f,Tuple) || (f=(f,))
    cuda10def(f...)
end