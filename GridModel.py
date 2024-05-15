import numpy as np
import pandas as pd
from casadi import *
from casadi.tools import *
import pdb
import sys
import os
import do_mpc
from do_mpc.tools import Timer

class GridModel:
    def __init__(self, symvar_type='SX', data_path='./data.xlsx', silence_solver=False):
        self.symvar_type = symvar_type
        self.data_path = data_path
        self.data = pd.read_excel(self.data_path)
        self.delta_P_Load_data = self.data['delta_P_Load'].values
        self.delta_P_RES_data = self.data['delta_P_RES'].values
        print(self.delta_P_RES_data[0])
        self.param_load()
        self.model = self.create_model()
        self.mpc = self.create_mpc(silence_solver)
        self.set_optimizer_constraints()
        self.mpc.set_tvp_fun(self.tvp_fun)
        self.mpc.setup()  # 确保在设置 tvp_fun 后调用 setup

        """ User settings: """
        self.show_animation = True
        self.store_results = False

    def param_load(self):
        # 初始化变量真值
        self.f_current = 50 
        self.P_ESS_current = 2 
        self.E_ESS_current = 300
        self.P_DG_current = 2 
        self.P_RES_current = 1 

        self.Deta_T = 0.5
        # ESS 参数值
        self.T_ESS = 1
        self.P_ESS_max = 2
        self.P_ESS_min = 0
        self.E_ESS_max = 1000
        self.E_ESS_min = 0

        self.Deta_T_rate = self.Deta_T * 1 / 3600

        # DG 参数值
        self.P_DG_max = 1.5   
        self.P_DG_min = -2.5
        self.P_DG_current = 1

        # RES 参数值
        self.Rou_RES = 0.1  # p.u.  弃风惩罚权重

    def create_model(self):
        model_type = 'continuous'
        model = do_mpc.model.Model(model_type, self.symvar_type)

        # Certain parameters
        # 系统参数
        M = 1.8 
        D = 0.15
        # ESS参数
        T_ESS = 0.55
        T_DG = 0.7
        T_RES = 0.35

        # States struct (optimization variables):
        delta_f = model.set_variable(var_type='_x', var_name='delta_f', shape=(1,1))
        delta_P_ESS = model.set_variable(var_type='_x', var_name='delta_P_ESS', shape=(1,1))
        delta_P_DG = model.set_variable(var_type='_x', var_name='delta_P_DG', shape=(1,1))
        delta_P_RES = model.set_variable(var_type='_x', var_name='delta_P_RES', shape=(1,1))

        # 扰动变量
        delta_P_Load = model.set_variable(var_type='_tvp', var_name='delta_P_Load', shape=(1,1))
        delta_P_RES_data_actual = model.set_variable(var_type='_tvp', var_name='delta_P_RES_data_actual', shape=(1,1))
        
        # Input struct (optimization variables):
        delta_P_ESS_set = model.set_variable(var_type='_u', var_name='delta_P_ESS_set', shape=(1,1))
        delta_P_DG_set = model.set_variable(var_type='_u', var_name='delta_P_DG_set', shape=(1,1))
        delta_P_RES_set = model.set_variable(var_type='_u', var_name='delta_P_RES_set', shape=(1,1))

        # Differential equations
        model.set_rhs('delta_f', -D/M*delta_f + 1/M*(delta_P_ESS + delta_P_DG + delta_P_RES - delta_P_Load))
        model.set_rhs('delta_P_ESS', -1/T_ESS*(delta_P_ESS - delta_P_ESS_set))
        model.set_rhs('delta_P_DG', -1/T_DG*(delta_P_DG - delta_P_DG_set))
        model.set_rhs('delta_P_RES', -1/T_RES*(delta_P_RES - delta_P_RES_set))

        # 损失函数定义
        model.set_expression(expr_name='cost', expr=sum1(delta_f))

        # Build the model
        model.setup()

        return model

    def create_mpc(self, silence_solver):
        mpc = do_mpc.controller.MPC(self.model)

        # 通过鲁棒优化可以考虑不确定性的场景
        mpc.settings.n_robust = 0
        mpc.settings.n_horizon = 20
        mpc.settings.t_step = 0.5
        mpc.settings.store_full_solution = True

        if silence_solver:
            mpc.settings.supress_ipopt_output()

        '''TODO: 完善损失函数'''
        mterm = self.model.aux['cost']
        lterm = self.model.aux['cost'] 
        
        mpc.set_objective(mterm=mterm, lterm=lterm)
        mpc.set_rterm(delta_P_ESS_set=1e-4, delta_P_DG_set=1e-4, delta_P_RES_set=1e-4)

        return mpc

    def set_optimizer_constraints(self):
        model = self.mpc.model
        # 弃风弃光约束
        self.mpc.set_nl_cons('delta_P_RES_constraint', model._x['delta_P_RES'] - model._tvp['delta_P_RES_data_actual'], ub=0)

    def tvp_fun(self, t_now):
        tvp_template = self.mpc.get_tvp_template()
        idx = int(t_now)
        n_horizon = self.mpc.settings.n_horizon
        
        for k in range(n_horizon + 1):
            if (idx + k) < len(self.delta_P_Load_data):
                tvp_template['_tvp', k, 'delta_P_Load'] = self.delta_P_Load_data[idx + k]
            if (idx + k) < len(self.delta_P_RES_data):
                tvp_template['_tvp', k, 'delta_P_RES_data_actual'] = self.delta_P_RES_data[idx + k]
                
        return tvp_template
    
    def tvp_fun_simulator(self, t_now):
        tvp_template = self.simulator.get_tvp_template()
        idx = int(t_now)
        
        if idx < len(self.delta_P_Load_data):
            tvp_template['delta_P_Load'] = self.delta_P_Load_data[idx]
        if idx < len(self.delta_P_RES_data):
            tvp_template['delta_P_RES_data_actual'] = self.delta_P_RES_data[idx]
        
        return tvp_template

    
    def update_constraints(self, mpc):
        # 累计实际状态变量
        self.f_current += self.model._x['delta_f'] * self.Deta_T_rate
        self.P_ESS_current += self.model._x['delta_P_ESS'] * self.Deta_T_rate
        self.E_ESS_current += self.model._x['delta_P_ESS'] * self.Deta_T_rate * 0.55
        self.P_DG_current += self.model._x['delta_P_DG'] * self.Deta_T_rate
        # self.P_ESS_current += float(mpc.data['_x', 'delta_P_ESS']) * self.Deta_T_rate
        # self.E_ESS_current += float(mpc.data['_x', 'delta_P_ESS']) * self.Deta_T_rate * 0.55  # 使用固定值T_ESS
        # self.P_DG_current += float(mpc.data['_x', 'delta_P_DG']) * self.Deta_T_rate

        # 更新ESS的约束范围
        delta_ESS_up = self.P_ESS_max - self.P_ESS_current
        delta_ESS_down = -(self.P_ESS_current - self.P_ESS_min)
        mpc.bounds['lower', '_u', 'delta_P_ESS_set'] = delta_ESS_down
        mpc.bounds['upper', '_u', 'delta_P_ESS_set'] = delta_ESS_up

        # 更新DG的约束范围
        delta_DG_up = self.P_DG_max - self.P_DG_current
        delta_DG_down = -(self.P_DG_current - self.P_DG_min)
        mpc.bounds['lower', '_u', 'delta_P_DG_set'] = delta_DG_down
        mpc.bounds['upper', '_u', 'delta_P_DG_set'] = delta_DG_up

    def run_simulation(self):
        timer = Timer()

        self.simulator = do_mpc.simulator.Simulator(self.model)
        self.simulator.set_tvp_fun(self.tvp_fun_simulator)
        self.simulator.set_param(t_step=0.5)
        self.simulator.setup()
        
        x0 = self.simulator.x0
        x0['delta_f'] = 0
        x0['delta_P_ESS'] = 0
        x0['delta_P_DG'] = 0
        x0['delta_P_RES'] = 0

        self.simulator.x0 = x0
        self.mpc.x0 = x0
        self.mpc.set_initial_guess()

        for t in range(len(self.delta_P_Load_data)):
            self.update_constraints(self.mpc)
            timer.tic()
            u0 = self.mpc.make_step(x0)
            timer.toc()
            x0 = self.simulator.make_step(u0)
            self.P_ESS_current += float(u0['delta_P_ESS_set']) * self.Deta_T_rate
            self.E_ESS_current += float(u0['delta_P_ESS_set']) * self.Deta_T_rate * 0.55  # 使用固定值T_ESS
        timer.info()
        timer.hist()
        # Store results:
        if self.store_results:
            do_mpc.data.save_results([self.mpc, self.simulator], 'CSTR_robust_MPC')

if __name__ == '__main__':
    grid_model = GridModel(data_path='/home/lyq/Draco/MPC4EH_py/data.xlsx', silence_solver=True)
    grid_model.run_simulation()
