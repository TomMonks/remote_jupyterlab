# Remote JupyterLab launcher

Small Bash scripts for starting JupyterLab on a remote Linux machine and opening it securely in a local web browser through an SSH tunnel.

The repository has two launcher variants. They differ in both their SSH connection method and their environment manager:

| Directory | Intended setup | SSH connection | Environment activation |
|---|---|---|---|
| `ssh-config/` | Personal/research Linux machines | An SSH host alias such as `ssh mike`, normally configured in `~/.ssh/config` | **Mamba/Miniforge**: `source ~/miniforge3/bin/activate <environment>` |
| `openstack-pem/` | Student OpenStack Linux images | A direct IP address, `ubuntu` user, and PEM private key | **Conda/Miniconda**: `source ~/.miniconda3/bin/activate <environment>` |

> Do not commit a real PEM/private-key file or a personal configuration file to this repository.

## Repository layout

```text
.
├── ssh-config/
│   ├── launch_jupyter.sh
│   └── example.conf
├── openstack-pem/
│   ├── launch_jupyter.sh
│   └── student_jupyter.conf.example
└── README.md
```

## How it works

Each launcher performs two jobs:

1. It creates an SSH tunnel from a port on the local computer to the same port on the remote Linux machine.
2. It connects to the remote machine, activates the required Mamba or Conda environment, changes into an optional working directory, and starts JupyterLab without opening a remote browser.

For example, with port `11464`, the SSH tunnel maps:

```text
local computer:  localhost:11464  ->  remote Linux machine: localhost:11464
```

When Jupyter displays a URL containing a token, open that URL in a browser on the **local** computer. Do not try to open a browser on the remote Linux image.

## SSH-config and Mamba

Use `ssh-config/` for personal or research Linux machines that you normally access with a configured SSH host name, for example:

```bash
ssh mike
```

This version is designed for machines using **Miniforge/Mamba**. It activates the requested environment with:

```bash
source ~/miniforge3/bin/activate <environment_name>
```

The short host name, hostname/IP address, remote username, and usually the SSH identity file are normally held in `~/.ssh/config` on your local computer.

An example local SSH configuration is:

```sshconfig
Host mike
    HostName 192.168.1.50
    User myusername
    IdentityFile ~/.ssh/id_ed25519
```

### Configuration

Create or adapt a configuration file such as `my_project.conf`:

```ini
REMOTE_HOST=mike
ENV_NAME=base
PORT=11464
REMOTE_DIR=Documents/code/my-project
```

| Setting | Meaning |
|---|---|
| `REMOTE_HOST` | An SSH host alias, such as `mike`, or a hostname |
| `ENV_NAME` | Mamba/Conda environment containing JupyterLab |
| `PORT` | Local and remote port used for JupyterLab |
| `REMOTE_DIR` | Optional directory to open when JupyterLab starts |

### Run

From the `ssh-config/` directory:

```bash
chmod +x launch_jupyter.sh
./launch_jupyter.sh -f my_project.conf
```

You can override individual values at the command line:

```bash
./launch_jupyter.sh -h mike -e my_environment -p 11464 -d Documents/code/my-project
```

## OpenStack PEM and Conda

Use `openstack-pem/` for module Linux images where you have:

- A remote IP address
- A remote username, normally `ubuntu`
- A PEM private key downloaded or supplied when the image/key pair was created

This version is designed for the student images, which use **Conda installed through Miniconda**. It activates the environment with:

```bash
source ~/.miniconda3/bin/activate <environment_name>
```

The script uses a command of the following form internally:

```bash
ssh -i your_key.pem ubuntu@10.121.4.123
```

### First-time setup

1. Put `launch_jupyter.sh`, the configuration file, and your PEM key in a suitable directory on your **local** computer.
2. Copy the example configuration:

   ```bash
   cp student_jupyter.conf.example student_jupyter.conf
   ```

3. Edit `student_jupyter.conf` to enter the IP address and PEM key filename.
4. Restrict access to the PEM key:

   ```bash
   chmod 600 your_pem_key_name.pem
   ```

5. Make the launcher executable:

   ```bash
   chmod +x launch_jupyter.sh
   ```

### Configuration

A student configuration file looks like this:

```ini
REMOTE_HOST=10.121.4.123
REMOTE_USER=ubuntu
PEM_KEY=./your_pem_key_name.pem
ENV_NAME=hds_python
PORT=11464
REMOTE_DIR=hpdm171
```

| Setting | Meaning |
|---|---|
| `REMOTE_HOST` | IP address of the student Linux image |
| `REMOTE_USER` | Username on the image; normally `ubuntu` |
| `PEM_KEY` | Path to the local private PEM key file |
| `ENV_NAME` | Conda environment containing JupyterLab |
| `PORT` | Local and remote port used for JupyterLab |
| `REMOTE_DIR` | Directory on the image containing the module materials |

### Run

From the `openstack-pem/` directory:

```bash
./launch_jupyter.sh -f student_jupyter.conf
```

Or, if the script has not yet been marked executable:

```bash
bash launch_jupyter.sh -f student_jupyter.conf
```

The terminal should print a Jupyter URL similar to:

```text
http://localhost:11464/lab?token=...
```

Copy the complete URL into a browser on the local computer. Keep the terminal window open while using JupyterLab. Press `Ctrl+C` when finished; the script then closes the SSH tunnel.

## Changing options

Both scripts allow values to be supplied on the command line:

```bash
./launch_jupyter.sh \
  -f student_jupyter.conf \
  -e hds_python \
  -p 11464 \
  -d hpdm171
```

| Option | Meaning |
|---|---|
| `-f` | Path to a configuration file |
| `-e` | Mamba/Conda environment name |
| `-p` | JupyterLab port |
| `-d` | Remote working directory |
| `-h` | Remote SSH host or IP address |
| `-i` | PEM key path; OpenStack script only |
| `-u` | Remote username; OpenStack script only |

## Security and Git

A PEM file is a private SSH key. Anyone who possesses it may be able to access the matching remote Linux image, so it must remain private.

Add the following to `.gitignore`:

```gitignore
# Private SSH / cloud keys
*.pem
*.key

# Personal machine or student connection details
student_jupyter.conf
*.local.conf
```

Commit the safe example configuration file, but do not commit:

- Any `*.pem` or `*.key` file
- A student’s completed `student_jupyter.conf`
- Jupyter token URLs
- Private IP addresses if they should not be shared outside the module

## Troubleshooting

### `Permission denied (publickey)`

Check that the correct PEM file is named in `PEM_KEY`, that it has restrictive permissions, and that the IP address and username are correct:

```bash
chmod 600 your_pem_key_name.pem
ssh -i your_pem_key_name.pem ubuntu@YOUR_IP_ADDRESS
```

### `.../.miniconda3/bin/activate: No such file or directory`

The default student-image installation path is:

```bash
~/.miniconda3/bin/activate
```

Check the actual path on the remote machine with:

```bash
which conda
conda env list
```

If necessary, update the activation path in the OpenStack launcher script.

### `Address already in use`

The selected port is already being used locally or remotely. Change it consistently in the configuration file, for example:

```ini
PORT=11465
```

Then reconnect and open:

```text
http://localhost:11465
```

### The browser cannot connect

- Make sure the launcher terminal remains open.
- Use `http://localhost:PORT`, not the remote image IP address.
- Copy the full tokenised Jupyter URL printed in the terminal.
- Confirm that the SSH tunnel and JupyterLab use the same `PORT` value.
