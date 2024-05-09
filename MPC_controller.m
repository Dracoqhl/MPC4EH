%Checked

%经过检查，我发现以下规律：t是当前的仿真时刻，x是初始化的状态变量，受到x0影响，u是输入量，sys是输出，输出的个数受到sizes.NumOutputs决定
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
sizes.NumContStates  = 0;   %模块连续状态变量个数
sizes.NumDiscStates  = 4+1;   %模块离散状态变量个数
sizes.NumOutputs     = 3+1;   %模块输出变量个数
sizes.NumInputs      = 4; %9个等值系统的状态变量+N_DR个海量资源的状态变量
sizes.DirFeedthrough = 1; %输入u在mdlOutputs 中被访问，则存在直接馈通
sizes.NumSampleTimes = 1; %模块采样时间个数
sys = simsizes(sizes);  %设置完后赋值给sys输出
x0 =zeros(4+1,1);   %这里是最初始时刻的一个初始化，t=0时刻。后续的x0初始化，其实可以使用输入变量u（主要这里的u就是从外界来的输入变量）。

    
U=zeros(2+1,1); %控制信号的初值
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
    global Ad Bd Cd Dd
    global deta_solar_clock deta_P_load_clock
    global N_step
    global P_DG_up P_DG_down 
    global P_ESS_up P_ESS_down

    global deta_P_load_random_clock deta_solar_random_clock
    global u_last_time_MPC_controller %MPC控制器中，上一个时刻的控制信号记录
    % global u_DG_up_max_value u_DG_down_max_value u_AGG_up_max_value u_AGG_down_max_value      
    % global DR_AGG_number DR_AGG_P_down DR_AGG_P_up DR_indivitual_down_within_Agg_type1 DR_indivitual_up_within_Agg_type1
    % global DR_AGG_feature_center DR_indivitual_feature_within_Agg_type1      
    global u0_last_time
    global RES_operation_mode 
    global RES_curtailment_overall_value
    global Computational_time
    global EXITFLAG_variation Static_vary %看一下有没有infeasible的问题
    
    tic
    
    N_x=4; %每个时间段优化状态变量x的个数
    N_u=3; %每个时间段优化控制变量u的个数    
    fprintf('Update start, t=%6.3f\n',t)
    
    N_MPC_time_slot=N_step; %MPC的优化时间长度，时间点的个数，u(0) u(1) ... u(N_MPC_time_slot-1); x(1) ... x(N_MPC_time_slot) //x(0)是采样输入的

    x0_sample=u(1:4);%系统当前状态采样
    % P_0_DR_type1=u(4+1:4+DR_AGG_number(1)); %采样各灵活性资源当前的转：解聚合中使用
    
    
    % % %     u_last_time_sample=u(6:9);%系统上一个时刻的控制信号
    
    t_number=max(find(t>=deta_solar_clock(:,1)))%找到当前时刻对应的预测值编号
    D_0=[deta_solar_clock(t_number,2) deta_P_load_clock(t_number,2)];%第一个控制时刻的扰动
    D_1=[deta_solar_clock(t_number+1,2) deta_P_load_clock(t_number+1,2)];%第二个控制时刻的扰动
    D_2=[deta_solar_clock(t_number+2,2) deta_P_load_clock(t_number+2,2)];%第三个控制时刻的扰动
    D_3=[deta_solar_clock(t_number+3,2) deta_P_load_clock(t_number+3,2)];%第三个控制时刻的扰动
    D_4=[deta_solar_clock(t_number+4,2) deta_P_load_clock(t_number+4,2)];%第三个控制时刻的扰动

