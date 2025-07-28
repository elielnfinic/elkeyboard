# ElKeyboard App Group Setup

## Issue
If you're seeing this error:
```
container_create_or_lookup_app_group_path_by_app_group_identifier: client is not entitled
Unable to access shared container
```

This means the app group entitlements are not properly configured.

## Solution

### Step 1: Configure App Groups in Xcode

1. **For the Main App (ElKeyboard)**:
   - Select the ElKeyboard target in Xcode
   - Go to "Signing & Capabilities" tab
   - Click "+" and add "App Groups" capability
   - Add the app group: `group.com.yourcompany.ElKeyboard`

2. **For the Keyboard Extension (ElKeyboardExtension)**:
   - Select the ElKeyboardExtension target in Xcode
   - Go to "Signing & Capabilities" tab  
   - Click "+" and add "App Groups" capability
   - Add the same app group: `group.com.yourcompany.ElKeyboard`

### Step 2: Use the Entitlement Files

The entitlement files have been created for you:
- `ElKeyboard/ElKeyboard.entitlements`
- `ElKeyboardExtension/ElKeyboardExtension.entitlements`

Make sure these are properly referenced in your Xcode project:
1. Select your target
2. Go to "Build Settings"
3. Search for "Code Signing Entitlements"
4. Set the path to the appropriate .entitlements file

### Step 3: Update the App Group Identifier

If you want to use a different app group identifier:
1. Update the identifier in these files:
   - `ElKeyboard/KeyTracker.swift` (line 16)
   - `ElKeyboard/MessageSaver.swift` (line 13) 
   - `ElKeyboardExtension/KeyboardViewController.swift` (line 12)
2. Update both entitlement files with the new identifier
3. Configure the same identifier in Xcode capabilities

### Step 4: Test

After configuring the entitlements:
1. Clean and rebuild your project
2. Install both the main app and enable the keyboard extension
3. The error should be resolved and messages should save properly

## Fallback Behavior

The current code includes fallback mechanisms:
- KeyTracker falls back to standard UserDefaults if app groups aren't available
- MessageSaver falls back to the Documents directory if app groups aren't available
- Detailed error messages are logged to help with debugging

This ensures the app continues to function even if app groups aren't properly configured, though data won't be shared between the main app and keyboard extension.