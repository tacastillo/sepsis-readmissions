import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output
from app import app

import plotly.express as px
import pandas as pd
import pathlib
import pickle


PATH = pathlib.Path(__file__).parent

df = pickle.load(open(PATH.joinpath("../data.pickle"), "rb"))

histogram_options = list(map(lambda column: {
    "label": ' '.join(column.split('_')).title(),
    "value": column
}, df.iloc[:, 1:-1].columns))

layout = dbc.Container([
    dbc.Row(
        [dbc.Col(children=[
            dbc.Card(
                dbc.FormGroup(
                    children=[
                        dbc.Label("Variable"),
                        dcc.Dropdown(
                            id="histogram-variable",
                            options=histogram_options,
                            value=histogram_options[0]["value"]
                        )
                    ]
                )
            , body=True 
            )],
            md=4, xs=12
        ),
        dbc.Col(children=[
                dcc.Graph(
                    id='histogram'
                ),
            ],
            md=8, xs=12
        )],
        align="center"
    ),
], fluid=True)

@app.callback(
    Output('histogram', 'figure'),
    [
        Input('histogram-variable', "value")
    ]
)
def update_histogram(variable):
    fig = px.histogram(df,
        x=variable,
        color="will_readmit_for_sepsis",
        barmode="overlay",
        histnorm='probability density',
        nbins=100,
        title=f"Probability of Value Based on Occurence Per State (Re-Admit/No Re-Admit)"
    )
    fig.update_yaxes(title="Probability")
    fig.data[0].name = "Won't Re-Admit"
    fig.data[1].name = "Will Re-Admit"

    return fig