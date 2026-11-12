on run arguments
    set mountFolder to POSIX file (item 1 of arguments) as alias
    tell application "Finder"
        tell folder mountFolder
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set bounds of container window to {200, 160, 920, 668}
            set options to icon view options of container window
            set arrangement of options to not arranged
            set icon size of options to 96
            set text size of options to 14
            set background picture of options to file ".background:install.png"
            set position of file "media_knowledge.app" to {180, 220}
            set position of alias file "Applications" to {540, 220}
            update without registering applications
            delay 2
            if position of file "media_knowledge.app" is not {180, 220} then error "Application icon position was not saved"
            if position of alias file "Applications" is not {540, 220} then error "Applications shortcut position was not saved"
            close container window
        end tell
    end tell
end run
