%checked

%%
%�Ŷ��������루�����������ǿ�ȡ����ɲ�����
global deta_solar_clock deta_P_load_clock  %���/����Ԥ�����
global deta_solar_random_clock deta_P_load_random_clock  %���/����Ԥ�����+һ����Ԥ�����
% global Deta_T  N_DR
% global M D T_DG T_RES 
% global Frequency_deviation_overall_value Frequency_economic_overall_value Generation_economic_overall_value Regulation_economic_overall_value 
global RES_curtailment_overall_value
% global Ad Bd Cd Dd
global u_last_time_MPC_controller u0_last_time%MPC�������У���һ��ʱ�̵Ŀ����źż�¼
global  Q_fre Q_DG Q_RES Q_ESS r_fre r_DG r_RES r_ESS Beita_DG Beita_RES Beita_ESS
global  Fre_regulation_mode %Ƶ�ʿ���ģʽѡ�� =0�������ǵ�Ƶƫ�=1����Ƶƫ��+����ɱ���=2��Ƶƫ��+����ɱ�+��̳ɱ�
% global u_DG_up_max_value u_DG_down_max_value 
% global Disaggregation_method_flag
% global Q_fre_reference Q_DG_reference r_DG_reference Q_RES_reference r_RES_reference Beita_DG_referenece Beita_RES_reference
% global Regulation_cost_coefficient Operation_cost_coefficient
global RES_operation_mode 
global Computational_time %��¼ÿ��MPC�Ż�����ļ���ʱ��
global EXITFLAG_variation Static_vary %��һ����û��infeasible������
global P_ESS_up P_ESS_down P_DG_up P_DG_down
global N_step Deta_T

    N_step=5;%MPC�Ŀ���ʱ�䲽��

    Operation_cost_coefficient=1;       %���гɱ�����ϵ��
    Regulation_cost_coefficient=1;    %��Ƶ�ɱ�����ϵ��    
    Static_vary=1;
    Deta_T=0.5; %MPC�Ŀ��Ʋ���,0.05s�Ǻ����õĹ��/����������ƥ���

    %��־λ
    Disaggregation_method_flag=1; %��ۺϷ�����=1ֱ�ӷ��䷨��=�������������з�
    Fre_regulation_mode=2; % =0�����ǵ�Ƶƫ��;=1��Ƶƫ��+����ɱ�;=2��Ƶƫ��+����ɱ�+��̳ɱ�
    RES_operation_mode=1;  %=1�������ڿ����硢����ģʽ��=����������֮MPPTģʽ

%��Ƶ��Դ���ò�����ʼ��
    Q_fre_reference=500;

%% ϵͳ����
    M=1.8;
    D=0.15;

