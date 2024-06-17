import pandas as pd
import numpy as np
from casadi import *
from casadi.tools import *
import do_mpc

class GridModel:
    def __init__(self, config, data_path='./data.xlsx', silence_solver=True):
        self.config = config
        self.data_path = data_path
        self.data = pd.read_excel(self.data_path)
        self.delta_P_Load_data = self.data['delta_P_Load'].values
        self.delta_P_RES_data = self.data['delta_P_RES'].values
        self.delta_P_RES_noisy = self.data['delta_P_RES_noisy'].values
        self.model = self.create_model()
        self.mpc = self.create_mpc(silence_solver)
        self.set_optimizer_constraints(self.mpc)
        self.mpc.set_tvp_fun(self.tvp_fun)
        self.mpc.setup()
        self.estimator = do_mpc.estimator.StateFeedback(self.model)

    def create_model(self):
        model_type = 'continuous'
        model = do_mpc.model.Model(model_type, self.config['symvar_type'])

        M = self.config['M']
        D = self.config['D']
        T_ESS = self.config['T_ESS']
        T_DG = self.config['T_DG']
        T_RES = self.config['T_RES']

        delta_f = model.set_variable(var_type='_x', var_name='delta_f', shape=(1, 1))
        delta_P_ESS = model.set_variable(var_type='_x', var_name='delta_P_ESS', shape=(1, 1))
        delta_P_DG = model.set_variable(var_type='_x', var_name='delta_P_DG', shape=(1, 1))
        delta_P_RES = model.set_variable(var_type='_x', var_name='delta_P_RES', shape=(1, 1))
        accumulated_delta_f = model.set_variable(var_type='_x', var_name='accumulated_delta_f', shape=(1, 1))
        accumulated_delta_P_ESS = model.set_variable(var_type='_x', var_name='accumulated_delta_P_ESS', shape=(1, 1))
        accumulated_delta_P_DG = model.set_variable(var_type='_x', var_name='accumulated_delta_P_DG', shape=(1, 1))
        accumulated_delta_P_RES = model.set_variable(var_type='_x', var_name='accumulated_delta_P_RES', shape=(1, 1))

        delta_P_Load = model.set_variable(var_type='_tvp', var_name='delta_P_Load', shape=(1, 1))
        delta_P_RES_set = model.set_variable(var_type='_tvp', var_name='delta_P_RES_set', shape=(1, 1))

        delta_P_ESS_set = model.set_variable(var_type='_u', var_name='delta_P_ESS_set', shape=(1, 1))
        delta_P_DG_set = model.set_variable(var_type='_u', var_name='delta_P_DG_set', shape=(1, 1))

        model.set_rhs('delta_f', -D / M * delta_f + 1 / M * (delta_P_ESS + delta_P_DG + delta_P_RES - delta_P_Load))
        model.set_rhs('delta_P_ESS', -1 / T_ESS * (delta_P_ESS - delta_P_ESS_set))
        model.set_rhs('delta_P_DG', -1 / T_DG * (delta_P_DG - delta_P_DG_set))
        model.set_rhs('delta_P_RES', -1 / T_RES * (delta_P_RES - delta_P_RES_set))
        model.set_rhs('accumulated_delta_f', delta_f)
        model.set_rhs('accumulated_delta_P_ESS', delta_P_ESS)
        model.set_rhs('accumulated_delta_P_DG', delta_P_DG)
        model.set_rhs('accumulated_delta_P_RES', delta_P_RES)

        w_delta_f = self.config['weights']['w_delta_f']
        w_accumulated_delta_f = self.config['weights']['w_accumulated_delta_f']
        w_ress = self.config['weights']['w_ress']
        w_ess = self.config['weights']['w_ess']
        w_dg = self.config['weights']['w_dg']

        cost_expr = (
            w_delta_f * delta_f**2 +
            w_accumulated_delta_f * accumulated_delta_f**2 +
            w_ess * delta_P_ESS**2 +
            w_dg * delta_P_DG**2 +
            w_ress * delta_P_RES_set**2
        )

        model.set_expression('cost', cost_expr)
        model.setup()
        return model

    def create_mpc(self, silence_solver):
        mpc = do_mpc.controller.MPC(self.model)

        mpc.settings.n_robust = 0
        mpc.settings.n_horizon = 20
        mpc.settings.t_step = 1
        mpc.settings.store_full_solution = True

        if silence_solver:
            mpc.settings.supress_ipopt_output()

        mterm = self.model.aux['cost']
        lterm = self.model.aux['cost']

        mpc.set_objective(mterm=mterm, lterm=lterm)
        mpc.set_rterm(delta_P_ESS_set=1e-4, delta_P_DG_set=1e-4)
        return mpc

    def set_optimizer_constraints(self,mpc):
        # model = self.mpc.model

        mpc.bounds['lower', '_u', 'delta_P_ESS_set'] = self.config['bounds']['delta_P_ESS_set'][0]
        mpc.bounds['upper', '_u', 'delta_P_ESS_set'] = self.config['bounds']['delta_P_ESS_set'][1]
        mpc.bounds['lower', '_u', 'delta_P_DG_set'] = self.config['bounds']['delta_P_DG_set'][0]
        mpc.bounds['upper', '_u', 'delta_P_DG_set'] = self.config['bounds']['delta_P_DG_set'][1]

        mpc.bounds['lower', '_x', 'delta_P_ESS'] = self.config['bounds']['delta_P_ESS'][0]
        mpc.bounds['upper', '_x', 'delta_P_ESS'] = self.config['bounds']['delta_P_ESS'][1]
        mpc.bounds['lower', '_x', 'delta_P_DG'] = self.config['bounds']['delta_P_DG'][0]
        mpc.bounds['upper', '_x', 'delta_P_DG'] = self.config['bounds']['delta_P_DG'][1]
        mpc.bounds['lower', '_x', 'delta_P_RES'] = self.config['bounds']['delta_P_RES'][0]
        mpc.bounds['upper', '_x', 'delta_P_RES'] = self.config['bounds']['delta_P_RES'][1]
        mpc.bounds['lower', '_x', 'delta_f'] = self.config['bounds']['delta_f'][0]
        mpc.bounds['upper', '_x', 'delta_f'] = self.config['bounds']['delta_f'][1]
        mpc.bounds['lower', '_x', 'accumulated_delta_f'] = self.config['bounds']['accumulated_delta_f'][0]
        mpc.bounds['upper', '_x', 'accumulated_delta_f'] = self.config['bounds']['accumulated_delta_f'][1]

    def tvp_fun(self, t_now):
        tvp_template = self.mpc.get_tvp_template()
        idx = int(t_now)
        n_horizon = self.mpc.settings.n_horizon    

        for k in range(n_horizon + 1):
            if (idx + k) < len(self.delta_P_Load_data):
                tvp_template['_tvp', k, 'delta_P_Load'] = self.delta_P_Load_data[idx + k]
                tvp_template['_tvp', k, 'delta_P_RES_set'] =                self.delta_P_RES_data[idx + k]
        return tvp_template
    
    def tvp_fun_simulator(self, t_now):
        tvp_template = self.simulator.get_tvp_template()
        idx = int(t_now)
        
        if idx < len(self.delta_P_Load_data):
            tvp_template['delta_P_Load'] = self.delta_P_Load_data[idx]
            tvp_template['delta_P_RES_set'] = self.delta_P_RES_noisy[idx]
        return tvp_template

    # ESS DG 可调范围需要不断更新
    def update_constraints(self, mpc):
        delta_ESS_up = self.config['P_ESS_max'] - self.config['P_ESS_current']
        delta_ESS_down = -(self.config['P_ESS_current'] - self.config['P_ESS_min'])
        mpc.bounds['lower', '_u', 'delta_P_ESS_set'] = float(delta_ESS_down)
        mpc.bounds['upper', '_u', 'delta_P_ESS_set'] = float(delta_ESS_up)
        mpc.bounds['lower', '_x', 'delta_P_ESS'] = float(delta_ESS_down)
        mpc.bounds['upper', '_x', 'delta_P_ESS'] = float(delta_ESS_up)

        delta_DG_up = self.config['P_DG_max'] - self.config['P_DG_current']
        delta_DG_down = -(self.config['P_DG_current'] - self.config['P_DG_min'])
        mpc.bounds['lower', '_u', 'delta_P_DG_set'] = delta_DG_down
        mpc.bounds['upper', '_u', 'delta_P_DG_set'] = delta_DG_up
        mpc.bounds['lower', '_x', 'delta_P_DG'] = delta_DG_down
        mpc.bounds['upper', '_x', 'delta_P_DG'] = delta_DG_up

    def run_simulation(self):
        timer = do_mpc.tools.Timer()

        self.simulator = do_mpc.simulator.Simulator(self.model)
        self.simulator.set_tvp_fun(self.tvp_fun_simulator)
        self.simulator.set_param(t_step=1)
        self.simulator.setup()
        
        self.x0 = self.simulator.x0
        self.x0['delta_f'] = 0
        self.x0['delta_P_ESS'] = 0
        self.x0['delta_P_DG'] = 0
        self.x0['delta_P_RES'] = 0
        self.x0['accumulated_delta_f'] = 0

        self.simulator.x0 = self.x0
        self.mpc.x0 = self.x0
        self.mpc.set_initial_guess()

        # for t in range(100):
        for t in range(len(self.delta_P_Load_data)):
            self.update_constraints(self.mpc)
            timer.tic()
            u0 = self.mpc.make_step(self.x0)
            timer.toc()
            y_next = self.simulator.make_step(u0)
            self.x0 = self.estimator.make_step(y_next)
            
            print(f'{t}  delta_f: {self.x0[0]}   delta_P_ESS: {self.x0[1]}   delta_P_DG: {self.x0[2]}   delta_P_RES: {self.x0[3]}    {u0[0]}  {u0[1]} ')

        timer.info()
        timer.hist()

        return self.mpc, self.simulator