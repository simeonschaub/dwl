module DWL

struct xkb_keysym_t
    x::UInt32
end

struct Arg
    x::UInt
end

struct Key
    mod::UInt32
    keysym::xkb_keysym_t
    func::Ptr{Cvoid}
    arg::Arg
end

const keys = @show unsafe_wrap(Array, cglobal(:keys, Key), unsafe_load(cglobal(:KEYS_LEN, Cint)))

const WLR_MODIFIER_CAPS = @show unsafe_load(cglobal(:_WLR_MODIFIER_CAPS, UInt32))
cleanmask(x) = x & ~WLR_MODIFIER_CAPS

#function keybinding(mods::UInt32, sym::xkb_keysym_t)::Cint
function keybinding(ptr::Ptr{Cvoid})::Cint
    mods = unsafe_load(unsafe_load(Ptr{Ptr{UInt32}}(ptr)), 1)
    sym = unsafe_load(unsafe_load(Ptr{Ptr{xkb_keysym_t}}(ptr)), 2)
    @show mods sym
    handled = false
    for k in keys
        if cleanmask(mods) == cleanmask(k.mod) && sym == k.keysym && k.func != C_NULL
            ccall(k.func, Cvoid, (Ptr{Arg},), Ref(k.arg))
            handled = true
        end
    end
    return handled
end

end
