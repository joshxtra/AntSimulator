#pragma once
#include <string>
#include <fstream>

#ifdef __APPLE__
#include <CoreFoundation/CoreFoundation.h>
#include <mach-o/dyld.h>
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

// Returns the directory containing the executable (with trailing slash).
inline std::string getExeDir()
{
#ifdef __APPLE__
    char exe_path[PATH_MAX];
    uint32_t size = sizeof(exe_path);
    if (_NSGetExecutablePath(exe_path, &size) == 0) {
        std::string exe(exe_path);
        auto pos = exe.rfind('/');
        if (pos != std::string::npos) {
            return exe.substr(0, pos + 1);
        }
    }
#endif
    return "";
}

// Returns the path to conf.txt next to the executable.
// If the file exists it can be read; if not, this is also the write path.
inline std::string getConfPath()
{
    return getExeDir() + "conf.txt";
}
