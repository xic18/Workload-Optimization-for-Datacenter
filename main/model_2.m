close;clear

%[x,fval]=intlinprog(f,intcon,A,b,Aeq,beq,lb,ub);


%模型适用于双节点系统 系统负载调度+分布式pv+储能+多站配合 +松弛约束+连续的节点电价
%主要对结果做了可视化
%% MAX
MAX_CPU=0.9;
MIN_CPU=0.05;
MIN_PCT_0=0.2;
MIN_PCT_1=0.9;
%% energy model: P_total=(a*ft+b)N/1000+P_b  (kw)
a=232.101;
b=99.384;
N=12500;%虚拟机个数
P_b=1695.833;%基础功率（cpu静态+制冷+其他）

%% workload data
workload_data = csvread('day2.csv',1,0);
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
%第二个数据中心
anothor_workload_data = csvread('day3.csv',1,0);
anothor_num_0=anothor_workload_data(:,2);
anothor_CPU_0=anothor_workload_data(:,3);
anothor_RAM_0=anothor_workload_data(:,4);
anothor_num_1=anothor_workload_data(:,5);
anothor_CPU_1=anothor_workload_data(:,6);
anothor_RAM_1=anothor_workload_data(:,7);
anothor_num_2=anothor_workload_data(:,8);
anothor_CPU_2=anothor_workload_data(:,9);
anothor_RAM_2=anothor_workload_data(:,10);
anothor_CPU=anothor_workload_data(:,11);
anothor_RAM=anothor_workload_data(:,12);
anothor_POWER=anothor_workload_data(:,13);



%% pv power
%假设两个数据中心除了负载以外都相同
PVpower_data = xlsread('PV_power.xlsx','A2:B97');
PV_power=PVpower_data(:,2);
anothor_PV_power=PVpower_data(:,2);
PV_MAX=1000; %光伏最大功率为1000kw
%% price
%price_list=csvread('my_LMP_spline.csv',1,0);
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
anothor_P_DC_0=(a*anothor_CPU+b)*N/1000+P_b;
anothor_COST_0=anothor_price*anothor_P_DC_0;

%% 创建决策变量
x_0 = sdpvar(1,96);
x_1 = sdpvar(1,96);
x_2 = sdpvar(1,96);
Pch = sdpvar(1,96);
Pdch = sdpvar(1,96);
ch = binvar(1,96);
dch = binvar(1,96);

anothor_x_0 = sdpvar(1,96);
anothor_x_1 = sdpvar(1,96);
anothor_x_2 = sdpvar(1,96);
anothor_Pch = sdpvar(1,96);
anothor_Pdch = sdpvar(1,96);
anothor_ch = binvar(1,96);
anothor_dch = binvar(1,96);

%% 添加约束条件
%cpu使用率
CPU_usage=sdpvar(1,96);
anothor_CPU_usage=sdpvar(1,96);
for i=1:96
    CPU_usage(i)=x_0(i)+x_1(i)+x_2(i);
end
for i=1:96
    anothor_CPU_usage(i)=anothor_x_0(i)+anothor_x_1(i)+anothor_x_2(i);
end
%负载需求约束
P_DC=(a*CPU_usage+b)*N/1000+P_b;
anothor_P_DC=(a*anothor_CPU_usage+b)*N/1000+P_b;

%储能装置约束
n_g2b=0.95;
n_b2g=1/0.95;
P_ch_MAX=500;
P_dch_MAX=500;
Cap_battery=1500;

