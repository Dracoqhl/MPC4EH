%Checked

%������飬�ҷ������¹��ɣ�t�ǵ�ǰ�ķ���ʱ�̣�x�ǳ�ʼ����״̬�������ܵ�x0Ӱ�죬u����������sys�����������ĸ����ܵ�sizes.NumOutputs����
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
global Deta_T 

sizes = simsizes;
sizes.NumContStates  = 0;   %ģ������״̬��������
sizes.NumDiscStates  = 4+1;   %ģ����ɢ״̬��������
sizes.NumOutputs     = 3+1;   %ģ�������������
sizes.NumInputs      = 4; %9����ֵϵͳ��״̬����+N_DR��������Դ��״̬����
sizes.DirFeedthrough = 1; %����u��mdlOutputs �б����ʣ������ֱ����ͨ
sizes.NumSampleTimes = 1; %ģ�����ʱ�����
sys = simsizes(sizes);  %�������ֵ��sys���
x0 =zeros(4+1,1);   %���������ʼʱ�̵�һ����ʼ����t=0ʱ�̡�������x0��ʼ������ʵ����ʹ���������u����Ҫ�����u���Ǵ�������������������

    
U=zeros(2+1,1); %�����źŵĳ�ֵ
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
    global Ad Bd Cd Dd
    global deta_solar_clock deta_P_load_clock
    global N_step
    global P_DG_up P_DG_down 
    global P_ESS_up P_ESS_down

    global deta_P_load_random_clock deta_solar_random_clock
    global u_last_time_MPC_controller %MPC�������У���һ��ʱ�̵Ŀ����źż�¼
    % global u_DG_up_max_value u_DG_down_max_value u_AGG_up_max_value u_AGG_down_max_value      
    % global DR_AGG_number DR_AGG_P_down DR_AGG_P_up DR_indivitual_down_within_Agg_type1 DR_indivitual_up_within_Agg_type1
    % global DR_AGG_feature_center DR_indivitual_feature_within_Agg_type1      
    global u0_last_time
    global RES_operation_mode 
    global RES_curtailment_overall_value
    global Computational_time
    global EXITFLAG_variation Static_vary %��һ����û��infeasible������
    
    tic
    
    N_x=4; %ÿ��ʱ����Ż�״̬����x�ĸ���
    N_u=3; %ÿ��ʱ����Ż����Ʊ���u�ĸ���    
    fprintf('Update start, t=%6.3f\n',t)
    
    N_MPC_time_slot=N_step; %MPC���Ż�ʱ�䳤�ȣ�ʱ���ĸ�����u(0) u(1) ... u(N_MPC_time_slot-1); x(1) ... x(N_MPC_time_slot) //x(0)�ǲ��������

    x0_sample=u(1:4);%ϵͳ��ǰ״̬����
    % P_0_DR_type1=u(4+1:4+DR_AGG_number(1)); %�������������Դ��ǰ��ת����ۺ���ʹ��
    
    
    % % %     u_last_time_sample=u(6:9);%ϵͳ��һ��ʱ�̵Ŀ����ź�
    
    t_number=max(find(t>=deta_solar_clock(:,1)))%�ҵ���ǰʱ�̶�Ӧ��Ԥ��ֵ���
    D_0=[deta_solar_clock(t_number,2) deta_P_load_clock(t_number,2)];%��һ������ʱ�̵��Ŷ�
    D_1=[deta_solar_clock(t_number+1,2) deta_P_load_clock(t_number+1,2)];%�ڶ�������ʱ�̵��Ŷ�
    D_2=[deta_solar_clock(t_number+2,2) deta_P_load_clock(t_number+2,2)];%����������ʱ�̵��Ŷ�
    D_3=[deta_solar_clock(t_number+3,2) deta_P_load_clock(t_number+3,2)];%����������ʱ�̵��Ŷ�
    D_4=[deta_solar_clock(t_number+4,2) deta_P_load_clock(t_number+4,2)];%����������ʱ�̵��Ŷ�

