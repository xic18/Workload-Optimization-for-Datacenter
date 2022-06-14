import pandas as pd
import numpy as np
import threading
import time


def Fun0(N):
    j=N
    for i in range(len(workload_dataset)):
        if j>=N+10:
            break
        if j==0 & workload_dataset["timestamp"].iloc[i] < tick_list[j]:
            pass
        elif j==0:
            j = j + 1
        elif workload_dataset["timestamp"].iloc[i] < tick_list[j-1]:
            continue
        elif workload_dataset["timestamp"].iloc[i] < tick_list[j]:
            pass
        else:
            j = j + 1
        # print(i / 84613, "%")
        if workload_dataset["priority"].iloc[i] < 2:
            load_info["num_0"].iloc[j] += 1
            load_info["CPU_usage_0"].iloc[j] += workload_dataset["CPU_request"].iloc[i]
            load_info["RAM_usage_0"].iloc[j] += workload_dataset["RAM_request"].iloc[i]
        elif workload_dataset["priority"].iloc[i] < 8:
            load_info["num_1"].iloc[j] += 1
            load_info["CPU_usage_1"].iloc[j] += workload_dataset["CPU_request"].iloc[i]
            load_info["RAM_usage_1"].iloc[j] += workload_dataset["RAM_request"].iloc[i]
        else:
            load_info["num_2"].iloc[j] += 1
            load_info["CPU_usage_2"].iloc[j] += workload_dataset["CPU_request"].iloc[i]
            load_info["RAM_usage_2"].iloc[j] += workload_dataset["RAM_request"].iloc[i]

def Fun1():
    Fun0(0)
def Fun2():
    Fun0(10)
def Fun3():
    Fun0(20)
def Fun4():
    Fun0(30)
def Fun5():
    Fun0(40)
def Fun6():
    # Fun0(50)
    j = 50
    for i in range(len(workload_dataset)):
        if j >= 60:
            break
        if j == 0 & workload_dataset["timestamp"].iloc[i] < tick_list[j]:
            pass
        elif j == 0:
            j = j + 1
        elif workload_dataset["timestamp"].iloc[i] < tick_list[j - 1]:
            continue
        elif workload_dataset["timestamp"].iloc[i] < tick_list[j]:
            pass
        else:
            j = j + 1
        print(i / 84613, "%")
        if workload_dataset["priority"].iloc[i] < 2:
            load_info["num_0"].iloc[j] += 1
            load_info["CPU_usage_0"].iloc[j] += workload_dataset["CPU_request"].iloc[i]
            load_info["RAM_usage_0"].iloc[j] += workload_dataset["RAM_request"].iloc[i]
        elif workload_dataset["priority"].iloc[i] < 8:
            load_info["num_1"].iloc[j] += 1
            load_info["CPU_usage_1"].iloc[j] += workload_dataset["CPU_request"].iloc[i]
            load_info["RAM_usage_1"].iloc[j] += workload_dataset["RAM_request"].iloc[i]
        else:
            load_info["num_2"].iloc[j] += 1
            load_info["CPU_usage_2"].iloc[j] += workload_dataset["CPU_request"].iloc[i]
            load_info["RAM_usage_2"].iloc[j] += workload_dataset["RAM_request"].iloc[i]
def Fun7():
    Fun0(60)
def Fun8():
    Fun0(70)
def Fun9():
    Fun0(80)
def Fun10():
    Fun0(90)



if __name__ == '__main__':

    workload_dataset = pd.read_csv("data.csv")

    tick_list = []
    columns_list = ["time", "num_0", "CPU_usage_0", "RAM_usage_0", "num_1", "CPU_usage_1", "RAM_usage_1", "num_2",
                    "CPU_usage_2", "RAM_usage_2"]
    # load_info=pd.DataFrame(columns=columns_list)
    load_info_np = np.zeros((96, 10))
    load_info = pd.DataFrame(load_info_np)
    load_info.columns = columns_list
    load_info["time"] = list(range(96))
    for i in range(96):
        tick = 18600000000 + (i + 1) * 900 * 1000000
        tick_list.append(tick)

    thread1 = threading.Thread(target=Fun1)
    thread2 = threading.Thread(target=Fun2)
    thread3 = threading.Thread(target=Fun3)
    thread4 = threading.Thread(target=Fun4)
    thread5 = threading.Thread(target=Fun5)
    thread6 = threading.Thread(target=Fun6)
    thread7 = threading.Thread(target=Fun7)
    thread8 = threading.Thread(target=Fun8)
    thread9 = threading.Thread(target=Fun9)
    thread10 = threading.Thread(target=Fun10)
    # 开启线程
    thread1.start()
    thread2.start()
    thread3.start()
    thread4.start()
    thread5.start()
    thread6.start()
    thread7.start()
    thread8.start()
    thread9.start()
    thread10.start()

    load_info.to_csv("load_info.csv", sep=',', index=False, header=True)


