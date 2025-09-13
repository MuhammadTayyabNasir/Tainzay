import os
import sys
import shutil

def main():
    # --- 1. Hardcoded Path ---
    source_dir = "lib"  # Hardcoded to look in the 'lib' directory

    # Check if the lib directory exists
    if not os.path.isdir(source_dir):
        print(f"Error: The path '{source_dir}' is not a valid directory.")
        sys.exit(1)

    # Define the name for our new destination folder.
    dest_dir = "temp"

    # --- 2. Clean and Create Destination Folder ---

    # Remove the destination folder if it already exists
    if os.path.exists(dest_dir):
        print(f"Removing existing directory: '{dest_dir}'")
        shutil.rmtree(dest_dir)

    # Create the fresh destination folder
    print(f"Creating destination directory: '{dest_dir}'")
    os.makedirs(dest_dir, exist_ok=True)

    # --- 3. Find and Copy .dart Files ---

    print(f"\nSearching for .dart files in '{source_dir}' and its subfolders...")
    copied_count = 0
    for root, dirs, files in os.walk(source_dir):
        for filename in files:
            if filename.endswith(".dart"):
                source_path = os.path.join(root, filename)
                dest_path = os.path.join(dest_dir, filename)

                print(f"  Copying: {source_path}")
                shutil.copy2(source_path, dest_path)
                copied_count += 1
    
    print(f"\nSuccessfully copied {copied_count} files to '{dest_dir}'.")

    # --- 4. Rename Files in Destination Folder ---

    print(f"\nRenaming files in '{dest_dir}' from .dart to .txt...")
    renamed_count = 0
    for filename in os.listdir(dest_dir):
        if filename.endswith(".dart"):
            old_file_path = os.path.join(dest_dir, filename)
            base_name = os.path.splitext(filename)[0]
            new_file_path = os.path.join(dest_dir, base_name + ".txt")

            print(f"  Renaming: {filename} -> {base_name}.txt")
            os.rename(old_file_path, new_file_path)
            renamed_count += 1
    
    print(f"\nSuccessfully renamed {renamed_count} files.")
    print("\nDone!")

if __name__ == "__main__":
    main()