%% ��ʼ������
    
    %%���Ʊ��������뷶Χ
    u_DG_max=P_DG_up*ones(N_MPC_time_slot,1);
    % tt = ones(N_MPC_time_slot,1);
    u_DG_min=P_DG_down*ones(N_MPC_time_slot,1);

    RES_operation_mode;%=1�������ڿ����硢����ģʽ��=����������֮MPPTģʽ
    if  RES_operation_mode==1
        u_RES_max=[D_0(1); D_1(1); D_2(1); D_3(1); D_4(1);];%����Դ��Ԥ�Ⲩ�����ֵ
        u_RES_min=u_RES_max-1;
    else
        u_RES_max=[D_0(1); D_1(1); D_2(1); D_3(1); D_4(1);];%����Դ��Ԥ�Ⲩ�����ֵ
        u_RES_min=u_RES_max;        
    end
    
    %  % �˴���Ӧ�����źŸ���ESS����Ϣ
    global P_ESS_current E_ESS_current
    global Deta_T
    P_ESS_max = 2;
    P_ESS_min = 0;
    E_ESS_max = 1000;
    E_ESS_min = 0; 

    P_ESS_current =  x0_sample(4);
    E_ESS_current = E_ESS_current - (P_ESS_current)*Deta_T*1/3600;

    Deta_T_rate=Deta_T*1/3600;%ÿ��ʱ�����1h��ռ�ݵı���
    % P_ESS_up = min((P_ESS_max - P_ESS_current),((E_ESS_current-E_ESS_min)/Deta_T_rate));
    % P_ESS_down = -min((P_ESS_current - P_ESS_min),((E_ESS_max-E_ESS_current)/Deta_T_rate));
    P_ESS_up = (P_ESS_max - P_ESS_current);
    P_ESS_down = -(P_ESS_current - P_ESS_min);
    % 
    u_ESS_max=1*ones(N_MPC_time_slot,1);
    u_ESS_min=-1*ones(N_MPC_time_slot,1);

            
    %���ɲ���Ԥ��
    P_L_forecast=[D_0(2) D_1(2) D_2(2) D_3(2) D_4(2)];
    
 %����ʽԼ������
    Aineq=[];
    Bineq=[];
    
    %���켯��ʽ�ĵ�ʽԼ������(ÿһ�д���һ��ʱ�䲽��)
    Aeq_centralized=[ Bd   -eye(N_x)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u);  % Bd*U_0 - X_1= -Ad*X_0 -Dd*d_0
                      zeros(N_x,N_u)    Ad   Bd   -eye(N_x)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u);  % Ad*X_1+Bd*U_1-X_2=0  -Dd*d_1
                      zeros(N_x,N_x+N_u)  zeros(N_x,N_u)   Ad   Bd  -eye(N_x)     zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u) ;  % Ad*X_2+Bd*U_2-X_3=0  -Dd*d_2
                      zeros(N_x,N_x+N_u)  zeros(N_x,N_x+N_u)  zeros(N_x,N_u)   Ad   Bd  -eye(N_x)   zeros(N_x,N_x+N_u) ;  % Ad*X_3+Bd*U_3-X_4=0  -Dd*d_3
                      zeros(N_x,N_x+N_u)  zeros(N_x,N_x+N_u)  zeros(N_x,N_x+N_u)  zeros(N_x,N_u)   Ad   Bd  -eye(N_x) ;  % Ad*X_4+Bd*U_4-X_5=0  -Dd*d_4
                    ];%״̬�ռ䷽��ת��
    % tem = -Ad*x0_sample'
    Beq_centralized=[ -Ad*x0_sample - Dd*P_L_forecast(1);
                       zeros(4,1) - Dd*P_L_forecast(2);
                       zeros(4,1) - Dd*P_L_forecast(3);
                       zeros(4,1) - Dd*P_L_forecast(4);
                       zeros(4,1) - Dd*P_L_forecast(5);
                    ];%״̬�ռ䷽��ת��    
    Aeq=Aeq_centralized;
    Beq=Beq_centralized;
                
    %���Ʊ�����ΧԼ��
        lb=[
            u_DG_min(1);
            u_RES_min(1);
            u_ESS_min(1);

            -inf*ones(4,1);
            u_DG_min(2);
            u_RES_min(2);
            u_ESS_min(2);

            -inf*ones(4,1);
            u_DG_min(3);
            u_RES_min(3);
            u_ESS_min(3);

            -inf*ones(4,1);
            u_DG_min(4);
            u_RES_min(4);
            u_ESS_min(4);

            -inf*ones(4,1);        
            u_DG_min(5);
            u_RES_min(5);
            u_ESS_min(5);

            -inf*ones(4,1);                
            ];
        
        ub=[
            u_DG_max(1);
            u_RES_max(1);
            u_ESS_max(1);

            inf*ones(4,1);
            u_DG_max(2);
            u_RES_max(2);
            u_ESS_max(2);

            inf*ones(4,1);
            u_DG_max(3);
            u_RES_max(3);
            u_ESS_max(3);

            inf*ones(4,1);
            u_DG_max(4);
            u_RES_max(4);
            u_ESS_max(4);

            inf*ones(4,1);            
            u_DG_max(5);
            u_RES_max(5);
            u_ESS_max(5);

            inf*ones(4,1);             
            ];
        
    options = optimoptions('fmincon','MaxFunctionEvaluations',30000);
    N_variable=N_MPC_time_slot*(N_x+N_u);
    X0_optimization=zeros(N_variable,1);%�����ĳ�ʼ���� ��ע���ϵͳ״̬���������֣�    
   %�Ż�����
   [X,FVAL,EXITFLAG,OUTPUT,LAMBDA,GRAD,HESSIAN] = fmincon(@(X)MPC_fitnessfun(X),X0_optimization,Aineq,Bineq,Aeq,Beq,lb,ub,[],options);  %������Ϊ������ȷ�ģ�ֻ���е�ʱ����Ҫ�ѷ�����Լ�����õĺ������  
   %������
   
    u_0_MPC=X(1:3);%��ǰʱ�̵�MPC�����źţ������
    u_0_ESS=u_0_MPC(3);

    P_1_ESS=X(7);%��һʱ�̵�AGG1������״̬

    
    %���RES��ʵֵС��Ԥ��ֵ����ô������ʵִֵ�п����źţ�����ģ��Ԥ������Դ���� �� ʵ������Դ������ƫ��
    if u_0_MPC(2)>deta_solar_random_clock(t_number,2)
        u_0_MPC(2)=deta_solar_random_clock(t_number,2);
    end
    
    %ͳ�Ƶ�ǰ�����źŵ����������Ա���һʱ�̺˶��ɱ�����
    u_last_time_MPC_controller=u_0_MPC;
    % u_ESS_last_time=u0_last_time( 2+1:2+1 );
    
    
    % DR_control_signal_type1 = Disaggregation_to_DR(u_0_AGG1,u_DR_type1_last_time,P_1_AGG1,P_0_DR_type1,u_AGG_up_max_value(1),u_AGG_down_max_value(1),DR_indivitual_up_within_Agg_type1,DR_indivitual_down_within_Agg_type1,DR_indivitual_feature_within_Agg_type1);
    
   

    u_0_DisAGG=[u_0_MPC(1);
                u_0_MPC(2);
                u_0_MPC(3);
                E_ESS_current;
                ];
    RES_curtailment_overall_value=RES_curtailment_overall_value+u_RES_max(1)-u_0_MPC(2);
            
    sys= u_0_DisAGG';
    
    toc
    EXITFLAG_variation(Static_vary)=EXITFLAG; %��һ����û��infeasible������
    Computational_time(Static_vary)=toc;
    Static_vary=Static_vary+1;
    
    
% End of mdlOutputs.