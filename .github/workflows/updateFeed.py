import os
import re
import json
import hashlib
from datetime import datetime


CHANNEL_NAME = "main"
CHANGELOG = os.environ.get("AUTOMATION_CHANGELOG")

# Normalize line endings to LF in case the file is checked out with CRLF
def get_lf_sha1(file_path):
    with open(file_path, 'rb') as open_file:
        content = open_file.read()
    content = content.replace(b'\r\n', b'\n')
    sha1 = hashlib.sha1()
    sha1.update(content)
    return sha1.hexdigest()


def main():
    with open("DependencyControl.json") as f:
        data = json.load(f)

    # Macros
    for macro_name, macro in data["macros"].items():
        macro_channel = macro["channels"][CHANNEL_NAME]
        # Update file hashes
        for file in macro_channel["files"]:
            old_hash = file["sha1"]
            filename = file["name"]
            path = f"macros/{macro_name}{filename}"
            new_hash = get_lf_sha1(path)
            if old_hash != new_hash:
                file["sha1"] = new_hash
                print(f"Updating hash for {path} from {old_hash} to {new_hash}")

        # Update macro version
        old_version = macro_channel["version"]
        main_file = macro_channel["files"][0]["name"]
        if main_file == ".moon" or main_file == ".lua":
            file_path = f"macros/{macro_name}{main_file}"
            with open(file_path) as f:
                content = f.read()
            # Try and extract new version from file
            new_version = re.search(r"\s*script_version\s*=\s*\"([^\"]*)\"", content)
            if new_version:
                new_version = new_version.group(1)
                if new_version != old_version:
                    macro_channel["version"] = new_version
                    macro_channel["released"] = datetime.today().strftime('%Y-%m-%d')
                    print(f"Updating version for {macro_name} from {old_version} to {new_version}")
                    if CHANGELOG:
                        macro["changelog"][new_version] = CHANGELOG.split("\n")
            else:
                print(f"Couldn't find version for {macro_name} in {file_path}")
        else:
            print(f"First file {macro_name} for isn't a .lua or .moon file, skipping version update")

    # Modules
    for module_name, module in data["modules"].items():
        module_channel = module["channels"][CHANNEL_NAME]
        # Update file hashes
        for file in module_channel["files"]:
            old_hash = file["sha1"]
            filename = file["name"]
            if filename.endswith((".moon", ".lua")):
                path = f"modules/{module_name.replace('.', '/')}{filename}"
                new_hash = get_lf_sha1(path)
                if old_hash != new_hash:
                    file["sha1"] = new_hash
                    print(f"Updating hash for {path} from {old_hash} to {new_hash}")
        # Update module version
        old_version = module_channel["version"]
        main_file = module_channel["files"][0]["name"]
        if main_file == ".moon" or main_file == ".lua":
            file_path = f"modules/{module_name.replace('.', '/')}{main_file}"
            with open(file_path) as f:
                content = f.read()
            # Try and extract new version from file
            new_version = re.search(r"\s*module_version\s*=\s*\"([^\"]*)\"", content)
            if new_version:
                new_version = new_version.group(1)
                if new_version != old_version:
                    module_channel["version"] = new_version
                    module_channel["released"] = datetime.today().strftime('%Y-%m-%d')
                    print(f"Updating version for {module_name} from {old_version} to {new_version}")
                    if CHANGELOG:
                        module["changelog"][new_version] = CHANGELOG.split("\n")
            else:
                print(f"Couldn't find version for {module_name} in {file_path}")
        else:
            print(f"First file {module_name} for isn't a .lua or .moon file, skipping version update")

    with open("DependencyControl.json", "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=4)


if __name__ == "__main__":
    main()
