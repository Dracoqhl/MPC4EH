%checked

%%
%扰动变量收入（包括光伏光照强度、负荷波动）
global deta_solar_clock deta_P_load_clock  %光伏/负荷预测变量
global deta_solar_random_clock deta_P_load_random_clock  %光伏/负荷预测变量+一定的预测误差
% global Deta_T  N_DR
% global M D T_DG T_RES 
% global Frequency_deviation_overall_value Frequency_economic_overall_value Generation_economic_overall_value Regulation_economic_overall_value 
global RES_curtailment_overall_value
% global Ad Bd Cd Dd
global u_last_time_MPC_controller u0_last_time%MPC控制器中，上一个时刻的控制信号记录
global  Q_fre Q_DG Q_RES Q_ESS r_fre r_DG r_RES r_ESS Beita_DG Beita_RES Beita_ESS
global  Fre_regulation_mode %频率控制模式选择 =0：仅考虑调频偏差；=1：调频偏差+发电成本；=2调频偏差+发电成本+里程成本
% global u_DG_up_max_value u_DG_down_max_value 
% global Disaggregation_method_flag
% global Q_fre_reference Q_DG_reference r_DG_reference Q_RES_reference r_RES_reference Beita_DG_referenece Beita_RES_reference
% global Regulation_cost_coefficient Operation_cost_coefficient
global RES_operation_mode 
global Computational_time %记录每次MPC优化程序的计算时间
global EXITFLAG_variation Static_vary %看一下有没有infeasible的问题
global P_ESS_up P_ESS_down P_DG_up P_DG_down
global N_step Deta_T

    N_step=5;%MPC的控制时间步长

    Operation_cost_coefficient=1;       %运行成本折算系数
    Regulation_cost_coefficient=1;    %调频成本折算系数    
    Static_vary=1;
    Deta_T=0.5; %MPC的控制步长,0.05s是和设置的光伏/负荷数据相匹配的

    %标志位
    Disaggregation_method_flag=1; %解聚合方法：=1直接分配法；=其他：经济运行法
    Fre_regulation_mode=2; % =0仅考虑调频偏差;=1调频偏差+发电成本;=2调频偏差+发电成本+里程成本
    RES_operation_mode=1;  %=1：工作在可弃风、弃光模式；=其他：工作之MPPT模式

%调频资源经济参数初始化
    Q_fre_reference=500;

%% 系统参数
    M=1.8;
    D=0.15;

%% ESS参数
%EV:功率：8~20kw(TGD); 能量容量：20~60kWh(TGD); 当前能量：（0~1）能量容量(UD);  
%HVAC:功率：2~5kw(TGD); 温度范围：20~25℃; 当前温度： 20~25℃(UD);
%ESS 功率：20~50kw(TGD);  能量容量：50~100kWh(TGD); 当前能量：（0~1）能量容量(UD); 
% 成本、惯性信息
%下面是资源的平均信息，可以通过调整它们来批量修改资源的惯性常数、运行成本、里程成本
% average_T=0.55; %单位s
% average_b=0.0015; %$MWh
% average_Beita=0.2; %$MWh
global P_ESS_current E_ESS_current
    P_ESS_max = 2;
    P_ESS_min = 0;
    E_ESS_max = 1000;
    E_ESS_min = 0; 
    P_ESS_current=1;
    E_ESS_current = 300;
    %有功出力范围(调频上下限)
    Deta_T_rate=Deta_T*1/3600;%每个时间段在1h中占据的比例
    P_ESS_up = (P_ESS_max - P_ESS_current);
    P_ESS_down = -(P_ESS_current - P_ESS_min);

    % P_ESS_up = min((P_ESS_max - P_ESS_current),((E_ESS_current-E_ESS_min)/Deta_T_rate));
    % P_ESS_down = -min((P_ESS_current - P_ESS_min),((E_ESS_max-E_ESS_current)/Deta_T_rate));
    % P_ESS_up = min((P_ESS_max - P_ESS_current),(E_ESS_max-E_ESS_current))/Deta_T;
    % P_ESS_down = -min((P_ESS_current - P_ESS_min),(E_ESS_current-E_ESS_min))/Deta_T;
    %惯性常数，运行成本
    T_ESS = 0.55; %单位s
    b_ESS=0.0015; %$MWh
    
    % %将资源出力范围由kW转换成MW单位：
    % P_ESS_up=P_ESS_up/1000;
    % P_ESS_down=P_ESS_down/1000;
    % 运行成本（没有二次项）
    Q_ESS_reference = 0;
    r_ESS_reference = Operation_cost_coefficient*b_ESS*Deta_T/3600;
    % 调频成本
    Beita_ESS_reference = 0.2; %$MWh

 %% DG 参数

    T_DG=0.7; %DG time constant 
    %发电机资源的成本常数：
    a_DG=2.7;   %$/MWh^2
    b_DG=60;    %$/MWh
    P_DG_dispatching_reference=3.5; %MW

    Q_DG_reference=Operation_cost_coefficient*a_DG*Deta_T/3600;                                       %转换到一个仿真周期里的运行成本
    r_DG_reference=Operation_cost_coefficient*(2*a_DG*P_DG_dispatching_reference+b_DG)*Deta_T/3600;   %转换到一个仿真周期里的运行成本
    Beita_DG_referenece=0.2;  %单位里程的调频成本

    P_DG_up=1.5;                        %DG出力上限
    P_DG_down=-2.5;                     %DG出力下限

