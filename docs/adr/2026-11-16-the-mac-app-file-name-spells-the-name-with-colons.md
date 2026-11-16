# The Mac app's file name spells "precise//en" with colons

## Decision

- The app's name is "precise//en", all lowercase, everywhere Alex sees it. On the iPhone the display name carries it. On the Mac the bundle's file name is `precise::en.app`, because Finder, Spotlight and Launchpad show a colon in a file name as a slash.
- The executable takes the same name. The bundle identifier and signing identity stay the same, so the app keeps its identity across the rename.
- Scripts, docs and anything that opens the app (such as a scheduled job) use the colon path.

## Why

macOS shows an app's file name, not its bundle name, in Finder, Spotlight and Launchpad, and a POSIX file name cannot contain "/". The colon-to-slash translation is the system's own mapping between the two, so the file name `precise::en.app` is shown as "precise//en" with no other mechanism. In a shell the path reads `precise::en.app`; that is the accepted cost.

## Rejected

- **A localized display name (`LSHasLocalizedDisplayName` with a localized `CFBundleDisplayName`).** Tested: macOS collapses the consecutive slashes, so Finder showed "precise/en".
- **Keeping the file name "Precise EN.app".** Finder, Spotlight and Launchpad kept showing the old name.
- **A slash-free spelling such as "precise-en".** It isn't the name.
