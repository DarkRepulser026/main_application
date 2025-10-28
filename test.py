import os

def print_tree(start_path, prefix=""):
    # Lấy danh sách các file và thư mục, sắp xếp theo tên
    items = sorted(os.listdir(start_path))
    entries = [item for item in items if not item.startswith('.')]  # bỏ file ẩn

    for i, name in enumerate(entries):
        path = os.path.join(start_path, name)
        connector = "└── " if i == len(entries) - 1 else "├── "
        print(prefix + connector + name)

        if os.path.isdir(path):
            extension = "    " if i == len(entries) - 1 else "│   "
            print_tree(path, prefix + extension)

if __name__ == "__main__":
    root_dir = input("Enter project folder path: ").strip()
    if not os.path.exists(root_dir):
        print("❌ Folder not found.")
    else:
        print(f"\n📁 Folder tree for: {root_dir}\n")
        print_tree(root_dir)
