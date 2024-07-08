import os

directory = 'C:/Users/DankyATM/Downloads/60F/60F-0SOC_Multiplexer2ndRun/'

# List all files in the directory
print("Files in directory:")
print(os.listdir(directory))

# Check if the specific file exists
file_path = os.path.join(directory, '60F-0SOC_Multiplexer2ndRun_0%SOC_AfterMath_Real&Imag.csv')
print(f"Checking existence of {file_path}:")
print(os.path.isfile(file_path))

