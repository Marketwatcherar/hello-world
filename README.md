# hello-world

## Beginner guide (zsh) — how to visualize the app step by step

This guide assumes you are **new to terminal usage**. Every command below is written for **z shell (zsh)**.

---

## 0) Open Terminal and switch to zsh

If your terminal is not already zsh, run:

```zsh
zsh
```

You can confirm your current shell:

```zsh
echo $SHELL
```

You should see a path ending with `zsh`.

---


## If `/workspace/hello-world` does NOT exist on your machine

Yes — that can happen. It usually means one of these:
- You did not clone the GitHub repository yet.
- You downloaded a ZIP but did not extract it.
- You are using a different base folder (not `/workspace`).

### A) Check whether the folder exists

```zsh
ls -la /workspace
```

- If you see `hello-world`, go there:
  ```zsh
  cd /workspace/hello-world
  ```
- If you do **not** see it, follow B or C below.

### B) Clone from GitHub (best option)

1. Move to `/workspace`:
   ```zsh
   cd /workspace
   ```
2. Clone (replace URL with your repo URL):
   ```zsh
   git clone https://github.com/<your-user>/<your-repo>.git hello-world
   ```
3. Enter the repo:
   ```zsh
   cd /workspace/hello-world
   ```
4. Verify files:
   ```zsh
   ls -la
   ```

### C) If you downloaded a ZIP from GitHub

1. Move to the folder where the ZIP is saved:
   ```zsh
   cd ~/Downloads
   ```
2. Extract it:
   ```zsh
   unzip hello-world.zip
   ```
3. Move extracted folder into `/workspace`:
   ```zsh
   mv hello-world /workspace/hello-world
   ```
4. Enter the repo and verify:
   ```zsh
   cd /workspace/hello-world
   ls -la
   ```

### D) Confirm it is a real git repository

```zsh
cd /workspace/hello-world
ls -la .git
```

If `.git` exists, the repo is set correctly.

---

## 1) Verify the repository is in the correct location

Run these commands exactly:

```zsh
pwd
ls -la /workspace
ls -la /workspace/hello-world
```

What you should confirm:
- `pwd` should eventually be `/workspace/hello-world`.
- `/workspace/hello-world` should exist.
- Inside that folder, you should see:
  - `Cats/`
  - `scripts/`
  - `README.md`
  - `IMPLEMENTATION_PACKAGE.md`

Now move into the repo:

```zsh
cd /workspace/hello-world
pwd
```

---

## 2) Run an automatic repository check (recommended)

We provide a checker script that confirms required files/folders exist.

```zsh
zsh ./scripts/check_repo.zsh
```

If everything is correct, it will print success messages.

---

## 3) Start the app server (safe method, avoids 404)

From `/workspace/hello-world` run:

```zsh
zsh ./scripts/run_app.sh
```

Expected output includes:
- the repo path being served
- `Open: http://localhost:8080/Cats/`

Keep this terminal window open while using the app.

---

## 4) Open and visualize the app

In your browser, open:

- `http://localhost:8080/Cats/`

If that does not load, open direct file route:

- `http://localhost:8080/Cats/index.html`

---

## 5) How to use each screen

Once the page opens, you will see tabs:
- Attendance
- Grades
- Behavior
- Family Feedback
- Sync Status

### Attendance
1. Click **Mark all Present**.
2. Set one student to **Absent** and choose **Excused**.
3. Set another student to **Tardy** and fill **minutes late**.
4. Click **Save Draft (offline)**.
5. Click **Submit & Sync**.

### Grades
1. Go to **Grades**.
2. Keep max score at `20`.
3. Fill student scores between `0` and `20`.
4. Click **Save Grades**.
5. Try an invalid score (like `25`) to see validation.

### Behavior
1. Choose a student.
2. Fill ratings from `1` to `5`.
3. Choose incident severity.
4. Click **Save Behavior**.

### Family Feedback
1. Choose a student.
2. Fill ratings from `1` to `5`.
3. Add a comment.
4. Click **Save Feedback**.

### Sync Status
1. Click **Toggle Online/Offline** to simulate no internet.
2. Save records while offline.
3. Return to **Sync Status** and confirm queue count increases.
4. Toggle back online.
5. Click **Sync now** and confirm queue goes to 0.

---

## 6) Run a quick test (automatic)

In a **new terminal tab/window**, run:

```zsh
cd /workspace/hello-world
zsh ./scripts/test_app.sh
```

This test will:
1. Start local server.
2. Check the URL returns HTTP 200.
3. Verify main tabs exist in the page.

---

## 7) If you still get 404 (easy recovery)

1. Stop any running server by pressing `Ctrl + C`.
2. Ensure you are in the right repo:

```zsh
cd /workspace/hello-world
pwd
```

3. Start server using script (not raw python command):

```zsh
zsh ./scripts/run_app.sh
```

4. Open:
- `http://localhost:8080/Cats/`
- or fallback `http://localhost:8080/Cats/index.html`

---

## 8) Stop the app

Go back to the terminal running the server and press:

- `Ctrl + C`

---

## Notes
- This is a front-end prototype with simulated sync behavior.
- Backend/database implementation details are in `IMPLEMENTATION_PACKAGE.md`.
