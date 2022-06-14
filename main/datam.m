close;clear
%% energy model: P_total=(a*ft+b)N/1000+P_b  (kw)
a=232.101;
b=99.384;
N=12500;%虚拟机个数
P_b=1695.833;%基础功率（cpu静态+制冷+其他）

%% workload data
workload_data = csvread('day4.csv',1,0);
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



%% pv power
%假设两个数据中心除了负载以外都相同
PVpower_data = xlsread('PV_power.xlsx','A2:B97');
PV_power=PVpower_data(:,2);
PV_MAX=1000; %光伏最大功率为1000kw
%% price
price_list=csvread('electricity_power_spline.csv',1,0);
price_0=price_list(:,1);
price_1=price_list(:,2);
price_2=price_list(:,3);
price_3=price_list(:,4);
price_4=price_list(:,5);
price_5=price_list(:,6);
price_6=price_list(:,7);
price_7=price_list(:,8);
price_8=price_list(:,9);
price_9=price_list(:,10);

price=price_5;
anothor_price=price_6;
price=price'/200;
anothor_price=anothor_price'/200;

%%不进行优化
P_DC_0=(a*CPU+b)*N/1000+P_b;
COST_0=price*P_DC_0;

%% 可视化
x = 0.25:0.25:24; %定义x的范围，第二个参数表示步长
figure(1) %建立一个幕布
subplot(2,2,1)
hold on
grid on
box on
title({'day4 cpu usage(%)'}); 
plot(x,CPU_0','LineWidth',1) %绘制当前二维平面图
plot(x,CPU_1,'LineWidth',1)
plot(x,CPU_2,'LineWidth',1)
legend('CPU_0','CPU_1', 'CPU_2'); 
set(gca,'XLim',[0 24]);
subplot(2,2,3)
hold on
grid on
box on
title({'day4 cpu usage(%)'}); 
plot(x,CPU,'LineWidth',1)
set(gca,'XLim',[0 24]);

subplot(2,2,2)
hold on
grid on
box on
title({'day4 ram usage(%)'}); 
plot(x,RAM_0','LineWidth',1) %绘制当前二维平面图
plot(x,RAM_1,'LineWidth',1)
plot(x,RAM_2,'LineWidth',1)
legend('RAM_0','RAM_1', 'RAM_2'); 
set(gca,'XLim',[0 24]);
subplot(2,2,4)
hold on
grid on
box on
title({'day4 ram usage(%)'}); 
plot(x,RAM,'LineWidth',1)
set(gca,'XLim',[0 24]);


close;