%% RES 参数
    T_RES=0.35; %RES time constant
    Gama_RES=0.5;   %$/MWh
    Rou_RES=0.1;  %p.u.  弃风惩罚权重
    P_RES_MAX_reference=3;  %MW
    Q_RES_reference=Operation_cost_coefficient*(Rou_RES/P_RES_MAX_reference)/3600;  %转换到一个仿真周期里的运行成本
    r_RES_reference=Operation_cost_coefficient*(Gama_RES-2*Rou_RES)/3600;           %转换到一个仿真周期里的运行成本
    
    Beita_RES_reference=0.00; %单位里程的调频成本 :这个参数在论文里设置为0，如果它调大一些，一些AGG调频控制器的动作也就更加频繁了。
        
%% 
    Fre_regulation_mode; % =0仅考虑调频偏差;=1调频偏差+发电成本;=2调频偏差+发电成本+里程成本
    
    if Fre_regulation_mode==0  %仅考虑调频偏差
        
    Q_fre=Q_fre_reference; %频率对应的二次项系数
    Q_DG=0;  %DG对应的二次项系数
    Q_RES=0;   %RES对应的二次项系数
    Q_ESS=0;  %ESS 对应的二次项系数
    
    r_fre=0; %频率对应的一次项系数
    r_DG=0;  %DG对应的一次项系数
    r_RES=-0.0;   %RES对应的一次项系数
    r_ESS=0.0;  %ESS 对应的一次项系数    
    
    Beita_DG=0.0; %DG对应的单位调频里程成本
    Beita_RES=0.0; %RES对应的单位调频里程成本
    Beita_AGG(1)=0.0; %AGG1对应的单位调频里程成本
    
    elseif Fre_regulation_mode==1 %调频偏差+发电成本
        
    Q_fre=Q_fre_reference; %频率对应的二次项系数
    Q_DG=Q_DG_reference;  %DG对应的二次项系数
    Q_RES=Q_RES_reference;   %RES对应的二次项系数
    Q_ESS=0;  %AGG 1 对应的二次项系数
    
    
    r_fre=0; %频率对应的一次项系数
    r_DG=r_DG_reference;  %DG对应的一次项系数
    r_RES=r_RES_reference;   %RES对应的一次项系数
    r_ESS=r_ESS_reference;  %AGG 1 对应的一次项系数   
    
    Beita_DG=0.0; %DG对应的单位调频里程成本
    Beita_RES=0.0; %RES对应的单位调频里程成本
    Beita_AGG(1)=0.0; %AGG1对应的单位调频里程成本
    
    else  %调频偏差+发电成本+里程成本
    %资源成本
    Q_fre=Q_fre_reference; %频率对应的二次项系数
    Q_DG=Q_DG_reference;  %DG对应的二次项系数
    Q_RES=Q_RES_reference;   %RES对应的二次项系数
    Q_ESS=0;  %AGG 1 对应的二次项系数
    
    r_fre=0; %频率对应的一次项系数
    r_DG=r_DG_reference;  %DG对应的一次项系数
    r_RES=r_RES_reference;   %RES对应的一次项系数
    r_ESS=r_ESS_reference;  %AGG 1 对应的一次项系数   
    
    Beita_DG=Beita_DG_referenece; %DG对应的单位调频里程成本
    Beita_RES=Beita_RES_reference; %RES对应的单位调频里程成本
    Beita_ESS=Beita_ESS_reference; %AGG1对应的单位调频里程成本
    
    end     
    

    

    
    
%%
%新能源+负荷预测出力和实际出力信息

Error_rate_RES=0.05;     %预测值与实际值误差均值所占比例, ！！！！！！注意：这个参数对系统稳态频率的波动影响很大，如果设置未0，频率几乎稳定在0处。
Error_rate_Load=0.02;
RES_volatility=0.1;  %新能源预测波动性比例

% % % %   可以利用函数生成负荷和新能源，也可以读取
% % %     run RES_load_forecast_initialization;  %生成新能源+负荷预测出力和实际出力信息
    
    load('deta_solar_clock');
    load('deta_solar_random_clock');
    load('deta_P_load_clock');
    load('deta_P_load_random_clock');
    
    deta_solar_clock;           %MPC控制器 新能源预测值
    deta_solar_random_clock;    %系统 新能源实际值
    deta_P_load_clock;          %MPC控制器 负荷预测值
    deta_P_load_random_clock;   %系统 负荷实际值
    
    
%%
%MPC控制器参数初始化
    run MPC_controller_initialization;    
%%
%微电网状态方程初始化
    Model_error=0.0;%MPC中模型预测误差 ！！！！！！注意：这个参数对系统稳态频率的影响很小，几乎为0
    %实际系统初始化    
    run Real_system_initialization;
    global Frequency_deviation_overall_value Frequency_economic_overall_value Generation_economic_overall_value Regulation_economic_overall_value 
    

    %经济性统计
    Frequency_deviation_overall_value=0; %当前时刻的频率偏差统计
    Frequency_economic_overall_value=0; %当前时刻的频率偏差成本
    Generation_economic_overall_value=0; %当前时刻的发电运行成本
    Regulation_economic_overall_value=0; %当前时刻的调频里程成本
    RES_curtailment_overall_value=0; %RES curtailment量
    % 
    % %Overall_cost=Generation_economic_overall_value + Regulation_economic_overall_value;
    % AGG_regulation_mileage=zeros(6,1);  %记录每个聚合器的调频里程
    % 
    u0_last_time=zeros(3,1);  %这里可能应该是一个加+号，
    u_last_time_MPC_controller=[0;0;0];
    
    
