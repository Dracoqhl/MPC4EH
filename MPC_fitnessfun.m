%checked

%优化变量x=[u(0) x(1) u(1) x(2) u(2) x(3)]  x(k+1)=Ad*x(k) + Bd*u(k)  <->  Ad*x(k) + Bd*u(k) - x(k+1)=0

function fitness=MPC_fitnessfun(X)
    % global  Q_fre Q_DG Q_RES Q_ESS r_fre r_DG r_RES r_ESS Beita_DG Beita_RES Beita_AGG
    global  Q_fre Q_DG Q_RES Q_ESS r_fre r_DG r_RES r_ESS Beita_DG Beita_RES Beita_ESS
    global  u_last_time_MPC_controller %MPC控制器中，上一个时刻的控制信号记录
    
    u_DG_0=X(1);
    u_RES_0=X(2);
    u_ESS_0=X(3);
    
    f_1=X(4);
    P_DG_1=X(5);
    P_RES_1=X(6);
    P_ESS_1=X(7);
    
    u_DG_1=X(8);
    u_RES_1=X(9);
    u_ESS_1=X(10);
    
    f_2=X(11);
    P_DG_2=X(12);
    P_RES_2=X(13);
    P_ESS_2=X(14);
    
    u_DG_2=X(15);
    u_RES_2=X(16);
    u_ESS_2=X(17);
    
    
    f_3=X(18);
    P_DG_3=X(19);
    P_RES_3=X(20);
    P_ESS_3=X(21);
    
    u_DG_3=X(22);
    u_RES_3=X(23);
    u_ESS_3=X(24);
    
    
    f_4=X(25);
    P_DG_4=X(26);
    P_RES_4=X(27);
    P_ESS_4=X(28);  
    
    u_DG_4=X(29);
    u_RES_4=X(30);
    u_ESS_4=X(31);
    
    f_5=X(32);
    P_DG_5=X(33);
    P_RES_5=X(34);
    P_ESS_5=X(35);     
    
    u_DG_last_time_MPC_controller=u_last_time_MPC_controller(1);
    u_RES_last_time_MPC_controller=u_last_time_MPC_controller(2);
    u_ESS_last_time_MPC_controller=u_last_time_MPC_controller(3);
    
    %将每个Agent的目标函数分开：
    %Agent1: 频率协调器
    Function_agent1=Q_fre *( f_1*f_1 + f_2*f_2 + f_3*f_3 + f_4*f_4 + f_5*f_5 ) + r_fre * (f_1 + f_2 +f_3 +f_4 +f_5);
    %Agent2: DG
    Function_agent2=Q_DG *( P_DG_1*P_DG_1 + P_DG_2*P_DG_2 + P_DG_3*P_DG_3 + P_DG_4*P_DG_4 + P_DG_5*P_DG_5 ) + r_DG * (P_DG_1 + P_DG_2 +P_DG_3 +P_DG_4 +P_DG_5)  + Beita_DG * ( abs(u_DG_last_time_MPC_controller-u_DG_0) + abs(u_DG_0-u_DG_1) + abs(u_DG_1-u_DG_2) + abs(u_DG_2-u_DG_3) + abs(u_DG_3-u_DG_4) );
    %Agent3: RES
    Function_agent3=Q_RES *( P_RES_1*P_RES_1 + P_RES_2*P_RES_2 + P_RES_3*P_RES_3  + P_RES_4*P_RES_4  + P_RES_5*P_RES_5 ) + r_RES * (P_RES_1 + P_RES_2 +P_RES_3 +P_RES_4 +P_RES_5) + Beita_RES * ( abs(u_RES_last_time_MPC_controller-u_RES_0) + abs(u_RES_0-u_RES_1) +abs(u_RES_1-u_RES_2) +abs(u_RES_2-u_RES_3) +abs(u_RES_3-u_RES_4) );
    global P_ESS_current E_ESS_current
    %Agent4: ESS
    Function_agent4=Q_ESS *( P_ESS_1*P_ESS_1 + P_ESS_2*P_ESS_2 + P_ESS_3*P_ESS_3 + P_ESS_4*P_ESS_4 + P_ESS_5*P_ESS_5 ) + r_ESS * (P_ESS_1 + P_ESS_2 +P_ESS_3 +P_ESS_4 +P_ESS_5) + Beita_ESS * ( abs(u_ESS_last_time_MPC_controller-u_ESS_0) + abs(u_ESS_0-u_ESS_1) +abs(u_ESS_1-u_ESS_2) +abs(u_ESS_2-u_ESS_3) +abs(u_ESS_3-u_ESS_4) );

    
    % fitness=Function_agent1+Function_agent2+Function_agent3+Function_agent4+Function_agent5+Function_agent6+Function_agent7+Function_agent8+Function_agent9;
    fitness=Function_agent1+Function_agent2+Function_agent3+Function_agent4;
    
end