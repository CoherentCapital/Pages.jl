using HTTP
using HTTP: hasheader
using MbedTLS

@static if is_apple()
    launch(x) = run(`open $x`)
elseif is_linux()
    launch(x) = run(`xdg-open $x`)
elseif is_windows()
    launch(x) = run(`cmd /C start $x`)
end

@async begin
    sleep(2)
    launch("https://127.0.0.1:8081/examples/mwe")
end

@async HTTP.listen(ip"127.0.0.1", 8081,;
            ssl = true,
            sslconfig = MbedTLS.SSLConfig(joinpath(dirname(@__FILE__),"cert.pem"), joinpath(dirname(@__FILE__),"key.pem"))) do http
    if HTTP.WebSockets.is_upgrade(http.message)

        HTTP.WebSockets.upgrade(http) do client
            count = 1
            while !eof(client);
                msg = String(readavailable(client))
                println(msg)
                write(client, "Hello JavaScript! From Julia $count")
                count += 1
            end
        end
    else
        HTTP.Servers.handle_request(http) do req::HTTP.Request
            HTTP.Response(200,readstring(joinpath(dirname(@__FILE__),"mwe.html")))
        end
    end
end




