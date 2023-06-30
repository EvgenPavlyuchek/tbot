## Example of DevSecOps Implementation - Pre-commit Hook with Gitleaks

This is a pre-commit script that includes standard pre-commit functions from GitHub, as well as Gitleaks (https://github.com/gitleaks/gitleaks). It can help you check your commits for trailing whitespace and secrets.

### Installation

To use the script, run the following command in the root folder of your GitHub project:
   ```
   curl -sSL  https://raw.githubusercontent.com/evgenpavlyuchek/devsecops/main/pre-commit.sh  | sh
   ```
or
   ```
   curl -sSL -o pre-commit.sh https://raw.githubusercontent.com/evgenpavlyuchek/devsecops/main/pre-commit.sh
   chmod +x ./pre-commit.sh
   ```

### Installation options

If you choose the first method, the script will automatically install itself in .git/hooks/pre-commit.

If you choose the second method, it will interactively ask you whether you want to install it in .git/hooks/pre-commit. In this case, you can cancel the installation if desired.

In both cases, Gitleaks will be installed automatically if you have enabled the parameter.

If you encounter any issues with the installation of Gitleaks within the script, which may require additional privileges, you can always install it manually by following the recommendations on the official repository:
   ```
   https://github.com/gitleaks/gitleaks
   ```
Once Gitleaks is installed, you can run the script again, and it will detect the existing Gitleaks installation and display the results of checking your code.
Usage

### Usage

After installation in .git/hooks/pre-commit, whenever you make a commit in your repository, the pre-commit hook script will be executed. It will run Gitleaks to check for secrets and also perform a check for trailing whitespace. If any errors are found, the commit will be rejected; otherwise, the commit will proceed.

### Requirements

The script can be run on Linux, macOS, or Windows using Git Bash. The installation has been tested on Linux and MacOS, but it may require additional privileges.

Remember to review any scripts before executing them.

### Parameters

The script has two parameters. Use the following commands to enable or disable checking for secrets and trailing whitespace:

   ```
   git config hooks.gitleaks true
   git config hooks.gitleaks false
   ```

   ```
   git config hooks.whitespace true
   git config hooks.whitespace false
   ```