function y=define_struct(work_load_path,pv_power_path,price_index)

%% workload data
workload_data = csvread(work_load_path,1,0);
num_0=workload_data(:,2);
CPU_0=workload_data(:,3);
RAM_0=workload_data(:,4);
num_1=workload_data(:,5);
CPU_1=workload_data(:,6);
RAM_1=workload_data(:,7);
num_2=workload_data(:,8);
CPU_2=workload_data(:,9);
RAM_2=workload_data(:,10);
CPU=workload_data(:,11);
RAM=workload_data(:,12);
POWER=workload_data(:,13);

y.CPU_0=CPU_0;
y.CPU_1=CPU_1;
y.CPU_2=CPU_2;
y.CPU=CPU;
y.POWER=POWER;

%% pv power
%假设两个数据中心除了负载以外都相同
PVpower_data = xlsread(pv_power_path,'A2:B97');
PV_power=PVpower_data(:,2);
y.PV_power=PV_power;

%% price
price_list=csvread('my_LMP_spline.csv',1,0);
price=price_list(:,price_index);
price=price'/200;
y.price=price;

%% cost
% energy model: P_total=(a*ft+b)N/1000+P_b  (kw)
a=232.101;
b=99.384;
N=12500;%虚拟机个数
P_b=1695.833;%基础功率（cpu静态+制冷+其他）
P_DC_0=(a*CPU+b)*N/1000+P_b;
COST_0=price*P_DC_0;
y.P_DC_0=P_DC_0;
y.COST_0=COST_0;

%% 决策变量
y.x_0 = sdpvar(1,96);
y.x_1 = sdpvar(1,96);
y.x_2 = sdpvar(1,96);
y.Pch = sdpvar(1,96);
y.Pdch = sdpvar(1,96);
y.ch = binvar(1,96);
y.dch = binvar(1,96);



