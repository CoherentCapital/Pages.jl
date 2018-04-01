# Browser Window (Borrowed from Blink.jl)
@static if is_apple()
    launch(x) = run(`open $x`)
elseif is_linux()
    launch(x) = run(`xdg-open $x`)
elseif is_windows()
    launch(x) = run(`cmd /C start $x`)
end

# const connections = Dict{Int,WebSocket}() # WebSocket.id => WebSocket
const conditions = Dict{String,Condition}()
conditions["connected"] = Condition()
conditions["unloaded"] = Condition()

Endpoint("/pages.js") do request::HTTP.Request
    readstring(joinpath(dirname(@__FILE__),"pages.js"))
end

# ws = WebSocketHandler() do request::Request, client::WebSocket
#     while true
#         msg = JSON.parse(String(read(client)))
#         route = msg["route"]
#         if !haskey(pages[route].sessions,client.id)
#             pages[route].sessions[client.id] = client
#         end
#         haskey(msg,"args") ? callbacks[msg["name"]].callback(client,msg["args"]) : callbacks[msg["name"]].callback(client)
#     end
# end

# For external websocket connections not from a page served locally, e.g. IJulia
const external = Dict{String,WebSocket}()

# Keep track of additional request information (e.g. url vars)
# Warning: ideally we shouldn't use a global lookup table but I don't know
#   how to inject the URI Dict into the Request object in HTTP.jl 
const uri_vars = Dict{HTTP.Request,Dict}()

# Get the value of a variable specified in the URL
getvar(req, k) = uri_vars[req][k]

# Populate uri_vars for this request with a dict of variables extracted from the uri
# For example,
#    route     = regex that represents routespec below
#    routespec = "/ticket/<event>/<date>
#    uri       = "/ticket/lakers/2018-03-31
# would return
#    Dict("event" => "lakers", "date" => "2018-03-31")
function populate_uri_dict!(request, ep, uri)
    d = Dict{String,String}()
    m = match(ep.route, uri)
    if length(m.captures) > 0
        v = matchall(r"<[^>]+>", ep.routespec)
        v = [strip(x, ['<','>']) for x in v]
        for (i, s) in enumerate(v)
            d[s] = m.captures[i]
        end
    end
    uri_vars[request] = d
end

function start(p = 8000)
    global port = p
    HTTP.listen(ip"127.0.0.1",p) do http
        if HTTP.WebSockets.is_upgrade(http.message)
            HTTP.WebSockets.upgrade(http) do client
                while !eof(client);
                    data = String(readavailable(client))
                    msg = JSON.parse(data)
                    name = pop!(msg,"name"); route = pop!(msg,"route"); id = pop!(msg,"id")
                    if haskey(pages,route)
                        if !haskey(pages[route].sessions,id)
                            pages[route].sessions[id] = client
                        end
                    else
                        if !haskey(external,id)
                            external[id] = client
                        end
                    end
                    if haskey(callbacks,name)
                        callbacks[name].callback(client,route,id,msg)
                    end
                end
            end
        else
            # println("matching $(http.message.target)")
            ep = matchroute(pages, http.message.target)
            println("match route result => $ep")
            if ep != nothing
                populate_uri_dict!(http.message, ep, HTTP.URI(http.message.target).path)
                try
                    HTTP.Servers.handle_request(ep.handler,http)
                finally
                    delete!(uri_vars, http.message)
                end
            else
                HTTP.Servers.handle_request((req) -> HTTP.Response(404),http)
            end
        end
    end
end
