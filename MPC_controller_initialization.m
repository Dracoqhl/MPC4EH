%checked

%本函数用于MPC控制器一些参数的初始化，必须由Initialization函数调用
global Ad Bd Cd Dd
% global Deta_T 
% global M D T_DG T_RES 
% global  Q_fre Q_DG Q_RES Q_AGG r_fre r_DG r_RES r_AGG Beita_DG Beita_RES 
% global  Fre_regulation_mode %频率控制模式选择 =0：仅考虑调频偏差；=1：调频偏差+发电成本；=2调频偏差+发电成本+里程成本
% global Ad Bd Cd Dd
% global u_DG_up_max_value u_DG_down_max_value u_AGG_up_max_value u_AGG_down_max_value 
% global DR_AGG_feature_center
% global Q_fre_reference Q_DG_reference r_DG_reference Q_RES_reference r_RES_reference Beita_DG_referenece Beita_RES_reference
% global Operation_cost_coefficient Regulation_cost_coefficient

    %x=Ac*x+Bc*u+Dc*d
    Ac=[ -D/M      1/M      1/M      1/M      ;
           0    -1/T_DG      0        0       ; 
           0        0     -1/T_RES    0       ;
           0        0        0   -1/T_ESS  ;
        ]; %连续系统的状态空间方程
    Bc=[  0         0        0       ;
        1/T_DG      0        0       ;
          0       1/T_RES    0       ;
          0         0     1/T_ESS ;
        ];%连续系统的状态空间方程
    
    Dc=[ -1/M;
           0;
           0;
           0;
        ];%连续系统的状态空间方程
    
    Ad=eye( length(Dc) )+Deta_T*Ac;  %离散系统的状态空间方程
    Bd=Deta_T*Bc;  %离散系统的状态空间方程
    Dd=Deta_T*Dc;  %离散系统的状态空间方程

    

    
    
    