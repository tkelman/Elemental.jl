type DistMatrix{T} <: ElementalMatrix{T}
	obj::Ptr{Void}
end

for (elty, ext) in ((:ElInt, :i),
                    (:Float32, :s),
                    (:Float64, :d),
                    (:Complex64, :c),
                    (:Complex128, :z))
    @eval begin
        function DistMatrix(::Type{$elty}, colDist = MC, rowDist = MR, grid = Grid())
            obj = Ref{Ptr{Void}}(C_NULL)
            err = ccall(($(string("ElDistMatrixCreateSpecific_", ext)), libEl), Cuint,
                (Cint, Cint, Ptr{Void}, Ref{Ptr{Void}}),
                colDist, rowDist, grid.obj, obj)
            err == 0 || throw(ElError(err))
            return DistMatrix{$elty}(obj[])
        end

        function Grid(A::DistMatrix{$elty})
            g = Grid()
            err = ccall(($(string("ElDistMatrixGrid_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{Ptr{Void}}),
                A.obj, Ref{Ptr{Void}}(g.obj))
            err == 0 || throw(ElError(err))
            return g
        end

        function comm(A::DistMatrix{$elty})
            cm = Ref{ElComm}()
            err = ccall(($(string("ElDistMatrixDistComm_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElComm}),
                A.obj, cm)
            err == 0 || throw(ElError(err))
            return cm[]
        end

        function get(A::DistMatrix{$elty}, i::Integer, j::Integer)
            rv = Ref{$elty}(0)
            err = ccall(($(string("ElDistMatrixGet_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function getLocal(A::DistMatrix{$elty}, i::Integer, j::Integer)
            rv = Ref{$elty}(0)
            err = ccall(($(string("ElDistMatrixGetLocal_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt, Ref{$elty}),
                A.obj, i - 1, j - 1, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function globalCol(A::DistMatrix{$elty}, i::Integer)
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixGlobalCol_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, i - 1, rv)
            err == 0 || throw(ElError(err))
            return rv[] + 1
        end

        function globalRow(A::DistMatrix{$elty}, i::Integer)
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixGlobalRow_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, Ref{ElInt}),
                A.obj, i - 1, rv)
            err == 0 || throw(ElError(err))
            return rv[] + 1
        end

        function height(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function localHeight(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixLocalHeight_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function localWidth(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixLocalWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function processPullQueue(A::DistMatrix{$elty}, buf::Array{$elty,2})
            err = ccall(($(string("ElDistMatrixProcessPullQueue_", ext)), libEl), Cuint,
                (Ptr{Void}, Ptr{$elty}),
                A.obj, buf)
            err == 0 || throw(ElError(err))
            return buf
        end

        function processQueues(A::DistMatrix{$elty})
            err = ccall(($(string("ElDistMatrixProcessQueues_", ext)), libEl), Cuint,
                (Ptr{Void},), A.obj)
            err == 0 || throw(ElError(err))
            return A
        end

        function queuePull(A::DistMatrix{$elty}, i::Integer, j::Integer)
            err = ccall(($(string("ElDistMatrixQueuePull_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, i - 1, j - 1)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function queueUpdate(A::DistMatrix{$elty}, i::Integer, j::Integer, value::$elty)
            err = ccall(($(string("ElDistMatrixQueueUpdate_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt, ElInt, $elty),
              A.obj, i - 1, j - 1, value)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function reserve(A::DistMatrix{$elty}, numEntries::Integer)
            err = ccall(($(string("ElDistMatrixReserve_", ext)), libEl), Cuint,
              (Ptr{Void}, ElInt),
              A.obj, numEntries)
            err == 0 || throw(ElError(err))
            return nothing
        end

        function width(A::DistMatrix{$elty})
            rv = Ref{ElInt}(0)
            err = ccall(($(string("ElDistMatrixWidth_", ext)), libEl), Cuint,
                (Ptr{Void}, Ref{ElInt}),
                A.obj, rv)
            err == 0 || throw(ElError(err))
            return rv[]
        end

        function resize!(A::DistMatrix{$elty}, i::Integer, j::Integer = 1) # to mimic vector behavior
            err = ccall(($(string("ElDistMatrixResize_", ext)), libEl), Cuint,
                (Ptr{Void}, ElInt, ElInt),
                A.obj, i, j)
            err == 0 || throw(ElError(err))
            return A
        end
    end
end

DistMatrix() = DistMatrix(Float64)

#########################
### Julia convenience ###
#########################
countnz(A::DistMatrix) = length(A)

# Do I want to provide this function? It's an invitation to be slow
getindex(A::DistMatrix, i::Integer, j::Integer) = get(A, i, j)

# This might be wrong. Should consider how to extract distributions properties of A
function similar{T}(::DistMatrix, ::Type{T}, sz::Dims)
    A = DistMatrix(T)
    resize!(A, sz...)
    return A
end

function getindex(A::DistMatrix, iInd::Colon, jInd::UnitRange)
    B = DistMatrix(eltype(A))
    zeros!(B, size(A, 1), length(jInd))
    for j = jInd
        for i = 1:size(A, 1)
            queueUpdate(B, i, j, A[i,j])
        end
    end
    processQueues(B)
    return B
end

# FixMe! Should this one handle vectors of matrices?
function hcat{T}(x::Vector{DistMatrix{T}})
    l    = length(x)
    if l == 0
        throw(ArgumentError("cannot flatten empty vector"))
    else
        x1   = x[1]
        m, n = size(x1, 1), size(x1, 2)
        if n != 1
            throw(ArgumentError("elements has to be vectors, i.e. the second dimension has to have size one"))
        end
        A    = DistMatrix(T)
        zeros!(A, m, l*n)
        for j = 1:l
            xj = x[j]
            for k = 1:localWidth(xj)
                for i = 1:localHeight(xj)
                    xji = getLocal(xj, i, 1)
                    queueUpdate(A, globalRow(xj, i), j, xji)
                end
            end
        end
        processQueues(A)
        return A
    end
end
