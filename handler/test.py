import os


def list_model_files():
    """List all files in a directory"""
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        
        models_path = os.path.join(script_dir, 'models')
        models=os.listdir(models_path)
        print(f"Contents of 'models' directory: {models}")
        
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    # Change to your desired directory path
    list_model_files()


