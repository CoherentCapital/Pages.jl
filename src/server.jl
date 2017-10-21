# Browser Window (Borrowed from Blink.jl)
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

# this should no longer be nesesary ...maybe
Endpoint("/pages.js") do request::Request
    readstring(joinpath(dirname(@__FILE__),"/pages.js"))
end

ws = WebSocketHandler() do request::Request, client::WebSocket
    while true
        msg = JSON.parse(String(read(client)))
        print(msg)
        route = msg["route"]
        if !haskey(pages[route].sessions,client.id)
            pages[route].sessions[client.id] = client
        end
        haskey(msg,"args") ? callbacks[msg["name"]].callback(client,msg["args"]) : callbacks[msg["name"]].callback(client)
    end
end

http = HttpHandler() do request::Request, response::Response
    route = URI(request.resource).path
    str = match(r"^(\/[\d\w- _]+)", route);
    folder = String(str[1])

    # We are in an existing folder
    if haskey(pages, folder)
        req = pages[folder].handler(request) # let's see what we're dealing with here.

        # We will be serving from folder but is a file specified?
        if length(folder) < length(route) # Yes, it is!
            file = replace(route, r"^(\/[\d\w- _]+)", "");

        # No, no file specified so we will specify the standard default "/index.html"
        else
            file = "/index.html"
        end

        # I thought mimetypes should just work but found that I had to detect/set them
        key = match(r"(?:\.(\w+$))", file)[1]
        mime = mimetypes[ key ]

        # Serve results
        if length(Pages.pages[folder].folder) > 0
            res = Response( 200, Dict{AbstractString,AbstractString}([("Content-Type", mime)]),
                            readstring( Pages.pages[folder].folder * file ))
        else
            req # = "Page generated on server."
        end

    # Folder does not exist! ...Inform user.
    else
        res = "Sorry, page not found."
    end
end

server = Server(http,ws)

function start(p = 8000)
    global port = p
    @async run(server, port)
end
