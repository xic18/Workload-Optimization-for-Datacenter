# Workload-Optimization-for-Datacenter
Workload Optimization for Datacenter with Distributed Photovoltaic and Energy Storage Systems
zip文件构成如下：

## data

文件夹存储预处理的数据

electricity_price：节点电价数据（1h粒度）

electricity_power_spline：是对于节点电价electricity_price插值得到的LMP（15min粒度）

energy_model_data：处理原始能耗数据得到的数据

energy_data：energy_model_data包含很多天的数据，energy_data仅取第一天的数据

load_info：三类优先级负载的数量和资源利用率（15min粒度）

my_LMP：24节点的节点电价（1h粒度）

my_LMP_spline：24节点的节点电价的插值（15min粒度）

power_price：更多节点的小时为粒度的节点电价（单位：美元/兆瓦时）

PV_power：典型的光伏出力

## raw_data

存储原始数据，包括谷歌数据集（task_event）和能耗数据集（2agosto -dic 2021）

谷歌数据集（task_event）是官网提供的原始数据，经过认为处理后得到workload文件夹

workload中raw文件夹是对应一天的原始的负载信息，合并到了对应当天的data.csv中，包含对应的CPU占用率等

2018-LMP为项目使用的连续节点电价

2agosto -dic 2021为数据中心能耗数据集的原始数据，经过处理得到energy_model_data.csv

## data_process

执行相关脚本的时候如果发现目录下没有对应文件夹，请自行从data或raw_data添加对应的数据文件！

process_raw_energy_data.py：处理2agosto -dic 2021.csv得到energy_model_data.csv

load_process.py：处理data.csv 得到load_info.csv

workload.py/workload.ipynb：处理data.csv 得到load_info.csv，用了多线程，应该会更快一些

lmp.ipynb：节点电价进行插值，关于插值方法有详细介绍

lmp24.ipynb：IEEE24节点电价进行插值

## main

为了方便，这里脚本用到的数据文件都放在了同一目录下，如果希望生成新的数据，请参考上述data_process各脚本的介绍进行修改

由于这里的数据都在文件夹data中，就不再赘述含义

model_1.m：单节点优化模型，其中包括光伏系统和储能系统（想要去掉光伏系统就把最大出力改成0，储能系统是数据中心自带的，所以不能去掉）

model_2.m：双节点优化模型，其中包括光伏系统和储能系统

multi_optimize.m：IEEE24节点系统优化

define_struct.m：定义每一个数据中心节点的结构体类型

load_dataset.m：加载IEEE24节点数据，以及每个数据中心的光伏、负载数据

datam.m：数据可视化，可以自己修改

case24_ieee_rts.m：修改了线路阻塞的脚本，以便生成差异较大的节点电价，建议替换matpower中的同名脚本（请提前做好备份）
