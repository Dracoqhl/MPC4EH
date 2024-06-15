import json
import argparse

def load_params(json_path):
    with open(json_path, 'r') as f:
        params = json.load(f)
    return params

def parse_and_load_params():
    parser = argparse.ArgumentParser(description='MPC Grid Model Parameters')
    parser.add_argument('--alias', type=str, required=True, help='Alias for the experiment configuration')
    parser.add_argument('--savepath', type=str, default='./exp_ans', help='Base path to save the results')
    parser.add_argument('--paramfile', type=str, default='parameters.json', help='Path to the JSON file with parameters')
    
    args = parser.parse_args()
    
    params = load_params(args.paramfile)
    
    # Merge args and params into a single dictionary
    config = {**vars(args), **params}
    
    return config