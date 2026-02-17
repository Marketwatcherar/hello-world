# hello-world

## Important first clarification

You **do not have to use `/workspace/hello-world`** on your personal computer.
That path is commonly used in cloud/dev containers.
On your own machine, you can use any folder, for example:
- `~/workspace/hello-world` (recommended)
- `~/Documents/hello-world`

So yes: if you cannot find `/workspace`, you can create your own workspace folder locally.

---

## Beginner guide (zsh) — create folder, find repo, run app

### 0) Open terminal and switch to zsh

```zsh
zsh
```

### 1) Create your own workspace folder (safe on any machine)

```zsh
mkdir -p ~/workspace
cd ~/workspace
pwd
```

You should now see a path like `/home/<you>/workspace` (Linux) or `/Users/<you>/workspace` (macOS).

### 2) Place this repository in that folder

#### Option A: Clone from GitHub (best)

```zsh
cd ~/workspace
git clone https://github.com/<your-user>/<your-repo>.git hello-world
cd hello-world
```

#### Option B: You downloaded ZIP

```zsh
cd ~/Downloads
unzip hello-world.zip
mv hello-world ~/workspace/hello-world
cd ~/workspace/hello-world
```

### 3) Verify repository is complete

```zsh
pwd
ls -la
ls -la .git
```

You should see:
- `Cats/`
- `scripts/`
- `README.md`
- `IMPLEMENTATION_PACKAGE.md`
- `.git/`

You can also run:

```zsh
./scripts/check_repo.zsh
```

### 4) Start the app server

```zsh
./scripts/run_app.sh
```

Open in browser:
- `http://localhost:8080/Cats/`
- fallback: `http://localhost:8080/Cats/index.html`

### 5) Quick smoke test

In another terminal tab:

```zsh
cd ~/workspace/hello-world
./scripts/test_app.sh
```

### 6) If you specifically want `/workspace/hello-world`

On Linux with permission to create under root:

```zsh
sudo mkdir -p /workspace
sudo chown -R "$USER":"$USER" /workspace
mkdir -p /workspace/hello-world
```

Then clone into it:

```zsh
git clone https://github.com/<your-user>/<your-repo>.git /workspace/hello-world
```

If you do not have `sudo`, just keep using `~/workspace/hello-world`.

---

## Helper script to create workspace folder

This command creates `~/workspace` and checks whether repo exists there:

```zsh
./scripts/setup_repo_folder.sh
```

Optional custom location:

```zsh
./scripts/setup_repo_folder.sh ~/Documents
```

---

## Notes
- This is a front-end prototype with simulated sync behavior.
- Backend/database implementation details are in `IMPLEMENTATION_PACKAGE.md`.
