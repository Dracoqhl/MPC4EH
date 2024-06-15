import matplotlib.pyplot as plt
import do_mpc
import os

def plot_results(mpc, simulator, base_path='results_plot', exam_name='experiment'):
    color = plt.rcParams['axes.prop_cycle'].by_key()['color']

    # First plot for changing variables
    fig1, ax1 = plt.subplots(6, 1, sharex=True, figsize=(10, 15))

    mpc_plot = do_mpc.graphics.Graphics(mpc.data)
    sim_plot = do_mpc.graphics.Graphics(simulator.data)

    ax1[0].set_title('Delta F')
    mpc_plot.add_line('_x', 'delta_f', ax1[0], label='Delta F')

    ax1[1].set_title('Delta P ESS')
    mpc_plot.add_line('_x', 'delta_P_ESS', ax1[1], label='Delta P ESS')

    ax1[2].set_title('Delta P DG')
    mpc_plot.add_line('_x', 'delta_P_DG', ax1[2], label='Delta P DG')

    ax1[3].set_title('Delta P RES')
    mpc_plot.add_line('_x', 'delta_P_RES', ax1[3], label='Delta P RES')

    ax1[4].set_title('Inputs')
    mpc_plot.add_line('_u', 'delta_P_ESS_set', ax1[4], linestyle='--', color=color[0], alpha=0.5, label='Delta P ESS Setpoint')
    mpc_plot.add_line('_u', 'delta_P_DG_set', ax1[4], linestyle='--', color=color[1], alpha=0.5, label='Delta P DG Setpoint')
    mpc_plot.add_line('_tvp', 'delta_P_RES_set', ax1[4], linestyle='--', color=color[2], alpha=0.5, label='Delta P RES Setpoint')

    ax1[5].set_title('State Variables')
    mpc_plot.add_line('_x', 'delta_P_ESS', ax1[5], linestyle='-', color=color[0], label='Delta P ESS')
    mpc_plot.add_line('_x', 'delta_P_DG', ax1[5], linestyle='-', color=color[1], label='Delta P DG')
    mpc_plot.add_line('_x', 'delta_P_RES', ax1[5], linestyle='-', color=color[2], label='Delta P RES')

    for a in ax1:
        a.legend()

    plt.xlabel('Time')
    plt.tight_layout()
    file_name = exam_name+'_changing_variables.png'
    save_path = os.path.join(base_path,file_name)
    plt.savefig(save_path)
    plt.close(fig1)

    # Second plot for accumulated variables
    fig2, ax2 = plt.subplots(4, 1, sharex=True, figsize=(10, 10))

    ax2[0].set_title('Accumulated Delta F')
    mpc_plot.add_line('_x', 'accumulated_delta_f', ax2[0], linestyle='-', color=color[3], label='Accumulated Delta F')

    ax2[1].set_title('Accumulated Delta P ESS')
    mpc_plot.add_line('_x', 'accumulated_delta_P_ESS', ax2[1], linestyle='-', color=color[4], label='Accumulated Delta P ESS')

    ax2[2].set_title('Accumulated Delta P DG')
    mpc_plot.add_line('_x', 'accumulated_delta_P_DG', ax2[2], linestyle='-', color=color[5], label='Accumulated Delta P DG')

    ax2[3].set_title('Accumulated Delta P RES')
    mpc_plot.add_line('_x', 'accumulated_delta_P_RES', ax2[3], linestyle='-', color=color[6], label='Accumulated Delta P RES')

    for a in ax2:
        a.legend()

    plt.xlabel('Time')
    plt.tight_layout()
    file_name = exam_name+'_accumulated_variables.png'
    save_path = os.path.join(base_path,file_name)
    plt.savefig(save_path)
    plt.close(fig2)

    # Third plot for setpoints vs state variables
    fig3, ax3 = plt.subplots(3, 1, sharex=True, figsize=(10, 10))

    ax3[0].set_title('Delta P ESS and Setpoint')
    mpc_plot.add_line('_x', 'delta_P_ESS', ax3[0], linestyle='-', color=color[0], label='Delta P ESS')
    mpc_plot.add_line('_u', 'delta_P_ESS_set', ax3[0], linestyle='--', color=color[0], alpha=0.5, label='Delta P ESS Setpoint')

    ax3[1].set_title('Delta P DG and Setpoint')
    mpc_plot.add_line('_x', 'delta_P_DG', ax3[1], linestyle='-', color=color[1], label='Delta P DG')
    mpc_plot.add_line('_u', 'delta_P_DG_set', ax3[1], linestyle='--', color=color[1], alpha=0.5, label='Delta P DG Setpoint')

    ax3[2].set_title('Delta P RES and Setpoint')
    mpc_plot.add_line('_x', 'delta_P_RES', ax3[2], linestyle='-', color=color[2], label='Delta P RES')
    mpc_plot.add_line('_tvp', 'delta_P_RES_set', ax3[2], linestyle='--', color=color[2], alpha=0.5, label='Delta P RES Setpoint')

    for a in ax3:
        a.legend()

    plt.xlabel('Time')
    plt.tight_layout()
    file_name = exam_name+'_setpoints_vs_states.png'
    save_path = os.path.join(base_path,file_name)
    plt.savefig(save_path)
    plt.close(fig3)