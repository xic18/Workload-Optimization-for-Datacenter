close;clear

%[x,fval]=intlinprog(f,intcon,A,b,Aeq,beq,lb,ub);

%模型还是采用了松弛一些的条件，试图更好地利用数据中心灵活性
%模型 适用于单节点系统 系统负载调度+分布式pv+储能,且使用相对连续的节点电价
%% MAX
MAX_CPU=0.8;
MIN_CPU=0.1;
MIN_PCT_0=0.2;
MIN_PCT_1=0.5;
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
%% pv power
PVpower_data = xlsread('PV_power.xlsx','A2:B97');
PV_power=PVpower_data(:,2);
PV_MAX=1000; %光伏最大功率为1000kw
%% price
%{
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

price=price_9;
price=price'/200;
%}


price=ones(1,96);
price(1:28)=0.37/4;
price(29:40)=0.8/4;
price(41:60)=1.37/4;
price(61:72)=0.8/4;
price(73:84)=1.37/4;
price(85:92)=0.8/4;
price(93:96)=0.37/4;

%%不进行优化
P_DC_0=(a*CPU+b)*N/1000+P_b;
COST_0=price*P_DC_0;

%% 创建决策变量
x_0 = sdpvar(1,96);
x_2 = sdpvar(1,96);
x_1 = sdpvar(1,96);
%x_2 = sdpvar(1,96);
Pch = sdpvar(1,96);
Pdch = sdpvar(1,96);
ch = binvar(1,96);
dch = binvar(1,96);

%% 添加约束条件
%cpu使用率
for i=1:96
    CPU_usage(i)=x_0(i)+x_1(i)+x_2(i);
end
%负载需求约束
P_DC=(a*CPU_usage+b)*N/1000+P_b;

%储能装置约束
n_g2b=0.95;
n_b2g=1/0.95;
P_ch_MAX=500;
P_dch_MAX=500;
Cap_battery=1500;

E_battery=sdpvar(1,96);

%光伏出力约束
PV_power=PV_power*PV_MAX;

%电网购电约束
P_grid=P_DC+Pch-Pdch-PV_power';

%决策变量约束
constraints=[
    x_0>=0;
    
    %x_0+x_1+x_2<=0.9;
    x_1>=0;
    sum(x_0)==sum(CPU_0);
    sum(x_1)==sum(CPU_1);
    CPU_usage<=MAX_CPU;% 安全运行cpu利用率限制
    CPU_usage>=MIN_CPU;

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

];

for i=1:96
        cns=[
            sum(x_0(1:i))<=sum(CPU_0(1:i));
            sum(x_0(1:i))>=sum(CPU_0(1:i))*MIN_PCT_0;
            sum(x_1(1:i))<=sum(CPU_1(1:i));
            sum(x_1(1:i))>=sum(CPU_1(1:i))*MIN_PCT_1;
            x_2(i)==CPU_2(i);
            %CPU_usage(i)>=0.5*CPU(i)

            ];
        constraints=[constraints,cns];
        
end

%目标函数
COST=price*P_grid';

ops = sdpsettings('verbose',0,'solver','lpsolve');
reuslt = optimize(constraints,COST);
disp("优化前成本/能耗")
disp(COST_0)
disp(sum(P_DC_0)/4)
if reuslt.problem == 0 % problem =0 代表求解成功
    disp("优化后成本/能耗") 
    disp(value(COST)) 
    disp(sum(value(P_grid))/4)
    
else
    disp('求解出错');
end
CPU_after=value(CPU_usage);
disp(1-value(COST)/COST_0);
disp("共减少")
disp(COST_0-value(COST))

loss_total=zeros(1,97);
loss=zeros(1,96);
for i=1:96
    loss(i)=sum(CPU_0(1:i))-sum(x_0(1:i))+sum(CPU_1(1:i))-sum(x_1(1:i));
    loss_total(i+1)=loss_total(i)+loss(i);
%loss(i+1)=loss(i)+CPU_0(i)-x_0(i)+CPU_1(i)-x_1(i);
end

disp(loss_total)
%% 可视化
x = 0.25:0.25:24; %定义x的范围，第二个参数表示步长
figure(1) %建立一个幕布
subplot(2,1,1)
hold on
grid on
box on
%title({'优化前后数据中心负载分布'}); 
plot(x,CPU',x,CPU_after,'LineWidth',1) %绘制当前二维平面图
h=legend({'优化前CPU利用率','优化后CPU利用率'},'Location','NorthOutside'); 
set(h,'Orientation','horizon')
set(gca,'XLim',[0 24]);
xlabel('时间（h）')
ylabel('CPU利用率')
subplot(2,1,2)
hold on
grid on
box on
title({'节点电价(单位：元/千瓦时)'});
plot(x,price*4,'LineWidth',1)
set(gca,'XLim',[0 24]);

figure(2)
subplot(2,1,1)
hold on
grid on
box on
%title('性能损失每15min增量(单位：h)')
plot(x,loss/4/2,'LineWidth',1)
set(gca,'XLim',[0 24]);
xlabel('时间（h）')
ylabel('单位：%')
subplot(2,1,2)
hold on
grid on
box on
%title('性能总损失(单位：h)')
plot(x,loss_total(2:97)/4/2,'LineWidth',1)
set(gca,'XLim',[0 24]);
xlabel('时间（h）')
ylabel('单位：%')
figure(3)
subplot(2,1,1)
hold on
grid on
box on
%title({'优化前后数据中心的功率','单位：kw'});
plot(x,P_DC_0,'LineWidth',1)
plot(x,value(P_DC),'LineWidth',1)
plot(x,value(P_DC)-value(P_grid),'LineWidth',1)
plot(x,value(P_grid),'LineWidth',1)
h1=legend({'优化前数据中心总能耗','数据中心总能耗', '分布式光伏与储能供电功率','电网供电功率'},'Location','NorthOutside'); 
set(h1,'Orientation','horizon')
set(gca,'XLim',[0 24]);
xlabel('时间（h）')
ylabel('功率 单位：kW')
subplot(2,1,2)
hold on
grid on
box on
%title({'节点电价(单位：元/千瓦时)'});
plot(x,price*4,'LineWidth',1)
xlabel('时间（h）')

