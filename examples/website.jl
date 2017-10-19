using Pages, PlotlyJS

Pages.start()
# ==============================================================================
# Example 1.
# Type in: http://localhost:8000/SomeOtherContent?name=Travis
# ==============================================================================
Endpoint("/SomeOtherContent") do request::Request
    uri = URI(request.resource)
       param = query_params(uri)
       "Hello $(param["name"]). I am sending you some text."
end
# ==============================================================================
# Example 1.
#  Type in: http://localhost:8000/MyCoolSite  then run: example_plotly()
# ==============================================================================
Endpoint("/MyCoolSite") do request::Request
    Pages.pages["/MyCoolSite"].folder = dirname(@__FILE__)
end

# ==============================================================================
# Shamelessly copied from existing example!
# ==============================================================================
function example_plotly()

n = 10
data = [scatter(;x = 1:n,y = rand(n))]
layout = Layout(;title = "Create a new <div> and plot a single trace",
    width = 600,
    height = 300
)
id = "Plot1"
Pages.add(Pages.Element(id=id))
Pages.broadcast("script","""Plotly.newPlot("$(id)",$(data),$(layout));""")

trace1 = scatter(;x = 1:n, y = rand(n))
trace2 = scatter(;x = 1:n, y = rand(n))
data = [trace1, trace2]
layout = Layout(;title = "Create a new <div> and plot an array of traces",
    width = 600,
    height = 300
)
id = "Plot2"
Pages.add(Pages.Element(id=id))
Pages.broadcast("script","""Plotly.newPlot("$(id)",$(data),$(layout));""")

trace1 = scatter(;
    x = [1, 2, 3, 4],
    y = [10, 15, 13, 17],
    mode = "markers")

trace2 = scatter(;
    x = [2, 3, 4, 5],
    y = [16, 5, 11, 10],
    mode = "lines")

trace3 = scatter(;
    x = [1, 2, 3, 4],
    y = [12, 9, 15, 12],
    mode = "lines+markers")

data = [trace1, trace2, trace3]

layout = Layout(;
    title = "Line and Scatter Plot",
    height = 400,
    width = 480)

id = "Plot3"
Pages.add(Pages.Element(id=id))
Pages.broadcast("script","""Plotly.newPlot("$(id)",$(data));""")

country = ["Switzerland (2011)", "Chile (2013)", "Japan (2014)",
           "United States (2012)", "Slovenia (2014)", "Canada (2011)",
           "Poland (2010)", "Estonia (2015)", "Luxembourg (2013)",
           "Portugal (2011)"]

votingPop = [40, 45.7, 52, 53.6, 54.1, 54.2, 54.5, 54.7, 55.1, 56.6]
regVoters = [49.1, 42, 52.7, 84.3, 51.7, 61.1, 55.3, 64.2, 91.1, 58.9]

# notice use of `attr` function to make nested attributes
trace1 = scatter(;x=votingPop, y=country, mode="markers",
                  name="Percent of estimated voting age population",
                  marker=attr(color="rgba(156, 165, 196, 0.95)",
                              line_color="rgba(156, 165, 196, 1.0)",
                              line_width=1, size=16, symbol="circle"))

trace2 = scatter(;x=regVoters, y=country, mode="markers",
                  name="Percent of estimated registered voters")
# also could have set the marker props above by using a dict
trace2["marker"] = Dict(:color => "rgba(204, 204, 204, 0.95)",
                       :line => Dict(:color=> "rgba(217, 217, 217, 1.0)",
                                     :width=> 1),
                       :symbol => "circle",
                       :size => 16)

data = [trace1, trace2]

layout = Layout(Dict{Symbol,Any}(:paper_bgcolor => "rgb(254, 247, 234)",
                                 :plot_bgcolor => "rgb(254, 247, 234)");
                title="Votes cast for ten lowest voting age population in OECD countries",
                width=600, height=600, hovermode="closest",
                margin=Dict(:l => 140, :r => 40, :b => 50, :t => 80),
                xaxis=attr(showgrid=false, showline=true,
                           linecolor="rgb(102, 102, 102)",
                           titlefont_font_color="rgb(204, 204, 204)",
                           tickfont_font_color="rgb(102, 102, 102)",
                           autotick=false, dtick=10, ticks="outside",
                           tickcolor="rgb(102, 102, 102)"),
                legend=attr(font_size=10, yanchor="middle",
                            xanchor="right"),
                )

id = "Plot4"
Pages.add(Pages.Element(id=id))
Pages.broadcast("script","""Plotly.newPlot("$(id)",$(data),$(layout));""")

end

 # example_plotly()
