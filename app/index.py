import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output

import plotly.express as px
import pandas as pd
import pickle

from app import app
from pages import home, histograms, relationships

sidebar = html.Div(
    [
        html.H2("Mimic III Data Analysis", className="display-4"),
        html.Hr(),
        html.P(
            "Exploratory data analysis on the MIMIC-III data set for use in predicting sepsis readmissions", className="lead"
        ),
        dbc.Nav(
            [
                dbc.NavLink("Home", href="/", active="exact"),
                dbc.NavLink("Differences", href="/differences", active="exact"),
                dbc.NavLink("Relationships", href="/relationships", active="exact"),
            ],
            vertical=True,
            pills=True,
        ),
    ],
    className="sidebar",
)

content = html.Div(id="page-content", className="content")

app.layout = html.Div([dcc.Location(id="url"), sidebar, content])

@app.callback(Output("page-content", "children"), [Input("url", "pathname")])
def render_page_content(pathname):
    if pathname == "/":
        return home.layout
    elif pathname == "/differences":
        return histograms.layout
    elif pathname == "/relationships":
        return relationships.layout
    # If the user tries to reach a different page, return a 404 message
    return dbc.Jumbotron(
        [
            html.H1("404: Not found", className="text-danger"),
            html.Hr(),
            html.P(f"The pathname {pathname} was not recognized."),
        ]
    )

if __name__ == "__main__":
    app.run_server(debug=True)