import os
import grid_model
import plotting
import config
import json

def main():
    # Parse command-line arguments and load parameters
    params = config.parse_and_load_params()

    # Create and run GridModel simulation
    grid_model_instance = grid_model.GridModel(params, data_path='data.xlsx', silence_solver=True)
    mpc, simulator = grid_model_instance.run_simulation()

    # Create the directory for saving results if it doesn't exist
    save_dir = os.path.join(params['savepath'], params['alias'])
    os.makedirs(save_dir, exist_ok=True)

    # Plot results
    plotting.plot_results(mpc, simulator, base_path=save_dir, exam_name=params['alias'])

    # Save the used parameters to a JSON file
    params_file_path = os.path.join(save_dir, 'used_parameters.json')
    with open(params_file_path, 'w') as f:
        json.dump(params, f, indent=4)

if __name__ == '__main__':
    main()