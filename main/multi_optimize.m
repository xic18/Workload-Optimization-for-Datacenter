close;clear

% 多站优化
%mpopt=mpoption;
%rundcopf('case24_ieee_rts');
DC_num=20;
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
n_g2b=0.95;
n_b2g=1/0.95;
P_ch_MAX=500;
P_dch_MAX=500;
Cap_battery=1500;
PV_MAX=1000; %光伏最大功率为1000kw

%% 数据读入
DC=load_dataset();

%% 添加约束条件
%cpu使用率
for j=1:DC_num
    DC(j).CPU_usage=sdpvar(1,96);

    for i=1:96
        DC(j).CPU_usage(i)=DC(j).x_0(i)+DC(j).x_1(i)+DC(j).x_2(i);
    end
end
%负载需求约束
for j=1:DC_num
    DC(j).P_DC=(a*DC(j).CPU_usage+b)*N/1000+P_b;
end
%储能装置约束
for j=1:DC_num
    DC(j).E_battery=sdpvar(1,96);
end
%光伏出力约束
for j=1:DC_num
    DC(j).PV_power=DC(j).PV_power*PV_MAX;
end
%电网购电约束
for j=1:DC_num
    DC(j).P_grid=DC(j).P_DC+DC(j).Pch-DC(j).Pdch-DC(j).PV_power';
end

%决策变量约束
constraints=[];
for j=1:DC_num
    cns=[
        DC(j).x_0>=0;
        DC(j).x_1>=0;
        DC(j).x_2>=0;    
        sum(DC(j).x_0)==sum(DC(j).CPU_0);
        sum(DC(j).x_1)==sum(DC(j).CPU_1);
        DC(j).CPU_usage<=MAX_CPU;% 安全运行cpu利用率限制
        DC(j).CPU_usage>=MIN_CPU;

        %储能装置约束
        DC(j).E_battery(1)==n_g2b*DC(j).Pch(1)/4-n_b2g*DC(j).Pdch(1)/4;
        DC(j).E_battery(2:96)==DC(j).E_battery(1:95)+n_g2b*DC(j).Pch(2:96)/4-n_b2g*DC(j).Pdch(2:96)/4;
        DC(j).Pch>=0;
        DC(j).Pch<=P_ch_MAX*DC(j).ch;
        DC(j).Pdch>=0;
        DC(j).Pdch<=P_dch_MAX*DC(j).dch;
        DC(j).ch+DC(j).dch<=1;
        DC(j).E_battery+n_g2b*DC(j).Pch/4<=Cap_battery;
        n_b2g*DC(j).Pdch/4<=DC(j).E_battery;

        %电网约束
        DC(j).P_grid>=0;
       
        ];
    constraints=[constraints,cns];

    for i=1:96
            cns=[
                sum(DC(j).x_0(1:i))<=sum(DC(j).CPU_0(1:i));
                sum(DC(j).x_0(1:i))>=sum(DC(j).CPU_0(1:i))*MIN_PCT_0;
                sum(DC(j).x_1(1:i))<=sum(DC(j).CPU_1(1:i));
                sum(DC(j).x_1(1:i))>=sum(DC(j).CPU_1(1:i))*MIN_PCT_1;
                DC(j).CPU_usage(i)>=0.5*DC(j).CPU(i)%一点trick，别问为什么                              
                ];
            constraints=[constraints,cns];
    end

end
for i=1:96
    sum_x2=0;
    sum_cpu2=0;
    for j=1:DC_num
        sum_x2=sum_x2+DC(j).x_2(i);
        sum_cpu2=sum_cpu2+DC(j).CPU_2(i);
    end
    cns=[sum_x2==sum_cpu2];
    constraints=[constraints,cns];
end

%目标函数
total_cost=0;
for j=1:DC_num
    DC(j).COST=DC(j).price*DC(j).P_grid';
    total_cost=total_cost+DC(j).COST;
end

ops = sdpsettings('verbose',0,'solver','lpsolve');
reuslt = optimize(constraints,total_cost);
if reuslt.problem == 0 % problem =0 代表求解成功
    disp('找到最优解');
else
    disp('求解出错');
end


disp('-------------------------优化结果--------------------------')
before=0;
after=0;
for j=1:DC_num
    disp(j)
    disp(DC(j).COST_0-value(DC(j).COST))
    disp(1-value(DC(j).COST)/DC(j).COST_0);
    before=before+DC(j).COST_0;
    after=after+value(DC(j).COST);
end
disp('总计节约成本')
disp(1-after/before)


%% 可视化
figure(1)

hold on
grid on
box on
title({'优化前后成本变化/元'}); 
y=zeros(DC_num,2);
for i=1:DC_num
    y(i,1)=value(DC(i).COST);
    y(i,2)=DC(i).COST_0;
end
bar(y); 
legend('after','before')


figure(2)
x = 0.25:0.25:24;
subplot(2,1,1)
hold on
grid on
box on
title({'优化前CPU占用'});
y=zeros(96,DC_num);
for i=1:DC_num
    y(:,i)=value(DC(i).CPU)/DC_num;
end
area(x,y)
legend('DC_1','DC_2','DC_3','DC_4','DC_5','DC_6','DC_7','DC_8','DC_9','DC_{10}','DC_{11}','DC_{12}','DC_{13}','DC_{14}','DC_{15}','DC_{16}','DC_{17}','DC_{18}','DC_{19}','DC_{20}')
set(gca,'XLim',[0 24]);
subplot(2,1,2)
hold on
grid on
box on
title({'优化后CPU占用'});
y=zeros(96,DC_num);
for i=1:DC_num
    y(:,i)=value(DC(i).CPU_usage)/DC_num;
end
area(x,y)
legend('DC_1','DC_2','DC_3','DC_4','DC_5','DC_6','DC_7','DC_8','DC_9','DC_{10}','DC_{11}','DC_{12}','DC_{13}','DC_{14}','DC_{15}','DC_{16}','DC_{17}','DC_{18}','DC_{19}','DC_{20}')
set(gca,'XLim',[0 24]);

figure(3)
x = 0.25:0.25:24;
subplot(2,1,1)
hold on
grid on
box on
title({'优化前功率/kw'});
y=zeros(96,DC_num);
for i=1:DC_num
    y(:,i)=value(DC(i).P_DC_0);
end
area(x,y)
legend('DC_1','DC_2','DC_3','DC_4','DC_5','DC_6','DC_7','DC_8','DC_9','DC_{10}','DC_{11}','DC_{12}','DC_{13}','DC_{14}','DC_{15}','DC_{16}','DC_{17}','DC_{18}','DC_{19}','DC_{20}')
set(gca,'XLim',[0 24]);
subplot(2,1,2)
hold on
grid on
box on
title({'优化后功率/kw'});
y=zeros(96,DC_num);
for i=1:DC_num
    y(:,i)=value(DC(i).P_DC);
end
area(x,y)
legend('DC_1','DC_2','DC_3','DC_4','DC_5','DC_6','DC_7','DC_8','DC_9','DC_{10}','DC_{11}','DC_{12}','DC_{13}','DC_{14}','DC_{15}','DC_{16}','DC_{17}','DC_{18}','DC_{19}','DC_{20}')
set(gca,'XLim',[0 24]);
