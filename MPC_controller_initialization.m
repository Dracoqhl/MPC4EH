%checked

%����������MPC������һЩ�����ĳ�ʼ����������Initialization��������
global Ad Bd Cd Dd
% global Deta_T 
% global M D T_DG T_RES 
% global  Q_fre Q_DG Q_RES Q_AGG r_fre r_DG r_RES r_AGG Beita_DG Beita_RES 
% global  Fre_regulation_mode %Ƶ�ʿ���ģʽѡ�� =0�������ǵ�Ƶƫ�=1����Ƶƫ��+����ɱ���=2��Ƶƫ��+����ɱ�+��̳ɱ�
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
        ]; %����ϵͳ��״̬�ռ䷽��
    Bc=[  0         0        0       ;
        1/T_DG      0        0       ;
          0       1/T_RES    0       ;
          0         0     1/T_ESS ;
        ];%����ϵͳ��״̬�ռ䷽��
    
    Dc=[ -1/M;
           0;
           0;
           0;
        ];%����ϵͳ��״̬�ռ䷽��
    
    Ad=eye( length(Dc) )+Deta_T*Ac;  %��ɢϵͳ��״̬�ռ䷽��
    Bd=Deta_T*Bc;  %��ɢϵͳ��״̬�ռ䷽��
    Dd=Deta_T*Dc;  %��ɢϵͳ��״̬�ռ䷽��

    

    
    
    