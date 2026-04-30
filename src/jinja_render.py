from pathlib import Path
import json
import os
from jinja2 import Environment, FileSystemLoader, StrictUndefined
import dotenv
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("jinja_dir_path", default="BQ_GOLD_RAW_STAGING/jinja",type=str)
parser.add_argument("output_dir_path", default="BQ_GOLD_RAW_STAGING/rendered", type=str)
parser.add_argument("config_file_path", default="config/template_config.env", type=str)

args = parser.parse_args()
dotenv.load_dotenv(args.config_file_path)

env = Environment(
    loader=FileSystemLoader(args.jinja_dir_path),
    undefined=StrictUndefined,  # fail if a variable is missing
)


def render_gold_1_sps():
    '''
    Renders the SPs that loads the Gold_1 layer tables, i.e - Data from Silver to Gold_1
    '''
    with open("misc/fileToSourceServer.json", "r") as f:
        fileToSourceServer = json.load(f)

    with open("misc/serverToBQPath.json", "r") as f:
        serverToBQPath = json.load(f)

    for file, server in fileToSourceServer.items():
        try:
            template = env.get_template(file)
            sql = template.render(project_id=os.getenv("project_id"), sp_dataset_id=os.getenv("sp_dataset_id"), target_dataset_id=os.getenv("target_dataset_id"), source_dataset_id=serverToBQPath[server])
            with open(f"{args.output_dir_path}/{file}", "w") as f:
                f.write(sql)
        except KeyError as e:
            print(f"Error deploying {file}: {e}")


def render_gold_2_sps():
    '''
    Renders the SPs that loads the Gold_2 layer tables, i.e - Data from Gold_1 to Gold_2
    '''
    paths = os.listdir(args.jinja_dir_path)
    for path in paths:
        if path.endswith(".sql"):
            template = env.get_template(os.path.basename(path))
            sql = template.render(project_id=os.getenv("project_id"), target_dataset_id=os.getenv("target_dataset_id"), sp_dataset_id=os.getenv("sp_dataset_id"))
            with open(f"{args.output_dir_path}/{path}", "w") as f:
                f.write(sql)

def render_gold_views():
    '''
    Renders the SPs that loads the Gold_2 layer tables, i.e - Data from Gold_1 to Gold_2
    '''
    paths = os.listdir(args.jinja_dir_path)
    for path in paths:
        if path.endswith(".sql"):
            template = env.get_template(os.path.basename(path))
            sql = template.render(project_id=os.getenv("project_id"), dataset_id=os.getenv("dataset_id"))
            with open(f"{args.output_dir_path}/{path}", "w") as f:
                f.write(sql)

render_gold_1_sps()
# render_gold_2_sps()
# render_gold_views()
