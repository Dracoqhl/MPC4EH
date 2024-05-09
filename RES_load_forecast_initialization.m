%checked

%本函数用于生成新能源+负荷预测出力和实际出力信息，必须由Initialization函数调用
global deta_solar_clock deta_P_load_clock Static_vary %光伏/负荷预测变量
global deta_solar_random_clock deta_P_load_random_clock  %光伏/负荷预测变量+一定的预测误差

load('RES_forecasting_data');
t_clock_x=[0:Deta_T:210]';%时间间隔为1s。
% deta_solar_clock_y=1.2*sin(t_clock_x/20) .*( 1+RES_volatility*randn(length(t_clock_x),1) ); 
deta_solar_clock_y=RES_forecasting_data(1:421); 
deta_solar_random_clock_y=deta_solar_clock_y.*( 1+Error_rate_RES*randn(length(t_clock_x),1) );
deta_solar_clock=[t_clock_x,deta_solar_clock_y ];  %MPC控制器预测值
deta_solar_random_clock=[t_clock_x,deta_solar_random_clock_y ];  %系统实际值

t_clock_x=[0:Deta_T:210]';
deta_P_load_clock_y=[0*ones(0.1*210/Deta_T,1);1.5*ones(0.2*210/Deta_T,1);-2*ones(0.2*210/Deta_T,1);0.5*ones(0.2*210/Deta_T,1);-1.5*ones(0.2*210/Deta_T,1);1.5*ones(0.1*210/Deta_T + 1,1)];
% deta_P_load_clock_y=0*sin(t_clock_x/20);
deta_P_load_random_clock_y=deta_P_load_clock_y.*( 1+Error_rate_Load*randn(length(t_clock_x),1) );
deta_P_load_clock=[t_clock_x,deta_P_load_clock_y ];   %MPC控制器预测值
deta_P_load_random_clock=[t_clock_x,deta_P_load_random_clock_y ]; %系统实际值