E_battery=sdpvar(1,96);
anothor_E_battery=sdpvar(1,96);
%光伏出力约束
PV_power=PV_power*PV_MAX;
anothor_PV_power=anothor_PV_power*PV_MAX;
%电网购电约束
P_grid=P_DC+Pch-Pdch-PV_power';
anothor_P_grid=anothor_P_DC+anothor_Pch-anothor_Pdch-anothor_PV_power';
%决策变量约束
constraints=[
    x_0>=0;
    x_1>=0;
    x_2>=0;    
    sum(x_0)==sum(CPU_0);
    sum(x_1)==sum(CPU_1);
    CPU_usage<=MAX_CPU;% 安全运行cpu利用率限制
    CPU_usage>=MIN_CPU;

    anothor_x_0>=0;
    anothor_x_1>=0;
    anothor_x_2>=0;
    sum(anothor_x_0)==sum(anothor_CPU_0);
    sum(anothor_x_1)==sum(anothor_CPU_1);
    anothor_CPU_usage<=MAX_CPU;% 安全运行cpu利用率限制
    anothor_CPU_usage>=MIN_CPU;

    %储能装置约束
    E_battery(1)==n_g2b*Pch(1)/4-n_b2g*Pdch(1)/4;
    E_battery(2:96)==E_battery(1:95)+n_g2b*Pch(2:96)/4-n_b2g*Pdch(2:96)/4;
    Pch>=0;
    Pch<=P_ch_MAX*ch;
    Pdch>=0;
    Pdch<=P_dch_MAX*dch;
    ch+dch<=1;
    E_battery+n_g2b*Pch/4<=Cap_battery;
    n_b2g*Pdch/4<=E_battery;

    anothor_E_battery(1)==n_g2b*anothor_Pch(1)/4-n_b2g*anothor_Pdch(1)/4;
    anothor_E_battery(2:96)==anothor_E_battery(1:95)+n_g2b*anothor_Pch(2:96)/4-n_b2g*anothor_Pdch(2:96)/4;
    anothor_Pch>=0;
    anothor_Pch<=P_ch_MAX*anothor_ch;
    anothor_Pdch>=0;
    anothor_Pdch<=P_dch_MAX*anothor_dch;
    anothor_ch+anothor_dch<=1;
    anothor_E_battery+n_g2b*anothor_Pch/4<=Cap_battery;
    n_b2g*anothor_Pdch/4<=anothor_E_battery;

    %电网约束
    P_grid>=0;
    anothor_P_grid>=0;

];
for i=1:96
        cns=[
            sum(x_0(1:i))<=sum(CPU_0(1:i));
            sum(x_0(1:i))>=sum(CPU_0(1:i))*MIN_PCT_0;
            sum(x_1(1:i))<=sum(CPU_1(1:i));
            sum(x_1(1:i))>=sum(CPU_1(1:i))*MIN_PCT_1;
            CPU_usage(i)>=0.5*CPU(i)%?

            sum(anothor_x_0(1:i))<=sum(anothor_CPU_0(1:i));
            sum(anothor_x_0(1:i))>=sum(anothor_CPU_0(1:i))*MIN_PCT_0;
            sum(anothor_x_1(1:i))<=sum(anothor_CPU_1(1:i));
            sum(anothor_x_1(1:i))>=sum(anothor_CPU_1(1:i))*MIN_PCT_1;
            anothor_CPU_usage(i)>=0.5*anothor_CPU(i)%一点trick，别问为什么
            
            anothor_x_2(i)+x_2(i)==anothor_CPU_2(i)+CPU_2(i);
            ];
        constraints=[constraints,cns];
end

%目标函数
COST=price*P_grid';
anothor_COST=anothor_price*anothor_P_grid';
total_cost=COST+anothor_COST;
ops = sdpsettings('verbose',0,'solver','lpsolve');
reuslt = optimize(constraints,total_cost);
if reuslt.problem == 0 % problem =0 代表求解成功
    disp('找到最优解');
    %disp(value(anothor_P_grid))
    %disp(value(COST)) 
    %disp(value(anothor_COST))
else
    disp('求解出错');
end

CPU_after=value(CPU_usage);
disp('数据中心1节约成本')
disp(COST_0-value(COST))
disp(1-value(COST)/COST_0);
disp('数据中心2节约成本')
disp(anothor_COST_0-value(anothor_COST))
disp(1-value(anothor_COST)/anothor_COST_0);
disp('总计节约成本')
disp(1-(value(anothor_COST)+value(COST))/(anothor_COST_0+COST_0))

