import os

# Define the file structure as a list of file paths
# The script will create the necessary directories for each file.
file_structure = [
    # Main app configuration
    "lib/app/config/app_router.dart",
    "lib/app/config/app_theme.dart",

    # Models
    "lib/app/models/patient_model.dart",
    "lib/app/models/doctor_model.dart",
    "lib/app/models/product_model.dart",
    "lib/app/models/transaction_model.dart",

    # Services
    "lib/app/services/firestore_service.dart",
    
    # Core Widgets (optional but good practice)
    "lib/app/widgets/.gitkeep",

    # Features
    # Dashboard
    "lib/features/dashboard/screens/dashboard_screen.dart",

    # Patient Feature
    "lib/features/patient/providers/patient_providers.dart",
    "lib/features/patient/screens/add_edit_patient_screen.dart",
    "lib/features/patient/screens/patient_list_screen.dart",

    # Doctor Feature (placeholders)
    "lib/features/doctor/providers/doctor_providers.dart",
    "lib/features/doctor/screens/add_edit_doctor_screen.dart",
    "lib/features/doctor/screens/doctor_list_screen.dart",

    # Product Feature (placeholders)
    "lib/features/product/providers/product_providers.dart",
    "lib/features/product/screens/add_edit_product_screen.dart",
    "lib/features/product/screens/product_list_screen.dart",
    
    # Transaction Feature (placeholders)
    "lib/features/transaction/providers/transaction_providers.dart",
    "lib/features/transaction/screens/add_transaction_screen.dart",
    "lib/features/transaction/screens/transaction_list_screen.dart",
]

# The main.dart file already exists, so we handle it separately to avoid overwriting.
main_dart_path = "lib/main.dart"

def create_project_structure():
    """Creates the folders and empty files for the project."""
    # Ensure lib directory exists
    if not os.path.exists("lib"):
        print("Error: 'lib' directory not found. Please run this script from the root of a Flutter project.")
        return

    # Create all files and their parent directories
    for path in file_structure:
        # Normalize path for the current OS
        normalized_path = os.path.normpath(path)
        
        # Get the directory part of the path
        directory = os.path.dirname(normalized_path)
        
        # Create directories if they don't exist
        if directory and not os.path.exists(directory):
            os.makedirs(directory)
            print(f"Created directory: {directory}")
            
        # Create an empty file
        if not os.path.exists(normalized_path):
            with open(normalized_path, 'w') as f:
                # You can add default boilerplate here if needed
                # For now, we just create an empty file.
                pass 
            print(f"Created file: {normalized_path}")
        else:
            print(f"Skipped (already exists): {normalized_path}")
            
    # Check for main.dart
    if os.path.exists(main_dart_path):
        print(f"Skipped (already exists): {main_dart_path}")
    else:
        print(f"Warning: {main_dart_path} not found. A Flutter project should have this file.")

    print("\n✅ Project structure generated successfully!")

if __name__ == "__main__":
    create_project_structure()