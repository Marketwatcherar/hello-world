# hello-world

## Start the app (quick)

From repository root:

```zsh
./run_app.sh
```

Open:
- `http://localhost:8080/Cats/`

---

## Fix for this error

If you see:

```text
zsh: no such file or directory: ./scripts/run_app.sh
```

it usually means you are not inside the project folder.

### Step-by-step fix (beginner)

1. Check where you are now:
   ```zsh
   pwd
   ```

2. Go to the repository folder:
   ```zsh
   cd /workspace/hello-world
   ```

3. Check the script exists:
   ```zsh
   ls -la scripts
   ```
   You should see `run_app.sh` in the list.

4. Start the app with the new root shortcut:
   ```zsh
   ./run_app.sh
   ```

5. If the script is still missing, your local copy may be incomplete.
   Re-download or re-clone:
   ```zsh
   cd /workspace
   rm -rf hello-world
   git clone https://github.com/<your-user>/<your-repo>.git hello-world
   cd hello-world
   ./run_app.sh
   ```

---

## Verify repository structure

Run:

```zsh
./scripts/check_repo.zsh
```

This checks required files:
- `Cats/index.html`
- `scripts/run_app.sh`
- `scripts/test_app.sh`
- `README.md`
- `IMPLEMENTATION_PACKAGE.md`

---

## Test app quickly

```zsh
./scripts/test_app.sh
```

---

## Notes
- This is a front-end prototype with simulated sync behavior.
- Backend/database details are in `IMPLEMENTATION_PACKAGE.md`.


---

## Fix for Playwright screenshot error (`ERR_EMPTY_RESPONSE`)

If you see this during automated screenshots:

```text
mcp__browser_tools__run_playwright_script ... ERR_EMPTY_RESPONSE
```

it usually means the browser tool could not reach your local server at that moment.

### Why this happens
- The server process stopped before Playwright connected.
- The server was started in a way that ended when the shell command finished.
- Wrong port was forwarded or wrong URL/host was used.
- Another process already occupied the port.

### Reliable fix (step by step)

1. Start server in a persistent terminal:
   ```zsh
   cd /workspace/hello-world
   python3 -m http.server 8095 --directory /workspace/hello-world
   ```

2. In another terminal, verify server is reachable:
   ```zsh
   curl -I http://127.0.0.1:8095/Cats/
   ```
   You should get `HTTP/1.0 200 OK`.

3. In Playwright/browser tool, forward the same port (`8095`).

4. Use one of these URLs in the script:
   - `http://127.0.0.1:8095/Cats/`
   - `http://localhost:8095/Cats/`

5. If it still fails, test direct file route:
   - `http://127.0.0.1:8095/Cats/index.html`

6. If needed, change to a clean port:
   ```zsh
   python3 -m http.server 8096 --directory /workspace/hello-world
   ```
   Then forward/use `8096` in Playwright.

### Quick diagnostics checklist

```zsh
pwd
ls -la /workspace/hello-world/Cats/index.html
lsof -i :8095
curl -I http://127.0.0.1:8095/Cats/
```

If `curl` is 200 but Playwright still fails, it is usually a browser-container connectivity issue, not an app code issue.


---

## If GitHub says this branch has conflicts in `Cats/index.html` or `README.md`

Use these exact commands locally:

```zsh
cd /workspace/hello-world
git status
```

1. Update your branch with the latest target branch (example: `main`):

```zsh
git fetch origin
git merge origin/main
```

2. If conflicts appear, open the files and remove conflict markers:
- `<<<<<<<`
- `=======`
- `>>>>>>>`

Keep the combined final content you want.

3. Verify no conflict markers remain:

```zsh
rg "^(<<<<<<<|=======|>>>>>>>)" Cats/index.html README.md
```

4. Finalize resolution:

```zsh
git add Cats/index.html README.md
git commit -m "Resolve merge conflicts in Cats/index.html and README.md"
```

5. Push your branch again:

```zsh
git push
```

If step 3 returns no output, conflicts are fully resolved.


---

## Conflict resolution outcome for `Cats/index.html` and `README.md`

The merge conflicts you pasted are resolved by keeping the **EFL-enhanced version** and dropping only conflict markers.

Chosen final baseline includes:
- EFL UI title and expanded teacher-friendly layout.
- Oral rubric criteria: fluency, grammatical precision, pronunciation, content/coherence.
- Written rubric criteria: task achievement, organization, grammar accuracy, vocabulary range.
- Larger controls and improved UX helpers.

Validation command (must return no output):

```zsh
rg "^(<<<<<<<|=======|>>>>>>>)" Cats/index.html README.md
```

If you still see conflicts on GitHub after local resolution, run:

```zsh
git fetch origin
git merge origin/main
rg "^(<<<<<<<|=======|>>>>>>>)" Cats/index.html README.md
git add Cats/index.html README.md
git commit -m "Resolve merge conflicts in Cats/index.html and README.md"
git push
```
