module DWL

const xkb_keysym_t = UInt32
#struct xkb_keysym_t
#    x::UInt32
#end

struct Arg
    x::UInt
end

struct Key
    mod::UInt32
    keysym::xkb_keysym_t
    func::Ptr{Cvoid}
    arg::Arg
end

keysym(x) = ccall((:XStringToKeysym, "libxkbfile"), xkb_keysym_t, (Cstring,), string(x))
# from wlr_keyboard.h
const WLR_MODIFIER_SHIFT = xkb_keysym_t(1 << 0)
const WLR_MODIFIER_CAPS  = xkb_keysym_t(1 << 1)
const WLR_MODIFIER_CTRL  = xkb_keysym_t(1 << 2)
const WLR_MODIFIER_ALT   = xkb_keysym_t(1 << 3)
const WLR_MODIFIER_MOD2  = xkb_keysym_t(1 << 4)
const WLR_MODIFIER_MOD3  = xkb_keysym_t(1 << 5)
const WLR_MODIFIER_LOGO  = xkb_keysym_t(1 << 6)
const WLR_MODIFIER_MOD5  = xkb_keysym_t(1 << 7)

const MODKEY = WLR_MODIFIER_ALT

#const keys = @show unsafe_wrap(Array, cglobal(:keys, Key), unsafe_load(cglobal(:KEYS_LEN, Cint)))

function spawn(cmd::Vector{String})
    cmd = Base.cconvert.(Cstring, cmd)
    ptrs = push!(pointer.(cmd), C_NULL)
    @ccall spawn(pointer(ptrs)::Ref{Ptr{Cstring}})::Cvoid
    GC.@preserve cmd ptrs
end
focusstack(x::Int) = @ccall focusstack(x::Ref{Cint})::Cvoid
killclient() = @ccall killclient(C_NULL::Ptr{Cvoid})::Cvoid
quit() = @ccall quit(C_NULL::Ptr{Cvoid})::Cvoid

const keys = Dict{Tuple{UInt32, xkb_keysym_t}, Any}(
    (MODKEY, keysym(:p)) => () -> spawn(["dmenu_run"]),
    (MODKEY | WLR_MODIFIER_SHIFT, keysym(:Return)) => () -> spawn(["alacritty"]),
    (MODKEY, keysym(:j)) => () -> focusstack(+1),
    (MODKEY, keysym(:k)) => () -> focusstack(-1),
    (MODKEY | WLR_MODIFIER_SHIFT, keysym(:C)) => killclient,
    (MODKEY | WLR_MODIFIER_SHIFT, keysym(:Q)) => quit,
)

#const WLR_MODIFIER_CAPS = @show unsafe_load(cglobal(:_WLR_MODIFIER_CAPS, UInt32))
cleanmask(x) = x & ~WLR_MODIFIER_CAPS

function keybinding(mods::UInt32, sym::xkb_keysym_t)::Cint
#function keybinding(ptr::Ptr{Cvoid})::Cint
#    mods = unsafe_load(unsafe_load(Ptr{Ptr{UInt32}}(ptr)), 1)
#    sym = unsafe_load(unsafe_load(Ptr{Ptr{xkb_keysym_t}}(ptr)), 2)
    #@show mods sym
    f = get(keys, (cleanmask(mods), sym), nothing)
    f === nothing && return false
    try Base.invokelatest(f) catch e; @show e end
    return true
#    handled = false
#    for k in keys
#        if cleanmask(mods) == cleanmask(k.mod) && sym == k.keysym && k.func != C_NULL
#            ccall(k.func, Cvoid, (Ptr{Arg},), Ref(k.arg))
#            handled = true
#        end
#    end
#    return @show handled
end

end
