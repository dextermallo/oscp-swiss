
# OSCP Swiss

Swiss Knife on your Kali Linux to help you move fast.

## 1. About OSCP Swiss

OSCP Swiss is a collection of functions, aliases, and variables designed to boost productivity on Kali Linux. It helps you automate repetitive tasks, manage your workspace, and provide the necessary tools to perform penetration testing.

For example, the command `ship` is a one-liner command to drop a file from your Kali to the target machine. For example:

```bash
ship ./linpeas.sh
# The command will automatically host the file and copy the command to fetch it to your click board automatically.
# All you need is to paste it on the target machine :)
```

Here is a quick demo for shipping multiple files at a time:

https://github.com/user-attachments/assets/895d3a44-56a9-437e-99b2-85262815b2ff

> ![tips]
> It is powerful when you have a set of frequently used tools. For example:
> ```bash
> # under /script/extension.sh
> # I have a set of utilities that I often use for enumerate on Windows
> windows_family=( $windows_mimikatz_x64 $windows_winpeas_x64 $windows_powerview $windows_powerup ... )
> 
> # I can easily get all of them on the target VM by:
> ship -t windows $windows_family
> ```

There are other commands to help you with the enumeration, exploitation, and post-exploitation. See [3. Usage](#3-usage). You can also customize the settings and add your own scripts and utilities to the Swiss Knife. See [4. Development & Customization](#4-development--customization). 

## 2. Getting Started

### 2.1. About Environments
>[!NOTE]
> Tested on `Kali 6.8.11-1kali2 (2024-05-30)`, virtualizing using `UTM 4.4.5` on MacBook Pro (M2, Sonoma 14.5)

>[!Caution]
> The script is designed to work on Kali Linux. It may not work on other Linux distributions.
> the scripts are developed and tested under Zsh (v5.9). There might be some issues if you are using Bash. PRs and Issues are welcome!

### 2.2. Prerequisites

You will need to install the following packages. Additionally, you may need to check the script before the run if you are not using Kail (version ≥ 6.8.11).

> [!CAUTION]
> Some of the commands may need additional libraries or packages. 
> You will see a warning message if you need to install additional packages:
> ![swiss](demo/external-pacakge-hint.png)

```sh
jq              # (required) parsing configuration
xclip           # (required) click board
docker          # (optional) used in the command `svc docker`
docker-compose  # (optional) used in the command `svc bloodhound`
pygmentize      # (optional) replace `cat` command with syntax highlighting
rlwrap          # (optional) used in the command `listen` for supporting arrow keys
```

### 2.3. Installation

```bash
# Download and put it in the home directory
git clone https://github.com/dextermallo/oscp-swiss.git ~

# copy the example settings to the settings.json
# you can customize the settings.json
cd ~/oscp-swiss & cp example.settings.json settings.json

# Add the following line to your .zshrc or .bashrc
echo "source ~/oscp-swiss/script/oscp-swiss.sh" >> ~/.zshrc

# All done! Restart your terminal or run the following command
source ~/.zshrc

# (Optional) If you already have any customized scripts, utilities, or wordlists, you can put them in the following directories:
mv ~/my-script.sh ~/oscp-swiss/private/

# you can also find your customized scripts by running the command:
swiss
```

### 2.4. Updates

```bash
# pull the latest changes
cd ~/oscp-swiss & git pull

# noted that you may need to update your settings.json if there are any changes
# and restart your terminal
source ~/.zshrc
```

## 3. Usage

> ![Tip]
> To keep the README concise, the following sections only provide a short description and examples. You can find more detailed information by running the command `<command> -h` or read it under the `/script` directory.

Functions are broken down into modules and main functions. For more information, see [4. Development & Customization](#4-development--customization).

>[!TIP]
> You can find configurations for functions under `/settings.json`. For example:
> ```json
> {
>     "global_settings": { ... },
>     "functions": {
>         "wpscan": {
>             "token": "your_token_here"
>         }
>     }
> }
> ```

### 3.1. Main Functions

#### 3.1.1. `swiss`

#### 3.1.2. `cd` (customized)

Customized `cd` with `cd -` (to move to the previous directory) and `cd $file` (by default, cd to a file will fail. The customized `cd` will move to the directory of the file.)

#### 3.1.3. `xfreerdp` (customized)

#### 3.1.4. `wpscan` (customized)

#### 3.1.5. `cat` (customized)

#### 3.1.6. `ls` (customized)

#### 3.1.7. `i`: get the default IP address

![command-i](demo/command-i.gif)

#### 3.1.8. `svc`: start service without pain

https://github.com/user-attachments/assets/66cde72a-46b2-4bf1-9e6a-3c7711d43269

#### 3.1.9. `ship`: killer tool for file transfer

https://github.com/user-attachments/assets/ee3838a1-a35e-410b-9e35-a9b404b68247

#### 3.1.10. `listen`: wrap the nc listener.

https://github.com/user-attachments/assets/6bb08184-f529-4a7b-b37b-5c1e18a4f1c4

#### 3.1.7. About Variables

#### 3.1.8. About Extension


### 3.5. Module/bruteforce

## 4. Development & Customization

Here are the key structures for swiss:

```md
.
├── data                 # (Private) common data/material for testing 
│   ├── ...
│   └── test.jpg
├── doc 
│   ├── cheatsheet       # (Public) quick cheatsheet for copy-paste, review, etc. See command `cheatsheet`.
│   └── utils-note.md    # (Public) notes for utilities. See command `memory`.
├── private              # (Private) you can put your customized script, .ovpn file, etc.
│   ├── myscript.sh
│   └── lab.ovpn
├── script               # (Public) main script for swiss
│   ├── module           # (Public) function module
│   ├── target           # (Public) scripts for the target side
│   ├── alias.sh         # (Public) alias for native resources (i.e., binaries, executables) on Kali
│   ├── extension.sh     # (Public) alias for external resources
│   ├── installation.sh  # (Public) (WIP) installation for creating wordlist, downloading binaries, etc.
│   ├── oscp-swiss.sh    # (Public) main script
│   └── utils.sh  
├── utils                # (Private) put your binaries, compiled files, utilities (e.g., pspy)
│   └── ...
├── wordlist             # (Private) custom wordlist
└── settings.json
```

## 5. License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

<!-- ## Acknowledgments -->
