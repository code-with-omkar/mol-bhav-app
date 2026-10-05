# MolBhav Progress - Option 2: Claude API + Desktop Shortcut

**Direct artifact updates via desktop icon click**

## Prerequisites

✅ **Required:**
- Node.js installed (download from https://nodejs.org/)
- Claude API key (get from https://console.anthropic.com)
- Windows 10/11

## Step 1: Get Your API Key

1. Go to https://console.anthropic.com
2. Navigate to **API Keys** section
3. Click **Create Key**
4. Copy the key (starts with `sk-ant-...`)
5. Keep it safe—don't share it

## Step 2: Set Environment Variable (One-time setup)

### Windows 11/10:

1. Press **Windows Key + X** → Select **System**
2. Click **Advanced system settings** (right side)
3. Click **Environment Variables** button (bottom)
4. Click **New...** (under User variables)
5. Fill in:
   - **Variable name:** `CLAUDE_API_KEY`
   - **Variable value:** `sk-ant-your-actual-key-here`
6. Click **OK** three times
7. **Close all open command prompts** and restart

**Verify it worked:**
- Open Command Prompt
- Type: `echo %CLAUDE_API_KEY%`
- Should show your key (not blank)

## Step 3: Save Files

Download these 3 files:

1. **`MolBhav_Progress_Template.md`** → Save to:
   ```
   C:\Users\[YourUsername]\molbhav_progress.md
   ```

2. **`molbhav-update-artifact.js`** → Save to a folder, e.g.:
   ```
   C:\Users\[YourUsername]\molbhav\molbhav-update-artifact.js
   ```

3. **`MolBhav-Update.bat`** → Save in same folder as .js file:
   ```
   C:\Users\[YourUsername]\molbhav\MolBhav-Update.bat
   ```

Replace `[YourUsername]` with your actual Windows username.

## Step 4: Create Desktop Shortcut

### Quick Method:

1. **Right-click on Desktop** → **New** → **Shortcut**
2. In "Location" field, paste:
   ```
   C:\Users\[YourUsername]\molbhav\MolBhav-Update.bat
   ```
3. Click **Next**
4. Name: `MolBhav Update`
5. Click **Finish**

### Change Icon (Optional):

1. Right-click shortcut → **Properties**
2. Click **Change Icon...**
3. Pick any icon (or use Windows defaults)
4. Click **OK** → **Apply** → **OK**

## Step 5: Test It

1. **Edit** `molbhav_progress.md` with your latest metrics:
   ```markdown
   API Progress: 98%
   App Progress: 96%
   Blockers: None
   ```

2. **Double-click** the desktop shortcut

3. **Should see:**
   - Terminal window showing extracted metrics
   - Browser opens artifact URL
   - Message: "✅ Update sent to Claude"

4. **Go to the artifact** → Claude updates progress bars + timestamp

## Step 6: Workflow

Each time you update progress:

```
1. Edit C:\Users\[YourUsername]\molbhav_progress.md
   (Update API %, App %, migrations, blockers, etc.)
   
2. Double-click "MolBhav Update" desktop shortcut
   
3. Terminal shows extracted metrics
   
4. Browser opens artifact
   
5. Claude automatically updates the dashboard
   
6. Done!
```

## Troubleshooting

### "API key not found"
- Make sure environment variable is set (see Step 2)
- Restart all Command Prompt windows
- Verify with: `echo %CLAUDE_API_KEY%`

### "Node.js not found"
- Install from: https://nodejs.org/
- Restart your computer
- Test: Open Command Prompt, type `node -v`

### "Progress file not found"
- Make sure file exists at: `C:\Users\[YourUsername]\molbhav_progress.md`
- Check file name is exactly: `molbhav_progress.md`

### "API error 401"
- API key is wrong or expired
- Get a new key from https://console.anthropic.com
- Update environment variable

### Terminal closes too fast
- All bat files pause at end, press Enter to close
- If it's closing immediately, API key might be invalid

## File Locations

**Example with username "omkar":**

```
C:\Users\omkar\molbhav_progress.md           ← Edit this
C:\Users\omkar\molbhav\MolBhav-Update.bat    ← Click shortcut to this
C:\Users\omkar\molbhav\molbhav-update-artifact.js
```

## What Happens Behind the Scenes

1. Batch file runs Node.js script
2. Script reads your `molbhav_progress.md`
3. Extracts: API %, App %, migrations, blockers
4. Calls Claude API with these metrics
5. Claude updates the artifact with new numbers
6. Browser opens artifact to show results

---

**Questions?** Modify paths in `.bat` file if you saved things differently, then save and test.
