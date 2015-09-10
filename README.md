Prepack is a Premake-based package manager.

You can use it to manage your native and managed source code projects, libraries
and assets.

For an overview of these commands, see the documentation.

```
Usage: prepack <command> [arguments]

Available commands:
        help    Shows an help listing of commands
        search  Searches for a package in the index
        list    Lists the packages in the index
        index   Builds an index of the local packages
        bundle  Bundles a local package to an archive
        update  Updates the package index
        install Installs packages in the system
```

# Prepack commands

The following reference pages cover each command in detail:

...

# Concepts

## Dependencies

Dependencies are one of prepack core concepts. A dependency is another package that your package needs in order to work. Dependencies are specified in your package spec.

You only list immediate dependencies—the software that your package uses directly. Prepack handles transitive dependencies for you.



