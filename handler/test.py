import os

def list_files():
    """List all files in a directory"""
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        
        models_path = os.path.join(script_dir, 'data')
        files = os.listdir(models_path)
        print(f"Contents of 'data' directory: {files}")
        
        data_files = [file for file in files if file.endswith('.npz')]
        print(f"Filtered .npz files: {data_files}")
        
        return data_files
        
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    list_files()
 


