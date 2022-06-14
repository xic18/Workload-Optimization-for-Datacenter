import pandas as pd
import numpy as np

workload_dataset=pd.read_csv("data2.csv")

tick_list=[]
columns_list=["time","num_0","CPU_usage_0","RAM_usage_0","num_1","CPU_usage_1","RAM_usage_1","num_2","CPU_usage_2","RAM_usage_2"]
# load_info=pd.DataFrame(columns=columns_list)
load_info_np=np.zeros((96,10))
load_info=pd.DataFrame(load_info_np)
load_info.columns=columns_list
load_info["time"]=list(range(96))
for i in range(96):
    tick=105000000000+(i+1)*900*1000000
    tick_list.append(tick)
j=0
for i in range(len(workload_dataset)):
    if workload_dataset["timestamp"].iloc[i]<tick_list[j]:
        pass
    else:
        j=j+1
    if(i%100==0):
        print(i/13664510 ,"%")
    if workload_dataset["priority"].iloc[i]<2:
        load_info["num_0"].iloc[j]+=1
        load_info["CPU_usage_0"].iloc[j]+=workload_dataset["CPU_request"].iloc[i]
        load_info["RAM_usage_0"].iloc[j]+=workload_dataset["RAM_request"].iloc[i]
    elif workload_dataset["priority"].iloc[i]<8:
        load_info["num_1"].iloc[j]+=1
        load_info["CPU_usage_1"].iloc[j]+=workload_dataset["CPU_request"].iloc[i]
        load_info["RAM_usage_1"].iloc[j]+=workload_dataset["RAM_request"].iloc[i]
    else:
        load_info["num_2"].iloc[j]+=1
        load_info["CPU_usage_2"].iloc[j]+=workload_dataset["CPU_request"].iloc[i]
        load_info["RAM_usage_2"].iloc[j]+=workload_dataset["RAM_request"].iloc[i]

load_info.to_csv("load_info2.csv",sep=',',index=False,header=True)