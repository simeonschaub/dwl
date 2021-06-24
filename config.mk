# paths
PREFIX = /usr/local

# Default compile flags (overridable by environment)
#CFLAGS ?= -g -Wall -Wextra -Werror -Wno-unused-parameter -Wno-sign-compare -Wno-unused-function -Wno-unused-variable -Wdeclaration-after-statement

# Uncomment to build XWayland support
CFLAGS += -DXWAYLAND

JL_BIN = julia-latest #~/Documents/Julia/julia/julia #./julia/julia
JL_SHARE = $(shell $(JL_BIN) -e 'print(joinpath(Sys.BINDIR, Base.DATAROOTDIR, "julia"))')
CFLAGS   += $(shell $(JL_BIN) $(JL_SHARE)/julia-config.jl --cflags)
CXXFLAGS += $(shell $(JL_BIN) $(JL_SHARE)/julia-config.jl --cflags)
LDFLAGS  += $(shell $(JL_BIN) $(JL_SHARE)/julia-config.jl --ldflags)
LDLIBS   += $(shell $(JL_BIN) $(JL_SHARE)/julia-config.jl --ldlibs)
