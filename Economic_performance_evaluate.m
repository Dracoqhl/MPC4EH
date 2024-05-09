%Checked

%本函数用于评估系统的运行经济性
function [sys,x0,str,ts] = controller(t,x,u,flag)

switch flag,
 case 0
  [sys,x0,str,ts] = mdlInitializeSizes; % Initialization
 case 2
  sys = mdlUpdates(t,x,u); % Update discrete states
 case 3
  sys = mdlOutputs(t,x,u); % Calculate outputs
 case {1,4,9} % Unused flags
  sys = [];
 otherwise
  error(['unhandled flag = ',num2str(flag)]); % Error handling
end

%==============================================================
% Initialization
%==============================================================
function [sys,x0,str,ts] = mdlInitializeSizes
global Ad Bd Cd Dd Deta_T

sizes = simsizes;
sizes.NumContStates  = 0;
sizes.NumDiscStates  = 7;
sizes.NumOutputs     = 4; %
sizes.NumInputs      = 7; %5个状态变量和两个干扰量：1-5为系统当前输入的状态变量，6-9为当前的控制变量
sizes.DirFeedthrough = 1; %输入u在mdlOutputs 中被访问，则存在直接馈通
sizes.NumSampleTimes = 1;
sys = simsizes(sizes); 
x0 =zeros(7,1);   %这里是最初始时刻的一个初始化，t=0时刻。后续的x0初始化，其实可以使用输入变量u（主要这里的u就是从外界来的输入变量）

% U=[0;0;0;0]; %控制信号的初值
% Initialize the discrete states.
str = [];             % Set str to an empty matrix.
ts  = [Deta_T 0];       % sample time: [period, offset],按照连结块的速率
%End of mdlInitializeSizes
%==============================================================
% Update the discrete states
%==============================================================
 function sys = mdlUpdates(t,x,u)
  
sys = x; 
%End of mdlUpdate.
    function sys = mdlOutputs(t,x,u)
   %%
    global u0_last_time
    global Frequency_deviation_overall_value Frequency_economic_overall_value Generation_economic_overall_value Regulation_economic_overall_value    
    global DR_AGG_feature_center DR_indivitual_feature_within_Agg_type1 DR_indivitual_feature_within_Agg_type2 DR_indivitual_feature_within_Agg_type3 DR_indivitual_feature_within_Agg_type4 DR_indivitual_feature_within_Agg_type5 DR_indivitual_feature_within_Agg_type6
    global Deta_T  N_DR
    global DR_AGG_number    
    global  Q_fre Q_DG Q_RES Q_ESS r_fre r_DG r_RES r_ESS Beita_DG Beita_RES Beita_ESS
    global Regulation_cost_coefficient
    
    x0_sample=u(1:3+1);%系统当前状态的输入。
    u0_sample=u(3+1+1:3+1+2+1);%系统当前控制信号输入。
    
    f_0=x0_sample(1);
    P_DG_0=x0_sample(2);
    P_RES_0=x0_sample(3);
    P_ESS_0=x0_sample(4);

    u_DG_0=u0_sample(1)
    u_RES_0=u0_sample(2);
    u_ESS_0=u0_sample(3);
   
    u_DG_last_time=u0_last_time(1);
    u_RES_last_time=u0_last_time(2);
    u_ESS_last_time=u0_last_time(3);
    
    Frequency_economic_value=0; %当前时刻的频率偏差成本
    Generation_economic_value=0; %当前时刻的发电运行成本
    Regulation_economic_value=0; %当前时刻的调频里程成本
    
    Generation_economic_value_DG=Q_DG *( P_DG_0*P_DG_0 ) + r_DG * (P_DG_0);
    Generation_economic_value_RES= Q_RES *( P_RES_0*P_RES_0 ) + r_RES * (P_RES_0);
    Generation_economic_value_ESS = Q_ESS*(P_ESS_0*P_ESS_0) + r_ESS*P_ESS_0;
    
    Regulation_economic_value_DG=Beita_DG * abs(u_DG_0-u_DG_last_time);
    Regulation_economic_value_RES=Beita_RES * abs(u_RES_0-u_RES_last_time);  
    Regulation_economic_value_ESS=Beita_ESS * abs(u_ESS_0-u_ESS_last_time);

    Frequency_economic_value=Q_fre *( f_0*f_0) + r_fre * (f_0);
    Frequency_deviation=abs(f_0);

    Generation_economic_value= Generation_economic_value_DG+Generation_economic_value_RES+Generation_economic_value_ESS;
    Regulation_economic_value= Regulation_economic_value_DG+Regulation_economic_value_RES + Regulation_economic_value_ESS;
    
    Frequency_deviation_overall_value=Frequency_deviation_overall_value+Frequency_deviation;
    Frequency_economic_overall_value=Frequency_economic_overall_value+Frequency_economic_value;
    Generation_economic_overall_value=Generation_economic_overall_value+Generation_economic_value;
    Regulation_economic_overall_value=Regulation_economic_overall_value+Regulation_economic_value;   
     
    u0_last_time=u0_sample;
    
    sys=[Frequency_deviation Frequency_economic_value  Generation_economic_value  Regulation_economic_value];
    
% End of mdlOutputs.