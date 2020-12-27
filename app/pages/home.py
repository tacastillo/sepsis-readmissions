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

content = """
# MIMIC-III Exploratory Data Analysis for Sepsis Readmissions
## Introduction
This website was made to convey and help explore a cross-section of the [MIMIC-III Critical Care Database](https://mimic.physionet.org/about/mimic/). This exploratory data analysis was a preliminary step to building a machine learning model to predict whether or not a patient will be re-admitted for sepsis within 30 days of an inpatient stay.
## About the Data
The data set that is being explored is every column and table of the MIMIC-III database. The data used has been queried, cleaned and proofchecked to focus on under 3 dozen key features that may be of significance. The potential significance of these features had been deduced by reading literature and papers on sepsis and existing research on the topic.
"""

layout = dbc.Container([
    dbc.Row(
        [
            dcc.Markdown(content)
        ]
    ),
], fluid=True)