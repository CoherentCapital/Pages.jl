__precompile__()

module Pages

using HTTP, JSON

import HTTP.WebSockets.WebSocket

export Endpoint, Callback, Plotly

export getvar, unregister!

mutable struct Endpoint
    handler::Function
    route::Regex
    routespec::String
    sessions::Dict{String,WebSocket}

    function Endpoint(handler, routespec)
        route = makeregex(routespec)
        p = new(handler,route,routespec,Dict{String,WebSocket}())
        !haskey(pages,route) || warn("Page $route already exists.")
        pages[route] = p
        finalizer(p, p -> delete!(pages, p.route))
        p
    end
end

# unregister
function unregister!(routespec)
    route = makeregex(routespec)
    delete!(pages, route)
    nothing
end

# Make regex from a route spec
# e.g. "/ticket/<id>" => r"^/ticket/([^/]+)\$"
function makeregex(routespec)
    s = replace(routespec, r"\.", "\\.")
    s = replace(s, r"<[^>]+>", "([^/]+)")
    return Regex(string("^", s, "(\\?.*\$)*"))
end

# Returns Endpoint for the first matched route
#
# Due to the nature of regular expression matching, we may end up with 
# multiple matches e.g. /examples regex could match /examples/one as well.
# We will pick the most specific endpoint by taking the longest routespec.
function matchroute(pages, uri)
    matches = Endpoint[]
    for (k, ep) in pages
        #println("matching $k with $uri")
        if ismatch(k, uri)
            push!(matches, ep)
        end
    end
    if length(matches) > 0
        L = [length(ep.routespec) for ep in matches]
        idx = indmax(L)
        return matches[idx]
    else
        nothing
    end
end

# Check if uri matches any routes in Pages
hasroute(pages, uri) = matchroute(pages, uri) != nothing

function Base.show(io::Base.IO,endpoint::Endpoint)
    print(io,"Endpoint created at $(endpoint.routespec).")
end

const pages = Dict{Regex,Endpoint}() # url => page

include("callbacks.jl")
include("server.jl")
include("api.jl")
include("displays/plotly.jl")
# include("ijulia.jl")

include("../examples/examples.jl")

end
