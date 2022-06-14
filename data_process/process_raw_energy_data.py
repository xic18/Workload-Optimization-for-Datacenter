import os
import pandas as pd
import numpy as np
import csv

df=pd.read_csv("2agosto -dic 2021.csv",quoting=csv.QUOTE_NONE)
df.columns=["mac","weekday","time","esp32time","voltage(V)","current(A)","active power(W)","frequency(Hz)","active energy(kWh)","power factor","esp32temp","CPU usage(%)","CPU power usage(%)","CPUtemp","GPU usage(%)","GPU power usage(%)","GPUtemp","RAM usage(%)","RAM power usage(%)"]
columns_list=["time","voltage(V)","current(A)","active power(W)","frequency(Hz)","active energy(kWh)","CPU usage(%)","CPU power usage(%)","RAM usage(%)","RAM power usage(%)"]
df2=df[columns_list].iloc[:-1]

for i in range(86400):
    for j in range(9):
        df2[df2.columns[j+1]].iloc[i]=float(df2[df2.columns[j+1]].iloc[i][1:-1])
    print(i/864,"%")

df2.to_csv("energy_model_data.csv",sep=',',index=False,header=True)