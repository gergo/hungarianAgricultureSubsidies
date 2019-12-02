import pandas as pd
import plotly.express as px

df = pd.read_csv('../output/tiborcz_wins.csv')

fig = px.bar(df, x='year', y='amount', title='Agricultural wins of Tiborcz family')
fig.show()

fig.write_image("../output/tiborcz_wins.png")
