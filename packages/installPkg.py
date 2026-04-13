import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "dotbot" / "lib" / "pyyaml" / "lib"))

import yaml
import subprocess


def read_yaml(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def install_packages(packages):
    if not packages:
        return
    package_list = ' '.join(packages)
    cmd = f"sudo pacman -S --needed {package_list}"
    subprocess.run(cmd, shell=True)


def install_yay(packages):
    if not packages:
        return
    package_list = ' '.join(packages)
    cmd = f"yay -S --needed {package_list}"
    subprocess.run(cmd, shell=True)


def show_menu():
    print("\n========== 菜单 ==========")
    print("1. pacman")
    print("2. yay")
    print("q. 退出")
    print("==========================")
    return input("请选择 (1/2/q): ").strip()


def show_package_info(pkg_type, packages):
    print(f"\n=== {pkg_type} 包信息 ===")
    print("包列表:")
    for pkg in packages:
        print(f"  - {pkg}")
    if pkg_type == "pacman":
        cmd = f"sudo pacman -S --needed {' '.join(packages)}"
    else:
        cmd = f"yay -S --needed {' '.join(packages)}"
    print(f"执行命令: {cmd}")
    print("==========================")
    return input("确认安装? (是/否): ").strip()


def main():
    result = read_yaml("packages.yaml")
    packages = result.get('packages', {})

    while True:
        choice = show_menu()

        if choice == '1' or choice.lower() == 'pacman':
            if 'pacman' not in packages or not packages['pacman']:
                print("没有 pacman 包")
                continue
            confirm = show_package_info("pacman", packages['pacman'])
            if confirm in ['是', 'yes', 'y', 'Y']:
                install_packages(packages['pacman'])
                print("安装完成!")
            else:
                print("取消安装")

        elif choice == '2' or choice.lower() == 'yay':
            if 'yay' not in packages or not packages['yay']:
                print("没有 yay 包")
                continue
            confirm = show_package_info("yay", packages['yay'])
            if confirm in ['是', 'yes', 'y', 'Y']:
                install_yay(packages['yay'])
                print("安装完成!")
            else:
                print("取消安装")

        elif choice == 'q' or choice.lower() == '退出':
            print("退出程序")
            break

        else:
            print("无效选择")


if __name__ == "__main__":
    main()
