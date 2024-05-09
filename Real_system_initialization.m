%Checked

%本函数用于微电网（细节+具体）的状态方程生成，必须由Initialization函数调用
%微电网参数
% global M D T_DG T_RES 
% global Deta_T  N_DR DR_AGG_number

    %%
    %实际系统初始化    
    %x=Ac*x+Bc*u;
    %y=Cc*x;
    
    %添加系统模型误差
    M_real=M*(1+Model_error*randn);
    D_real=D*(1+Model_error*randn);
    T_DG_real=T_DG*(1+Model_error*randn); %DG time constant
    T_RES_real=T_RES*(1+Model_error*randn); %RES time constant
    T_ESS_real=T_ESS*(1+Model_error*randn); %ESS time constant

    % T_DR_type1=DR_indivitual_feature_within_Agg_type1(:,1);
    % % T_DR_all=[T_DR_type1;T_DR_type2;T_DR_type3;T_DR_type4;T_DR_type5;T_DR_type6;]; %海量灵活性资源的个体 惯性参数
    % T_DR_all=[T_DR_type1]; %海量灵活性资源的个体 惯性参数
    
    N_state_variable_real_system=1+1+1+1; %实际系统中真实的状态变量个数
    Ac_real_system=zeros(N_state_variable_real_system);
    Bc_real_system=zeros(N_state_variable_real_system,4);
    % WHY: 为什么实际模型中的CD是这样的
    Cc_real_system=eye(N_state_variable_real_system);
    Dc_real_system=zeros(N_state_variable_real_system,1+1+1+1);    
    
    Ac_real_system(1,1)=-D_real/M_real;
    Ac_real_system(1,2:N_state_variable_real_system)=1/M_real;
    Ac_real_system(2,2)=-1/T_DG_real;
    Ac_real_system(3,3)=-1/T_RES_real;
    Ac_real_system(4,4)=-1/T_ESS_real;

    
    Bc_real_system(1,1+1+1+1)=-1/M_real;
    Bc_real_system(2,1)=1/T_DG_real;
    Bc_real_system(3,2)=1/T_RES_real;
    Bc_real_system(4,3)=1/T_ESS_real;


