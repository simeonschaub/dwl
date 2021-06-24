module DWL
Base.Experimental.@compiler_options compile=min optimize=0 infer=false

const xkb_keysym_t = UInt32
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

macro dwl_function(jl_name, c_name, argtype)
    return esc(quote
        struct $jl_name
            x::Ref{$argtype}
            $jl_name(x) = new(Ref{$argtype}(x))
        end
        (f::$jl_name)() = @ccall $c_name(f.x::Ref{$argtype})::Cvoid
    end)
end
macro dwl_function(name)
    return esc(quote
        $name() = @ccall $name(C_NULL::Ptr{Cvoid})::Cvoid
    end)
end

macro MOD(key)
    return :(MODKEY, $(keysym(key)))
end
macro MOD_SHIFT(key)
    return :(MODKEY | WLR_MODIFIER_SHIFT, $(keysym(key)))
end
macro MOD_CTRL(key)
    return :(MODKEY | WLR_MODIFIER_CTRL, $(keysym(key)))
end
macro MOD_CTRL_SHIFT(key)
    return :(MODKEY | WLR_MODIFIER_CTRL | WLR_MODIFIER_SHIFT, $(keysym(key)))
end
macro TAG_KEYS(key, skey, tag)
    return esc(:((
        @MOD($key)             => View(1 << $tag),
        @MOD_CTRL($key)        => ToggleView(1 << $tag),
        @MOD_SHIFT($skey)      => Tag(1 << $tag),
        @MOD_CTRL_SHIFT($skey) => ToggleTag(1 << $tag),
    )...))
end

const MODKEY = WLR_MODIFIER_ALT

struct Spawn
    cmd::Vector{String}
    ptrs::Vector{Ptr{UInt8}}

    function Spawn(cmd::Cmd)
        cmd = Base.cconvert.(Cstring, cmd.exec)
        ptrs = push!(pointer.(cmd), C_NULL)
        return new(cmd, ptrs)
    end
end
function (s::Spawn)()
    @ccall spawn(s.ptrs::Vector{Ptr{UInt8}})::Cvoid
    GC.@preserve s
end

@dwl_function FocusStack focusstack Cint
@dwl_function IncNMaster incnmaster Cint
@dwl_function SetMFact setmfac Cfloat
@dwl_function View view Cuint
@dwl_function ToggleView toggleview Cuint
@dwl_function Tag tag Cuint
@dwl_function ToggleTag toggletag Cuint
@dwl_function zoom
@dwl_function killclient
@dwl_function togglefloating
@dwl_function togglefullscreen
@dwl_function quit

const keys = Dict{Tuple{UInt32, xkb_keysym_t}, Any}(
    @MOD(p)            => Spawn(`dmenu_run`),
    @MOD_SHIFT(Return) => Spawn(`alacritty`),
    @MOD(j)            => FocusStack(+1),
    @MOD(k)            => FocusStack(-1),
    @MOD(i)            => IncNMaster(+1),
    @MOD(d)            => IncNMaster(-1),
    @MOD(h)            => SetMFact(+0.05),
    @MOD(l)            => SetMFact(-0.05),
    @MOD(Return)       => zoom,
    @MOD(Tab)          => View(0),
    @MOD_SHIFT(C)      => killclient,
    @MOD_SHIFT(space)  => togglefloating,
    @MOD(e)            => togglefullscreen,
    @MOD_SHIFT(Q)      => quit,

    @TAG_KEYS(1, exclam,     0),
    @TAG_KEYS(2, at,         1),
    @TAG_KEYS(3, numbersign, 2),
    @TAG_KEYS(4, dollar,     3),
    @TAG_KEYS(5, percent,    4),
    @TAG_KEYS(6, caret,      5),
    @TAG_KEYS(7, ampersand,  6),
    @TAG_KEYS(8, asterisk,   7),
    @TAG_KEYS(9, parenleft,  8),
)

cleanmask(x) = x & ~WLR_MODIFIER_CAPS

function keybinding(mods::UInt32, sym::xkb_keysym_t)::Cint
    f = get(keys, (cleanmask(mods), sym), nothing)
    f === nothing && return false
    try Base.invokelatest(f) catch e; @show e end
    return true
end

end
