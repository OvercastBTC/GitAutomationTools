# Step-by-Step Guide for Setting Up PeepAHK Repository

This guide provides the exact steps to set up the PeepAHK repository in your AutoHotkey environment, focusing on creating a local repository that tracks the upstream source while maintaining your preferred branch name.

## Initial Setup

1. **Navigate to the AutoHotkey directory**:
   ```bash
   cd ~/AppData/Local/Programs/AutoHotkey/v2
   ```

2. **Create the Peep directory** (if it doesn't exist):
   ```bash
   cd Lib
   mkdir -p ../Peep
   cd ../Peep
   ```

## Repository Setup Method 1: Direct Cloning

This is the recommended and simplest approach.

1. **Clone the repository** (either the original or your fork):
   ```bash
   # Clone from your fork
   git clone https://github.com/OvercastBTC/PeepAHK.git
   # OR clone directly from original
   # git clone https://github.com/GroggyOtter/PeepAHK.git
   ```

2. **Navigate to the cloned repository**:
   ```bash
   cd PeepAHK
   ```

3. **Add the upstream repository** (if you cloned from your fork):
   ```bash
   git remote add upstream https://github.com/GroggyOtter/PeepAHK.git
   ```

4. **Verify remote repositories**:
   ```bash
   git remote -v
   ```

5. **Create a local master branch** (if you want to use `master` instead of `main`):
   ```bash
   git checkout -b master
   ```

6. **Set tracking to upstream/main**:
   ```bash
   git branch --set-upstream-to=upstream/main master
   ```

7. **Verify the tracking is set up correctly**:
   ```bash
   git branch -vv
   ```

## Repository Setup Method 2: Manual Initialization

Use this if you need more control over the setup process.

1. **Initialize a new Git repository**:
   ```bash
   git init
   ```

2. **Add the remote repository**:
   ```bash
   git remote add origin https://github.com/GroggyOtter/PeepAHK.git
   ```

3. **Fetch the remote repository**:
   ```bash
   git fetch origin
   ```

4. **Create a local master branch that tracks the remote main branch**:
   ```bash
   git checkout -b master origin/main
   ```

5. **Verify the setup**:
   ```bash
   git branch -vv
   ```

## Including the Library in Your Scripts

After setting up the repository, you can include the library in your AutoHotkey scripts:

```autohotkey
#Requires AutoHotkey v2.0
#Include <../Peep/PeepAHK/script/Peep.v2>

; Your script code here
```

## Keeping Your Repository Updated

To get the latest updates from the original repository:

```bash
# Make sure you're on your master branch
git checkout master

# Fetch and merge updates from upstream
git fetch upstream
git merge upstream/main

# If you have a fork and want to update it as well
git push origin master
```

## Troubleshooting

If you encounter the error "Script library not found" with the include path, verify:

1. The PeepAHK repository is correctly cloned in the `C:\Users\bacona\AppData\Local\Programs\AutoHotkey\v2\Peep\` directory
2. The `script` folder exists inside the repository and contains `Peep.v2`
3. Your include path matches the actual file structure
