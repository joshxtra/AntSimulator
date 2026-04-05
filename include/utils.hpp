#pragma once
#include <string>
#include <fstream>

#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#endif

// Returns the base path for resources (with trailing slash).
// Inside a macOS .app bundle: path to Contents/Resources/
// Otherwise: empty string (use relative paths from CWD)
inline std::string getResourcePath()
{
#ifdef __APPLE__
    CFBundleRef bundle = CFBundleGetMainBundle();
    if (bundle) {
        CFURLRef resourcesURL = CFBundleCopyResourcesDirectoryURL(bundle);
        char path[PATH_MAX];
        if (CFURLGetFileSystemRepresentation(resourcesURL, TRUE, (UInt8*)path, PATH_MAX)) {
            CFRelease(resourcesURL);
            return std::string(path) + "/";
        }
        CFRelease(resourcesURL);
    }
#endif
    return "";
}

// Returns the path to conf.txt, checking in order:
//   1. Next to the .app bundle (or CWD for non-bundle builds)
//   2. ~/Library/Application Support/AntSimulator/ (macOS bundle)
// Returns empty string if not found.
inline std::string getConfPath()
{
#ifdef __APPLE__
    CFBundleRef bundle = CFBundleGetMainBundle();
    if (bundle) {
        // Check next to the .app bundle
        CFURLRef bundleURL = CFBundleCopyBundleURL(bundle);
        CFURLRef parentURL = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, bundleURL);
        CFRelease(bundleURL);
        char parentPath[PATH_MAX];
        if (CFURLGetFileSystemRepresentation(parentURL, TRUE, (UInt8*)parentPath, PATH_MAX)) {
            std::string candidate = std::string(parentPath) + "/conf.txt";
            if (std::ifstream(candidate)) {
                CFRelease(parentURL);
                return candidate;
            }
        }
        CFRelease(parentURL);

        // Fall back to ~/Library/Application Support/AntSimulator/conf.txt
        const char* home = getenv("HOME");
        if (home) {
            std::string candidate = std::string(home) + "/Library/Application Support/AntSimulator/conf.txt";
            if (std::ifstream(candidate)) {
                return candidate;
            }
        }
        return "";
    }
#endif
    // Non-bundle: use CWD
    return "conf.txt";
}