%% 开始求解过程
    
    %%控制变量的输入范围
    u_DG_max=P_DG_up*ones(N_MPC_time_slot,1);
    % tt = ones(N_MPC_time_slot,1);
    u_DG_min=P_DG_down*ones(N_MPC_time_slot,1);

    RES_operation_mode;%=1：工作在可弃风、弃光模式；=其他：工作之MPPT模式
    if  RES_operation_mode==1
        u_RES_max=[D_0(1); D_1(1); D_2(1); D_3(1); D_4(1);];%新能源的预测波动最大值
        u_RES_min=u_RES_max-1;
    else
        u_RES_max=[D_0(1); D_1(1); D_2(1); D_3(1); D_4(1);];%新能源的预测波动最大值
        u_RES_min=u_RES_max;        
    end
    
    %  % 此处对应控制信号更新ESS的信息
    global P_ESS_current E_ESS_current
    global Deta_T
    P_ESS_max = 2;
    P_ESS_min = 0;
    E_ESS_max = 1000;
    E_ESS_min = 0; 

    P_ESS_current =  x0_sample(4);
    E_ESS_current = E_ESS_current - (P_ESS_current)*Deta_T*1/3600;

    Deta_T_rate=Deta_T*1/3600;%每个时间段在1h中占据的比例
    % P_ESS_up = min((P_ESS_max - P_ESS_current),((E_ESS_current-E_ESS_min)/Deta_T_rate));
    % P_ESS_down = -min((P_ESS_current - P_ESS_min),((E_ESS_max-E_ESS_current)/Deta_T_rate));
    P_ESS_up = (P_ESS_max - P_ESS_current);
    P_ESS_down = -(P_ESS_current - P_ESS_min);
    % 
    u_ESS_max=1*ones(N_MPC_time_slot,1);
    u_ESS_min=-1*ones(N_MPC_time_slot,1);

            
    %负荷波动预测
    P_L_forecast=[D_0(2) D_1(2) D_2(2) D_3(2) D_4(2)];
    
 %不等式约束：无
    Aineq=[];
    Bineq=[];
    
    %构造集中式的等式约束矩阵(每一行代表一个时间步长)
    Aeq_centralized=[ Bd   -eye(N_x)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u);  % Bd*U_0 - X_1= -Ad*X_0 -Dd*d_0
                      zeros(N_x,N_u)    Ad   Bd   -eye(N_x)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u);  % Ad*X_1+Bd*U_1-X_2=0  -Dd*d_1
                      zeros(N_x,N_x+N_u)  zeros(N_x,N_u)   Ad   Bd  -eye(N_x)     zeros(N_x,N_x+N_u)   zeros(N_x,N_x+N_u) ;  % Ad*X_2+Bd*U_2-X_3=0  -Dd*d_2
                      zeros(N_x,N_x+N_u)  zeros(N_x,N_x+N_u)  zeros(N_x,N_u)   Ad   Bd  -eye(N_x)   zeros(N_x,N_x+N_u) ;  % Ad*X_3+Bd*U_3-X_4=0  -Dd*d_3
                      zeros(N_x,N_x+N_u)  zeros(N_x,N_x+N_u)  zeros(N_x,N_x+N_u)  zeros(N_x,N_u)   Ad   Bd  -eye(N_x) ;  % Ad*X_4+Bd*U_4-X_5=0  -Dd*d_4
                    ];%状态空间方程转换
    % tem = -Ad*x0_sample'
    Beq_centralized=[ -Ad*x0_sample - Dd*P_L_forecast(1);
                       zeros(4,1) - Dd*P_L_forecast(2);
                       zeros(4,1) - Dd*P_L_forecast(3);
                       zeros(4,1) - Dd*P_L_forecast(4);
                       zeros(4,1) - Dd*P_L_forecast(5);
                    ];%状态空间方程转换    
    Aeq=Aeq_centralized;
    Beq=Beq_centralized;
                
    %控制变量范围约束
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
    X0_optimization=zeros(N_variable,1);%迭代的初始变量 （注意和系统状态采样相区分）    
   %优化计算
   [X,FVAL,EXITFLAG,OUTPUT,LAMBDA,GRAD,HESSIAN] = fmincon(@(X)MPC_fitnessfun(X),X0_optimization,Aineq,Bineq,Aeq,Beq,lb,ub,[],options);  %个人认为这是正确的，只是有的时候需要把非线性约束设置的合理才行  
   %输出结果
   
    u_0_MPC=X(1:3);%当前时刻的MPC控制信号（输出）
    u_0_ESS=u_0_MPC(3);

    P_1_ESS=X(7);%下一时刻的AGG1的期望状态

    
    %如果RES真实值小于预测值，那么按照真实值执行控制信号：用于模拟预测新能源出力 和 实际新能源出力的偏差
    if u_0_MPC(2)>deta_solar_random_clock(t_number,2)
        u_0_MPC(2)=deta_solar_random_clock(t_number,2);
    end
    
    %统计当前控制信号的输出结果，以便下一时刻核定成本调用
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
    EXITFLAG_variation(Static_vary)=EXITFLAG; %看一下有没有infeasible的问题
    Computational_time(Static_vary)=toc;
    Static_vary=Static_vary+1;
    
    
% End of mdlOutputs.