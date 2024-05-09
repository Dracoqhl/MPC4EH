%checked

%������������������Դ+����Ԥ�������ʵ�ʳ�����Ϣ��������Initialization��������
global deta_solar_clock deta_P_load_clock Static_vary %���/����Ԥ�����
global deta_solar_random_clock deta_P_load_random_clock  %���/����Ԥ�����+һ����Ԥ�����

load('RES_forecasting_data');
t_clock_x=[0:Deta_T:210]';%ʱ����Ϊ1s��
% deta_solar_clock_y=1.2*sin(t_clock_x/20) .*( 1+RES_volatility*randn(length(t_clock_x),1) ); 
deta_solar_clock_y=RES_forecasting_data(1:421); 
deta_solar_random_clock_y=deta_solar_clock_y.*( 1+Error_rate_RES*randn(length(t_clock_x),1) );
deta_solar_clock=[t_clock_x,deta_solar_clock_y ];  %MPC������Ԥ��ֵ
deta_solar_random_clock=[t_clock_x,deta_solar_random_clock_y ];  %ϵͳʵ��ֵ

t_clock_x=[0:Deta_T:210]';
deta_P_load_clock_y=[0*ones(0.1*210/Deta_T,1);1.5*ones(0.2*210/Deta_T,1);-2*ones(0.2*210/Deta_T,1);0.5*ones(0.2*210/Deta_T,1);-1.5*ones(0.2*210/Deta_T,1);1.5*ones(0.1*210/Deta_T + 1,1)];
% deta_P_load_clock_y=0*sin(t_clock_x/20);
deta_P_load_random_clock_y=deta_P_load_clock_y.*( 1+Error_rate_Load*randn(length(t_clock_x),1) );
deta_P_load_clock=[t_clock_x,deta_P_load_clock_y ];   %MPC������Ԥ��ֵ
deta_P_load_random_clock=[t_clock_x,deta_P_load_random_clock_y ]; %ϵͳʵ��ֵ
