# MolBhav Progress Updater - Windows Setup

## Files You Need

1. **`MolBhav_Progress_Template.md`** - Your progress tracking file (edit this)
2. **`Update-MolBhav-Progress.ps1`** - PowerShell script (desktop icon runs this)

## Step 1: Save the Progress File

1. Download/copy `MolBhav_Progress_Template.md`
2. Save it to your home directory as:
   ```
   C:\Users\[YourUsername]\molbhav_progress.md
   ```
   - Replace `[YourUsername]` with your Windows username
   - Or save wherever you want, but remember the path

3. Update the metrics inside (API %, App %, blockers, etc.)

## Step 2: Save the PowerShell Script

1. Download/copy `Update-MolBhav-Progress.ps1`
2. Save it somewhere safe, e.g.:
   ```
   C:\Users\[YourUsername]\Scripts\Update-MolBhav-Progress.ps1
   ```
   - Create the `Scripts` folder if it doesn't exist

## Step 3: Create Desktop Shortcut

### Option A: Quick Manual (Recommended)

1. **Right-click Desktop** → New → Shortcut
2. In "Location" field, paste:
   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\[YourUsername]\Scripts\Update-MolBhav-Progress.ps1" -ProgressFile "C:\Users\[YourUsername]\molbhav_progress.md"
   ```
   - Replace both `[YourUsername]` with your actual Windows username
   - Or adjust paths if you saved files elsewhere

3. Click **Next**
4. Name it: `MolBhav Progress`
5. Click **Finish**

### Option B: Batch File Wrapper (Simpler)

1. Create a file called `MolBhav-Update.bat` on Desktop
2. Right-click → Edit, paste:
   ```batch
   @echo off
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\%USERNAME%\Scripts\Update-MolBhav-Progress.ps1" -ProgressFile "C:\Users\%USERNAME%\molbhav_progress.md"
   pause
   ```
3. Save and close
4. The .bat file is now your clickable shortcut

## Step 4: Use It

1. **Edit progress**: Open `molbhav_progress.md` in any text editor
   - Update API %, App %, blockers, latest completions
   
2. **Click icon**: Double-click the desktop shortcut
   - PowerShell runs
   - Shows progress summary in terminal
   - Opens artifact in browser
   - You manually update artifact with the new metrics

3. **Next time**: Edit the .md again → click icon → repeat

## Troubleshooting

### "PowerShell execution policy" error
- Right-click shortcut → Properties
- In Target field, make sure it includes:
  ```
  -ExecutionPolicy Bypass
  ```

### "Progress file not found"
- Check the path in the script matches where you saved `molbhav_progress.md`
- Path should be: `C:\Users\[YourUsername]\molbhav_progress.md`

### Terminal closes too fast
- The script has `pause` at the end, so it waits for you to press a key
- If it still closes, add `-NoExit` to the PowerShell command

## Full Path Example

If your username is `omkar`:

**Shortcut Target:**
```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\omkar\Scripts\Update-MolBhav-Progress.ps1" -ProgressFile "C:\Users\omkar\molbhav_progress.md"
```

**Script location:** `C:\Users\omkar\Scripts\Update-MolBhav-Progress.ps1`  
**Progress file:** `C:\Users\omkar\molbhav_progress.md`

---

## Workflow

```
1. Edit molbhav_progress.md with latest metrics
   ↓
2. Click desktop icon
   ↓
3. PowerShell shows summary + opens artifact
   ↓
4. Manually update artifact dashboard with new numbers
   ↓
5. Done! Next session, repeat from step 1
```

---

**Need help?** Modify the PowerShell script path or .md file path in the shortcut target, then save and test.