%% ESS����
%EV:���ʣ�8~20kw(TGD); ����������20~60kWh(TGD); ��ǰ��������0~1����������(UD);  
%HVAC:���ʣ�2~5kw(TGD); �¶ȷ�Χ��20~25��; ��ǰ�¶ȣ� 20~25��(UD);
%ESS ���ʣ�20~50kw(TGD);  ����������50~100kWh(TGD); ��ǰ��������0~1����������(UD); 
% �ɱ���������Ϣ
%��������Դ��ƽ����Ϣ������ͨ�����������������޸���Դ�Ĺ��Գ��������гɱ�����̳ɱ�
% average_T=0.55; %��λs
% average_b=0.0015; %$MWh
% average_Beita=0.2; %$MWh
global P_ESS_current E_ESS_current
    P_ESS_max = 2;
    P_ESS_min = 0;
    E_ESS_max = 1000;
    E_ESS_min = 0; 
    P_ESS_current=1;
    E_ESS_current = 300;
    %�й�������Χ(��Ƶ������)
    Deta_T_rate=Deta_T*1/3600;%ÿ��ʱ�����1h��ռ�ݵı���
    P_ESS_up = (P_ESS_max - P_ESS_current);
    P_ESS_down = -(P_ESS_current - P_ESS_min);

    % P_ESS_up = min((P_ESS_max - P_ESS_current),((E_ESS_current-E_ESS_min)/Deta_T_rate));
    % P_ESS_down = -min((P_ESS_current - P_ESS_min),((E_ESS_max-E_ESS_current)/Deta_T_rate));
    % P_ESS_up = min((P_ESS_max - P_ESS_current),(E_ESS_max-E_ESS_current))/Deta_T;
    % P_ESS_down = -min((P_ESS_current - P_ESS_min),(E_ESS_current-E_ESS_min))/Deta_T;
    %���Գ��������гɱ�
    T_ESS = 0.55; %��λs
    b_ESS=0.0015; %$MWh
    
    % %����Դ������Χ��kWת����MW��λ��
    % P_ESS_up=P_ESS_up/1000;
    % P_ESS_down=P_ESS_down/1000;
    % ���гɱ���û�ж����
    Q_ESS_reference = 0;
    r_ESS_reference = Operation_cost_coefficient*b_ESS*Deta_T/3600;
    % ��Ƶ�ɱ�
    Beita_ESS_reference = 0.2; %$MWh

 %% DG ����

    T_DG=0.7; %DG time constant 
    %�������Դ�ĳɱ�������
    a_DG=2.7;   %$/MWh^2
    b_DG=60;    %$/MWh
    P_DG_dispatching_reference=3.5; %MW

    Q_DG_reference=Operation_cost_coefficient*a_DG*Deta_T/3600;                                       %ת����һ����������������гɱ�
    r_DG_reference=Operation_cost_coefficient*(2*a_DG*P_DG_dispatching_reference+b_DG)*Deta_T/3600;   %ת����һ����������������гɱ�
    Beita_DG_referenece=0.2;  %��λ��̵ĵ�Ƶ�ɱ�

    P_DG_up=1.5;                        %DG��������
    P_DG_down=-2.5;                     %DG��������

%% RES ����
    T_RES=0.35; %RES time constant
    Gama_RES=0.5;   %$/MWh
    Rou_RES=0.1;  %p.u.  ����ͷ�Ȩ��
    P_RES_MAX_reference=3;  %MW
    Q_RES_reference=Operation_cost_coefficient*(Rou_RES/P_RES_MAX_reference)/3600;  %ת����һ����������������гɱ�
    r_RES_reference=Operation_cost_coefficient*(Gama_RES-2*Rou_RES)/3600;           %ת����һ����������������гɱ�
    
    Beita_RES_reference=0.00; %��λ��̵ĵ�Ƶ�ɱ� :�������������������Ϊ0�����������һЩ��һЩAGG��Ƶ�������Ķ���Ҳ�͸���Ƶ���ˡ�
        
%% 
    Fre_regulation_mode; % =0�����ǵ�Ƶƫ��;=1��Ƶƫ��+����ɱ�;=2��Ƶƫ��+����ɱ�+��̳ɱ�
    
    if Fre_regulation_mode==0  %�����ǵ�Ƶƫ��
        
    Q_fre=Q_fre_reference; %Ƶ�ʶ�Ӧ�Ķ�����ϵ��
    Q_DG=0;  %DG��Ӧ�Ķ�����ϵ��
    Q_RES=0;   %RES��Ӧ�Ķ�����ϵ��
    Q_ESS=0;  %ESS ��Ӧ�Ķ�����ϵ��
    
    r_fre=0; %Ƶ�ʶ�Ӧ��һ����ϵ��
    r_DG=0;  %DG��Ӧ��һ����ϵ��
    r_RES=-0.0;   %RES��Ӧ��һ����ϵ��
    r_ESS=0.0;  %ESS ��Ӧ��һ����ϵ��    
    
    Beita_DG=0.0; %DG��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    Beita_RES=0.0; %RES��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    Beita_AGG(1)=0.0; %AGG1��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    
    elseif Fre_regulation_mode==1 %��Ƶƫ��+����ɱ�
        
    Q_fre=Q_fre_reference; %Ƶ�ʶ�Ӧ�Ķ�����ϵ��
    Q_DG=Q_DG_reference;  %DG��Ӧ�Ķ�����ϵ��
    Q_RES=Q_RES_reference;   %RES��Ӧ�Ķ�����ϵ��
    Q_ESS=0;  %AGG 1 ��Ӧ�Ķ�����ϵ��
    
    
    r_fre=0; %Ƶ�ʶ�Ӧ��һ����ϵ��
    r_DG=r_DG_reference;  %DG��Ӧ��һ����ϵ��
    r_RES=r_RES_reference;   %RES��Ӧ��һ����ϵ��
    r_ESS=r_ESS_reference;  %AGG 1 ��Ӧ��һ����ϵ��   
    
    Beita_DG=0.0; %DG��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    Beita_RES=0.0; %RES��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    Beita_AGG(1)=0.0; %AGG1��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    
    else  %��Ƶƫ��+����ɱ�+��̳ɱ�
    %��Դ�ɱ�
    Q_fre=Q_fre_reference; %Ƶ�ʶ�Ӧ�Ķ�����ϵ��
    Q_DG=Q_DG_reference;  %DG��Ӧ�Ķ�����ϵ��
    Q_RES=Q_RES_reference;   %RES��Ӧ�Ķ�����ϵ��
    Q_ESS=0;  %AGG 1 ��Ӧ�Ķ�����ϵ��
    
    r_fre=0; %Ƶ�ʶ�Ӧ��һ����ϵ��
    r_DG=r_DG_reference;  %DG��Ӧ��һ����ϵ��
    r_RES=r_RES_reference;   %RES��Ӧ��һ����ϵ��
    r_ESS=r_ESS_reference;  %AGG 1 ��Ӧ��һ����ϵ��   
    
    Beita_DG=Beita_DG_referenece; %DG��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    Beita_RES=Beita_RES_reference; %RES��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    Beita_ESS=Beita_ESS_reference; %AGG1��Ӧ�ĵ�λ��Ƶ��̳ɱ�
    
    end     
    

    

    
    
