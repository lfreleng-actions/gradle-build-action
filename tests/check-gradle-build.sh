#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation

# Check that a built Gradle fixture ran on the expected Gradle release and
# JDK, and that every module built and its tests passed.
#
# Usage: check-gradle-build.sh <project-dir> <gradle-version> <java-version>
#
# <java-version> is a feature release such as 17 or 21. Run it after the
# build, with the 'gradle' under test first on PATH.

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <project-dir> <gradle-version> <java-version>" >&2
  exit 2
fi

project_dir="$1"
want_gradle="$2"
want_java="$3"
errors=0

fail() {
  echo "Error: $*"
  errors=$((errors + 1))
}

if [ ! -d "$project_dir" ]; then
  echo "Error: project directory not found: $project_dir" >&2
  exit 2
fi
cd "$project_dir"

# Dots in a version are literal; escape them before use in a regex
gradle_re="${want_gradle//./\\.}"
java_re="${want_java//./\\.}"

# The Gradle on PATH and the JVM that launches it
version_output=$(gradle --version)
if grep -Eq "^Gradle ${gradle_re}\$" <<< "$version_output"; then
  echo "OK: gradle --version reports Gradle $want_gradle"
else
  fail "gradle --version does not report 'Gradle $want_gradle'"
fi
# Require a separator after the feature release, so 2 cannot match 21
launcher=$(grep -E '^Launcher JVM:' <<< "$version_output" || true)
if grep -Eq "^Launcher JVM: +${java_re}([.+ ]|\$)" <<< "$launcher"; then
  echo "OK: $launcher"
else
  fail "want Launcher JVM $want_java, got '${launcher:-none}'"
fi

# The JVM the tests ran on, as recorded by the fixture's own test
mapfile -t jvm_files < <(
  find . -path '*/build/test-jvm/java-specification-version.txt' | sort
)
if [ "${#jvm_files[@]}" -eq 0 ]; then
  fail "no recorded test JVM under */build/test-jvm/"
fi
for file in "${jvm_files[@]}"; do
  recorded=$(tr -d '[:space:]' < "$file")
  if [ "$recorded" = "$want_java" ]; then
    echo "OK: tests ran on Java $recorded ($file)"
  else
    fail "want tests on Java $want_java, got '$recorded' ($file)"
  fi
done

# Every module with a build script produced a jar
mapfile -t modules < <(
  find . -mindepth 2 -maxdepth 2 \
    \( -name build.gradle -o -name build.gradle.kts \) \
    -not -path './build/*' -exec dirname {} \; | sort
)
if [ "${#modules[@]}" -eq 0 ]; then
  fail "no modules found in $project_dir"
fi
for module in "${modules[@]}"; do
  if compgen -G "$module/build/libs/*.jar" > /dev/null; then
    echo "OK: $module built $(basename "$module"/build/libs/*.jar)"
  else
    fail "$module produced no jar under build/libs/"
  fi
done

# The JUnit XML reports show passing tests with no failures or errors
total=0
mapfile -t reports < <(find . -path '*/build/test-results/*/TEST-*.xml' | sort)
if [ "${#reports[@]}" -eq 0 ]; then
  fail "no JUnit XML reports under */build/test-results/"
fi
attr() {
  sed -nE "s/.* $1=\"([0-9]+)\".*/\\1/p" <<< "$2"
}
for report in "${reports[@]}"; do
  suite=$(grep -m1 -o '<testsuite [^>]*>' "$report" || true)
  tests=$(attr tests "$suite")
  failures=$(attr failures "$suite")
  errs=$(attr errors "$suite")
  if [ -z "$tests" ] || [ -z "$failures" ] || [ -z "$errs" ]; then
    fail "cannot read test counts from $report"
    continue
  fi
  if [ "$failures" -ne 0 ] || [ "$errs" -ne 0 ]; then
    fail "$report: $failures failures, $errs errors"
  fi
  total=$((total + tests))
done
if [ "$total" -gt 0 ]; then
  echo "OK: $total tests ran in ${#reports[@]} report(s)"
else
  fail "no tests ran"
fi

if [ "$errors" -ne 0 ]; then
  echo "$errors check(s) failed"
  exit 1
fi
echo "All checks passed"
