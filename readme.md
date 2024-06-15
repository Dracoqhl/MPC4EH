# MPC Grid Model Simulation

This project simulates a grid model using Model Predictive Control (MPC). The simulation results are saved as plots and the parameters used in the simulation are stored in a JSON file for future reference.

## Project Structure
```
project/
├── exp_ans        # # Directory where all experiment results are saved
├── grid_model.py        # Contains the GridModel class for model construction and simulation
├── plotting.py          # Contains functions for plotting the simulation results
├── config.py            # Contains functions for loading and parsing configuration parameters
├── main.py              # Main script to run the simulation and save results
├── parameters.json      # JSON file containing default parameters for the simulation
└── data.xlsx            # Input data file used in the simulation
```
## Prerequisites

Before running the project, ensure you have the following dependencies installed:

- Python 3.9
- pandas
- numpy
- matplotlib
- casadi
- do_mpc

You can install the required Python packages using pip:

```bash
pip install pandas numpy matplotlib casadi do-mpc
```
## Running the Simulation

To run the simulation, use the main.py script. You need to provide the alias for the experiment, the savepath for results, and optionally the paramfile if you have a custom parameter file.
```bash
python main.py --alias <experiment_name> --savepath <results_directory> [--paramfile <path_to_parameters.json>]
```
### Example
```bash
python main.py --alias experiment
```
This command will run the simulation with the alias experiment1 and save the results in the ./results/experiment1 directory.

## Configuration

### Command-line Arguments

```
--alias: A string to identify the experiment. The results will be saved in a directory named after this alias.
--savepath: The base directory where the results will be saved.
--paramfile (optional): Path to the JSON file containing the parameters. If not provided, parameters.json in the current directory will be used.
```
### Parameters JSON

The parameters.json file contains the default parameters for the simulation. You can modify this file or provide a different file using the --paramfile argument.

Example structure of parameters.json:
```json
{
    "symvar_type": "SX",
    "M": 1.8,
    "D": 0.15,
    "T_ESS": 0.4,
    "T_DG": 0.8,
    "T_RES": 0.1,
    "weights": {
        "w_delta_f": 10,
        "w_accumulated_delta_f": 20,
        "w_ress": 1,
        "w_ess": 1,
        "w_dg": 1
    },
    "bounds": {
        "delta_P_ESS_set": [-2, 2],
        "delta_P_DG_set": [0, 3],
        "delta_P_ESS": [-2, 2],
        "delta_P_DG": [0, 3],
        "delta_P_RES": [-300, 300],
        "delta_f": [-2, 2],
        "accumulated_delta_f": [-0.1, 0.1]
    },
    "P_ESS_current": 0,
    "P_DG_current": 1,
    "P_DG_max": 3,
    "P_DG_min": 0,
    "P_ESS_max": 2,
    "P_ESS_min": -2
}
```
## Output

The results of the simulation are saved in the specified savepath directory under a subdirectory named after the alias. The output includes:

	1.	Plots of the simulation results:
```
alias_changing_variables.png: Plot of changing variables over time.
alias_accumulated_variables.png: Plot of accumulated variables over time.
alias_setpoints_vs_states.png: Plot comparing setpoints and state variables.
```
	2.	A JSON file containing the parameters used for the simulation:
```
used_parameters.json
```