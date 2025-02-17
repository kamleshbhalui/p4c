# P4Tools - Testing Tools For P4 Targets

## Directory Structure

```
p4tools
 ├─ cmake       ── Common CMake modules
 ├─ common      ── C++ source: common code for the various components of p4check
 ├─ modules     ── P4Tools extensions.
 │  └─ testgen  ── C++ source: P4Testgen.
 └─ submodules  ── External dependencies.
    ├─ gsl-lite ── C++ Core Guidelines Support Library.
    └─ inja     ── C++ template engine used for test generation.
```

## P4Tools
P4Tools is a collection of tools that make testing P4 targets and programs a little easier. So far the platform supports the following tools and projects:

- [P4Testgen](https://github.com/p4lang/p4c/tree/main/backends/p4tools/modules/testgen): An input-output test case generator for P4.

## Building

P4Tools can be built using the following CMAKE configuration in the P4C repository.

```
mkdir build
cd build
cmake .. -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DENABLE_TEST_TOOLS=ON
make
```

## Dependencies
* [inja](https://github.com/pantor/inja) template engine for testcase generation.
* [gsl-lite](https://github.com/gsl-lite/gsl-lite) C++ Core Guidelines Support Library, used to
support and enforce C++ best practices.

## Development Style
Currently, each C++ source directory has a few subdirectories, including:
* `core`, containing the core functionality of the submodule; and
* `lib`, containing supporting data structures.

The distinction between the two can be fuzzy. Here are some guiding principles
for where to find/put what:
* If it depends on anything in `core`, it belongs in `core`.
* If it's something that resembles a general-purpose data structure (e.g., an
  environment or a symbol table), it's probably in `lib`.


### C++ Coding style

P4Tools in general follows the [P4C coding style](https://github.com/p4lang/p4c/blob/main/docs/README.md#coding-conventions). Some deviations from the Style Guide are highlighted below.

* Comments are important. The Style Guide's [section on
  comments](https://google.github.io/styleguide/cppguide.html#Comments) is
  required reading.
    * Classes, methods, and fields are documented with triple-slash
      Doxygen-style comments:
      ```
      /// An example class demonstrating a documentation comment.
      class C {};
      ```
    * We do not use copyright headers or license boilerplate in our source
      files. Where needed, these will be auto-generated during release
      packaging.
* Generally prefer a single class declaration per `.h` file, unless providing a
  library of related classes. Multiple classes may be declared in a `.cpp`
  file.

