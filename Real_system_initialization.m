%Checked

%����������΢������ϸ��+���壩��״̬�������ɣ�������Initialization��������
%΢��������
% global M D T_DG T_RES 
% global Deta_T  N_DR DR_AGG_number

    %%
    %ʵ��ϵͳ��ʼ��    
    %x=Ac*x+Bc*u;
    %y=Cc*x;
    
    %���ϵͳģ�����
    M_real=M*(1+Model_error*randn);
    D_real=D*(1+Model_error*randn);
    T_DG_real=T_DG*(1+Model_error*randn); %DG time constant
    T_RES_real=T_RES*(1+Model_error*randn); %RES time constant
    T_ESS_real=T_ESS*(1+Model_error*randn); %ESS time constant

    % T_DR_type1=DR_indivitual_feature_within_Agg_type1(:,1);
    % % T_DR_all=[T_DR_type1;T_DR_type2;T_DR_type3;T_DR_type4;T_DR_type5;T_DR_type6;]; %�����������Դ�ĸ��� ���Բ���
    % T_DR_all=[T_DR_type1]; %�����������Դ�ĸ��� ���Բ���
    
    N_state_variable_real_system=1+1+1+1; %ʵ��ϵͳ����ʵ��״̬��������
    Ac_real_system=zeros(N_state_variable_real_system);
    Bc_real_system=zeros(N_state_variable_real_system,4);
    % WHY: Ϊʲôʵ��ģ���е�CD��������
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