%% 可视化
x = 0.25:0.25:24; %定义x的范围，第二个参数表示步长
figure(1) %建立一个幕布
subplot(2,2,2)
hold on
grid on
box on
%title({'优化前后数据中心2的功率','单位：kW'}); 
plot(x,anothor_P_DC_0','LineWidth',1) %绘制当前二维平面图
plot(x,value(anothor_P_DC),'LineWidth',1)
plot(x,value(anothor_P_DC)-value(anothor_P_grid),'LineWidth',1)
plot(x,value(anothor_P_grid),'LineWidth',1)
h1=legend({'优化前数据中心总能耗','数据中心总能耗', '分布式光伏与储能供电功率','电网供电功率'},'Location','NorthOutside');  
%set(h1,'Orientation','horizon')
ylabel('优化前后数据中心2的功率 单位：kW')
set(gca,'XLim',[0 24]);
subplot(2,2,4)
hold on
grid on
box on
%title({'节点电价2','单位：元/千瓦时'}); 
plot(x,anothor_price*4,'LineWidth',1)
ylabel('节点电价2 单位：元/千瓦时')
set(gca,'XLim',[0 24]);

subplot(2,2,1)
hold on
grid on
box on
%title({'优化前后数据中心1的功率','单位：kW'}); 
plot(x,P_DC_0,'LineWidth',1)
plot(x,value(P_DC),'LineWidth',1)
plot(x,value(P_DC)-value(P_grid),'LineWidth',1)
plot(x,value(P_grid),'LineWidth',1)
h2=legend({'优化前数据中心总能耗','数据中心总能耗', '分布式光伏与储能供电功率','电网供电功率'},'Location','NorthOutside');  
%set(h2,'Orientation','horizon')
ylabel('优化前后数据中心1的功率 单位：kW')
set(gca,'XLim',[0 24]);
subplot(2,2,3)
hold on
grid on
box on
%title({'节点电价1','单位：元/千瓦时'}); 
plot(x,price*4,'LineWidth',1)
ylabel('节点电价1 单位：元/千瓦时')
set(gca,'XLim',[0 24]);

figure(2)
subplot(3,1,1)
hold on
grid on
box on
%title({'优化前后数据中心1的在线负载'}); 
yyaxis left;
plot(x,CPU_2,'LineWidth',1)
plot(x,value(x_2),'LineWidth',1)
yyaxis right;
plot(x,price*4,'LineWidth',1)
h3=legend({'优化前','优化后', '节点电价'},'Location','NorthOutside'); 
set(h3,'Orientation','horizon')
set(gca,'XLim',[0 24]);

subplot(3,1,2)
hold on
grid on
box on
%title({'优化前后数据中心2的在线负载'}); 
yyaxis left;
plot(x,anothor_CPU_2,'LineWidth',1)
plot(x,value(anothor_x_2),'LineWidth',1)
yyaxis right;
plot(x,anothor_price*4,'LineWidth',1)
h4=legend({'优化前','优化后', '节点电价'},'Location','NorthOutside'); 
set(h4,'Orientation','horizon')
set(gca,'XLim',[0 24]);

subplot(3,1,3)
hold on
grid on
box on
title({'节点电价 元/千瓦时'}); 
plot(x,price*4,'LineWidth',1)
plot(x,anothor_price*4,'LineWidth',1)
h5=legend('price_1', 'price_2'); 
set(h5,'Orientation','horizon')
set(gca,'XLim',[0 24]);

figure(3)
subplot(2,2,1)
hold on
grid on
box on
title({'优化前数据中心1的各类负载'}); 
y=zeros(96,3);
y(:,1)=CPU_0;
y(:,2)=CPU_1;
y(:,3)=CPU_2;
%bar(x,y, 'stacked'); 
area(x,y)
legend({'CPU_0','CPU_1', 'CPU_2'},'Location','NorthEastOutside')
set(gca,'XLim',[0 24]);
subplot(2,2,3)
hold on
grid on
box on
title({'优化后数据中心1的各类负载'}); 
y(:,1)=value(x_0);
y(:,2)=value(x_1);
y(:,3)=value(x_2);
%bar(x,y, 'stacked'); 
area(x,y)
legend({'CPU_0','CPU_1', 'CPU_2'},'Location','NorthEastOutside')
set(gca,'XLim',[0 24]);


subplot(2,2,2)
hold on
grid on
box on
title({'优化前数据中心2的各类负载'}); 
y=zeros(96,3);
y(:,1)=anothor_CPU_0;
y(:,2)=anothor_CPU_1;
y(:,3)=anothor_CPU_2;
%bar(y, 'stacked'); 
area(x,y)
legend({'CPU_0','CPU_1', 'CPU_2'},'Location','NorthEastOutside')
set(gca,'XLim',[0 24]);
subplot(2,2,4)
hold on
grid on
box on
title({'优化后数据中心2的各类负载'}); 
y(:,1)=value(anothor_x_0);
y(:,2)=value(anothor_x_1);
y(:,3)=value(anothor_x_2);
%bar(y, 'stacked'); 
area(x,y)
legend({'CPU_0','CPU_1', 'CPU_2'},'Location','NorthEastOutside')
set(gca,'XLim',[0 24]);




figure(4)
hold on
grid on
box on
title({'光伏出力曲线：kw'}); 
plot(x,PV_power,'LineWidth',1)
set(gca,'XLim',[0 24]);




figure(6)
hold on
grid on
box on
title({'节点电价曲线：元/千瓦时'}); 
plot(x,price_0/40)
plot(x,price_1/40)
plot(x,price_2/40)
plot(x,price_3/40)
plot(x,price_4/40)
plot(x,price_5/40)
plot(x,price_6/40)
plot(x,price_7/40)
plot(x,price_8/40)
plot(x,price_9/40)
legend('price_0','price_1', 'price_2','price_3','price_4','price_5','price_6','price_7','price_8','price_9')
%{%}