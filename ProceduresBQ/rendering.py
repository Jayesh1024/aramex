from jinja2 import Template
from dotenv import load_dotenv
import os

# Get the folder where this script lives
base_dir = os.path.dirname(os.path.abspath(__file__))

# Load .env file from same folder as the script
load_dotenv(os.path.join(base_dir, 'config.env'))

# Read values from .env
project_id        = os.getenv('PROJECT_ID')
sp_dataset_id     = os.getenv('SP_DATASET_ID')
target_dataset_id = os.getenv('TARGET_DATASET_ID')

# Folders
input_folder  = os.path.join(base_dir, 'Working_SPs2')
output_folder = os.path.join(base_dir, 'rendered_SPs')
os.makedirs(output_folder, exist_ok=True)

# Loop through all SQL files and render them
for filename in os.listdir(input_folder):
    if filename.endswith('.sql'):

        with open(os.path.join(input_folder, filename), 'r') as f:
            template = Template(f.read())

        rendered = template.render(
            project_id        = project_id,
            sp_dataset_id     = sp_dataset_id,
            target_dataset_id = target_dataset_id
        )

        with open(os.path.join(output_folder, filename), 'w') as f:
            f.write(rendered)

        print(f"✓ Rendered: {filename}")

print("\nAll done! Check the rendered_SPs folder.")