%%
%����Դ+����Ԥ�������ʵ�ʳ�����Ϣ

Error_rate_RES=0.05;     %Ԥ��ֵ��ʵ��ֵ����ֵ��ռ����, ������������ע�⣺���������ϵͳ��̬Ƶ�ʵĲ���Ӱ��ܴ��������δ0��Ƶ�ʼ����ȶ���0����
Error_rate_Load=0.02;
RES_volatility=0.1;  %����ԴԤ�Ⲩ���Ա���

% % % %   �������ú������ɸ��ɺ�����Դ��Ҳ���Զ�ȡ
% % %     run RES_load_forecast_initialization;  %��������Դ+����Ԥ�������ʵ�ʳ�����Ϣ
    
    load('deta_solar_clock');
    load('deta_solar_random_clock');
    load('deta_P_load_clock');
    load('deta_P_load_random_clock');
    
    deta_solar_clock;           %MPC������ ����ԴԤ��ֵ
    deta_solar_random_clock;    %ϵͳ ����Դʵ��ֵ
    deta_P_load_clock;          %MPC������ ����Ԥ��ֵ
    deta_P_load_random_clock;   %ϵͳ ����ʵ��ֵ
    
    
%%
%MPC������������ʼ��
    run MPC_controller_initialization;    
%%
%΢����״̬���̳�ʼ��
    Model_error=0.0;%MPC��ģ��Ԥ����� ������������ע�⣺���������ϵͳ��̬Ƶ�ʵ�Ӱ���С������Ϊ0
    %ʵ��ϵͳ��ʼ��    
    run Real_system_initialization;
    global Frequency_deviation_overall_value Frequency_economic_overall_value Generation_economic_overall_value Regulation_economic_overall_value 
    

    %������ͳ��
    Frequency_deviation_overall_value=0; %��ǰʱ�̵�Ƶ��ƫ��ͳ��
    Frequency_economic_overall_value=0; %��ǰʱ�̵�Ƶ��ƫ��ɱ�
    Generation_economic_overall_value=0; %��ǰʱ�̵ķ������гɱ�
    Regulation_economic_overall_value=0; %��ǰʱ�̵ĵ�Ƶ��̳ɱ�
    RES_curtailment_overall_value=0; %RES curtailment��
    % 
    % %Overall_cost=Generation_economic_overall_value + Regulation_economic_overall_value;
    % AGG_regulation_mileage=zeros(6,1);  %��¼ÿ���ۺ����ĵ�Ƶ���
    % 
    u0_last_time=zeros(3,1);  %�������Ӧ����һ����+�ţ�
    u_last_time_MPC_controller=[0;0;0];
    
    
