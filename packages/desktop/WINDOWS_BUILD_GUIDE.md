# Formatica Windows Build Guide

This guide explains how to build the Windows version of Formatica using GitHub Actions.

## 🚀 How to Build

### Step 1: Push Changes to GitHub
Commit and push the new workflow file to your `main` branch:

```powershell
git add .
git commit -m "Add Windows build workflow"
git push origin main
```

### Step 2: Trigger Build Manually
1. Go to your repository on GitHub.
2. Click on the **Actions** tab.
3. Select **"Build Formatica Windows"** from the sidebar.
4. Click the **"Run workflow"** dropdown button and click **"Run workflow"**.
5. Wait for the build to complete (usually 10-15 minutes).

### Step 3: Download & Install
1. Once the build is finished, click on the workflow run.
2. Scroll down to the **Artifacts** section at the bottom.
3. Download `Formatica-Windows-Exe` or `Formatica-Windows-Installer`.
4. Extract the ZIP and run the `.exe` or `.msi` file.

---

## 📦 Creating an Official Release

If you want the `.exe` to be automatically attached to a GitHub Release:

1. Create a tag for your version (e.g., `v1.0.0`):
   ```powershell
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
2. GitHub Actions will detect the tag, build the app, and create a new Release with the `.exe` and `.msi` files attached.

---

## 🛠 Troubleshooting

- **Build fails at "Install dependencies"**: Ensure `packages/desktop/package.json` is correctly committed and all dependencies are valid.
- **Build fails at "Build for Windows"**: This is usually a Rust compilation error. Check the logs in the Actions tab for specific error messages (e.g., missing crates or syntax errors).
- **No artifacts found**: Ensure the paths in `.github/workflows/build-windows.yml` match the output of `tauri build`. (For Tauri 2.0, these are usually in `src-tauri/target/release/bundle/`).
