%Checked

%��������������ϵͳ�����о�����
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
sizes.NumInputs      = 7; %5��״̬������������������1-5Ϊϵͳ��ǰ�����״̬������6-9Ϊ��ǰ�Ŀ��Ʊ���
sizes.DirFeedthrough = 1; %����u��mdlOutputs �б����ʣ������ֱ����ͨ
sizes.NumSampleTimes = 1;
sys = simsizes(sizes); 
x0 =zeros(7,1);   %���������ʼʱ�̵�һ����ʼ����t=0ʱ�̡�������x0��ʼ������ʵ����ʹ���������u����Ҫ�����u���Ǵ�����������������

% U=[0;0;0;0]; %�����źŵĳ�ֵ
% Initialize the discrete states.
str = [];             % Set str to an empty matrix.
ts  = [Deta_T 0];       % sample time: [period, offset],��������������
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
    
    x0_sample=u(1:3+1);%ϵͳ��ǰ״̬�����롣
    u0_sample=u(3+1+1:3+1+2+1);%ϵͳ��ǰ�����ź����롣
    
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
    
    Frequency_economic_value=0; %��ǰʱ�̵�Ƶ��ƫ��ɱ�
    Generation_economic_value=0; %��ǰʱ�̵ķ������гɱ�
    Regulation_economic_value=0; %��ǰʱ�̵ĵ�Ƶ��̳ɱ�
    
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