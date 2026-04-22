<!--
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 The Linux Foundation
-->

# 🏗️ Gradle Build Action

Sets up a specific JDK version and distribution, configures Gradle via
[`gradle/actions/setup-gradle`](https://github.com/gradle/actions/tree/main/setup-gradle),
and runs a build using the Gradle Wrapper (or a specific Gradle version).

## gradle-build-action

## Usage Example

Builds a project using Gradle with the specified JDK version and
distribution.

<!-- markdownlint-disable MD013 -->

```yaml
steps:
  - name: "Gradle Build"
    id: gradle-build
    uses: lfreleng-actions/gradle-build-action@main
    with:
      jdk-version: "17"
      distribution: "temurin"
```

<!-- markdownlint-enable MD013 -->

### Advanced example

Build a specific Gradle task, publish a Build Scan, and generate a
GitHub Dependency Graph snapshot:

<!-- markdownlint-disable MD013 -->

```yaml
steps:
  - name: "Gradle Build"
    id: gradle-build
    uses: lfreleng-actions/gradle-build-action@main
    with:
      jdk-version: "21"
      path: "my-project"
      build-arguments: "clean build -x test"
      dependency-graph: "generate-and-submit"
      build-scan-publish: "true"
      build-scan-terms-of-use-url: "https://gradle.com/help/legal-terms-of-use"
      build-scan-terms-of-use-agree: "yes"

  - name: "Show Build Scan URL"
    if: steps.gradle-build.outputs.build-scan-url != ''
    run: echo "Build Scan: ${{ steps.gradle-build.outputs.build-scan-url }}"
```

<!-- markdownlint-enable MD013 -->

## Inputs

<!-- markdownlint-disable MD013 -->

### JDK / toolchain (passthrough to `setup-java`)

<!-- markdownlint-disable MD013 -->

| Name              | Required | Default | Description                                                                    |
| ----------------- | -------- | ------- | ------------------------------------------------------------------------------ |
| jdk-version       | False    | 21*     | OpenJDK version. Ignored when the caller provides `java-version-file`          |
| java-version-file | False    |         | Path to a `.java-version` file (alternative to `jdk-version`)                  |
| distribution      | False    | temurin | OpenJDK distribution                                                           |
| java-package      | False    | jdk     | Package type: `jdk`, `jre`, `jdk+fx`, or `jre+fx`                              |
| architecture      | False    |         | Package architecture (defaults to the runner's architecture)                   |
| check-latest      | False    | false   | When `true`, resolve the latest version satisfying the version spec            |
| setup-java-token  | False    |         | Token used by `setup-java` (useful on GHES or under rate limits)               |

<!-- markdownlint-enable MD013 -->

\* JDK 21 serves as the default when the caller omits both `jdk-version`
and `java-version-file`. Supplying `java-version-file` takes precedence
over the default.

<!-- markdownlint-enable MD013 -->

### Project / build

<!-- markdownlint-disable MD013 -->

| Name            | Required | Default | Description                                          |
| --------------- | -------- | ------- | ---------------------------------------------------- |
| path            | False    | .       | Path to the Gradle project (contains gradlew)        |
| build-arguments | False    | build   | Arguments passed to the Gradle Wrapper               |
| gradle-version  | False    |         | Specific Gradle version; omit to use project wrapper |

<!-- markdownlint-enable MD013 -->

### Caching (passthrough to `setup-gradle`)

<!-- markdownlint-disable MD013 -->

| Name                 | Required | Default     | Description                                             |
| -------------------- | -------- | ----------- | ------------------------------------------------------- |
| cache-provider       | False    | enhanced    | Caching implementation: `enhanced` or `basic` (MIT)     |
| cache-disabled       | False    | false       | When `true`, disable all caching                        |
| cache-read-only      | False    | false       | When `true`, restore but do not write cache entries     |
| cache-write-only     | False    | false       | When `true`, save but do not restore cache entries      |
| cache-encryption-key | False    |             | Base64 AES key for configuration-cache data encryption  |
| cache-cleanup        | False    | on-success  | `never`, `on-success` (default), or `always`            |

<!-- markdownlint-enable MD013 -->

### Wrapper validation / summaries / dependency graph

<!-- markdownlint-disable MD013 -->

| Name                          | Required | Default  | Description                                                     |
| ----------------------------- | -------- | -------- | --------------------------------------------------------------- |
| validate-wrappers             | False    | true     | Check checksums of all `gradlew` jars in the repository         |
| add-job-summary               | False    | always   | `never`, `always` (default), or `on-failure`                    |
| add-job-summary-as-pr-comment | False    | never    | `never` (default), `always`, or `on-failure`                    |
| dependency-graph              | False    | disabled | `disabled`, `generate`, `generate-and-submit`, etc.             |

<!-- markdownlint-enable MD013 -->

### Build Scan / Develocity

<!-- markdownlint-disable MD013 -->

| Name                          | Required | Default | Description                                                        |
| ----------------------------- | -------- | ------- | ------------------------------------------------------------------ |
| build-scan-publish            | False    | false   | Publish results as a Build Scan on scans.gradle.com                |
| build-scan-terms-of-use-url   | False    |         | Build Scan terms-of-use URL (required if publishing)               |
| build-scan-terms-of-use-agree | False    |         | Set to `yes` to agree to the Build Scan terms of use               |
| develocity-url                | False    |         | URL of a Develocity server (enables injection)                     |
| develocity-access-key         | False    |         | Develocity access key (pass via secrets)                           |

<!-- markdownlint-enable MD013 -->

## Outputs

<!-- markdownlint-disable MD013 -->

| Name              | Description                                                |
| ----------------- | ---------------------------------------------------------- |
| build-scan-url    | Link to the Build Scan generated by the Gradle build       |
| gradle-version    | Version of Gradle set up by the action                     |
| java-version      | Actual version of the Java environment installed           |
| java-distribution | Java distribution the action installed                     |
| java-home         | Path to the installed Java environment (`JAVA_HOME`)       |

<!-- markdownlint-enable MD013 -->

## Requirements/Dependencies

The directory specified by the `path` input (the repository root by
default) must contain a Gradle Wrapper (`gradlew`), unless the caller
sets an explicit `gradle-version` — in which case the action installs
that Gradle version and invokes `gradle` directly. The action uses
[actions/setup-java](https://github.com/actions/setup-java) and
[gradle/actions/setup-gradle](https://github.com/gradle/actions/tree/main/setup-gradle)
under the hood.

## Notes

- The [setup-java documentation](https://github.com/actions/setup-java?tab=readme-ov-file#supported-distributions)
  lists all supported JDK distributions.
- By default the action runs `./gradlew build` inside the directory
  given by `path`. Override the tasks and flags via `build-arguments`.
- This action pins
  [gradle/actions/setup-gradle](https://github.com/gradle/actions/tree/main/setup-gradle)
  to a specific commit SHA (v6.1.0 at time of writing). Upstream
  deprecated `gradle/gradle-build-action` in favour of `setup-gradle`
  (the former now transparently delegates to the latter), so this
  migration gives direct, explicit control over the underlying action
  and its inputs.
- When invoking Gradle with a non-wrapper version via `gradle-version`,
  `build-arguments` applies to the downloaded `gradle` binary rather
  than `./gradlew`.
- See the full list of `setup-gradle` inputs and advanced scenarios in
  the [upstream documentation](https://github.com/gradle/actions/blob/main/docs/setup-gradle.md).
