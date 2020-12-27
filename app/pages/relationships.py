import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output
from app import app

import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import pathlib
import pickle

PATH = pathlib.Path(__file__).parent

df = pickle.load(open(PATH.joinpath("../data.pickle"), "rb"))

scatter_options = list(map(lambda column: {
    "label": ' '.join(column.split('_')).title(),
    "value": column
}, df.columns[1: 25]))

pc_options = list(map(lambda column: {
    "label": ' '.join(column.split('_')).title(),
    "value": column
}, df.columns[25: -1]))

layout = dbc.Container([
    dbc.Row(
        [dbc.Col([
            dbc.Card([
                dbc.FormGroup([
                        dbc.Label("Numeric Variable #1"),
                        dcc.Dropdown(
                            id="scatter-one",
                            options=scatter_options,
                            value=scatter_options[0]["value"]
                        )
                    ]
                ),
                dbc.FormGroup([
                        dbc.Label("Numeric Variable #2"),
                        dcc.Dropdown(
                            id="scatter-two",
                            options=scatter_options,
                            value=scatter_options[1]["value"]
                        )
                    ]
                )
            ],
            body=True,
            className='scatter-card'),
            dbc.Card([
                dbc.FormGroup([
                        dbc.Label("Categorical Variable #1"),
                        dcc.Dropdown(
                            id="pc-one",
                            options=pc_options,
                            value=pc_options[0]["value"]
                        )
                    ]
                ),
                dbc.FormGroup(
                    children=[
                        dbc.Label("Categorical Variable #2"),
                        dcc.Dropdown(
                            id="pc-two",
                            options=pc_options,
                            value=pc_options[1]["value"]
                        )
                    ]
                ),
                dbc.FormGroup(
                    children=[
                        dbc.Label("Categorical Variable #3"),
                        dcc.Dropdown(
                            id="pc-three",
                            options=pc_options,
                            value=pc_options[2]["value"]
                        )
                    ]
                ),
                dbc.FormGroup(
                    children=[
                        dbc.Label("Categorical Variable #4"),
                        dcc.Dropdown(
                            id="pc-four",
                            options=pc_options,
                            value=pc_options[3]["value"]
                        )
                    ]
                )], body=True 
            )],
            md=4, xs=12
        ),
        dbc.Col([
                dcc.Graph(
                    id='scatter-plot'
                ),
                dcc.Graph(
                    id='parallel-categories'
                ),
            ],
            md=8, xs=12
        )],
        align="center"
    ),
], fluid=True)

@app.callback(
    Output('scatter-plot', 'figure'),
    Output('parallel-categories', 'figure'),
    [   
        Input("scatter-one", "value"),
        Input("scatter-two", "value"),
        Input("scatter-plot", "selectedData"),
        Input('pc-one', "value"),
        Input('pc-two', "value"),
        Input('pc-three', "value"),
        Input('pc-four', "value")
    ]
)
def update_histogram(numeric1, numeric2, selected_data, var1, var2, var3, var4):
    if selected_data == None:
        selected_data = { "points": list(map(lambda x: {"pointNumber": x}, list(range(len(df))))) }
    
    selected_indices = list(map(lambda x: x['pointNumber'], selected_data['points']))

    scatter = px.scatter(df, x=numeric1, y=numeric2)

    scatter.update_traces(
        selectedpoints=selected_indices
    )
    scatter.update_layout(dragmode='lasso')

    pc_df = df.iloc[selected_indices, :]

    parallel_categories = px.parallel_categories(
        pc_df,
        dimensions=[var1, var2, var3, var4],
        color="will_readmit_for_sepsis",
        labels={
            var1: var1.split('_')[0].title(),
            var2: var2.split('_')[0].title(),
            var3: var3.split('_')[0].title(),
            var4: var4.split('_')[0].title(),
        })

    parallel_categories.update_traces(
        dimensions=([{
            "categoryorder": "array",
            "ticktext": ["Wasn't Diagnosed", "Was Diagnosed"]
        }] * 4)
    )

    return [scatter, parallel_categories]